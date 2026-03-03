import sys
from turtle import delay
from PyQt5 import QtWidgets
import serial
import pyqtgraph as pg
import time

from PyQt5.QtWidgets import QApplication, QComboBox, QMainWindow, QWidget, QPushButton, QVBoxLayout, QLabel
from PyQt5.QtCore import QTimer

class MyWindow(QMainWindow):
    def __init__(self):
        super().__init__()  

        # Window setup
        self.setWindowTitle("Magnetic Measurement App")
        self.setGeometry(100, 100, 800, 600)

        # Central widget & layout
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout()
        self.central_widget.setLayout(self.layout)

        # Output window
        self.output_window = QtWidgets.QTextBrowser(self.central_widget)
        self.layout.addWidget(self.output_window)

        # Serial
        self.ser = serial.Serial('COM6', 9600, timeout=1)
        if self.ser and self.ser.is_open:
            self.output_window.append("Successful connection to port")
        else:
            self.output_window.append("Unable to connect to port")

        # Data storage
        self.magnitude_data = []
        self.time_data = []

        # Background storage
        self.background_magnitude_data = []
        self.background_time_data = []

        # Start time
        self.start_time = None

        self.interval = 2000  
        
        # -----------------------------
        # Buttons and plot setup
        # -----------------------------

        # Run Background button
        self.background_button = QPushButton("Run Background")
        self.layout.addWidget(self.background_button)
        self.background_button.clicked.connect(self.run_background)
        
        # Time Interval
        self.interval_definer = QComboBox()
        self.interval_definer.addItem(" 1 second")
        self.interval_definer.addItem(" 2 seconds")
        self.interval_definer.addItem(" 5 seconds")
        self.interval_definer.addItem(" 10 seconds")
        self.interval_definer.addItem(" 20 seconds")

        self.interval_definer.setFixedHeight(50)
        self.layout.addWidget(self.interval_definer)
        self.interval_definer.currentTextChanged.connect(self.text_changed )

        # Help button
        self.help_button = QPushButton("Help Window")
        self.layout.addWidget(self.help_button)
        self.help_button.clicked.connect(self.open_help_window)
        self.help_button.setFixedSize(800, 50)

        # Standard buttons
        self.start_button = QPushButton("Start")
        self.stop_button = QPushButton("Stop")
        self.send_button = QPushButton("Send Command")

        self.layout.addWidget(self.start_button)
        self.layout.addWidget(self.stop_button)
        self.layout.addWidget(self.send_button)

        self.start_button.setFixedSize(800, 50)
        self.stop_button.setFixedSize(800, 50)
        self.send_button.setFixedSize(800, 50)

        # Connect buttons
        self.start_button.clicked.connect(self.start_clicked)
        self.stop_button.clicked.connect(self.stop_clicked)
        self.send_button.clicked.connect(self.send_command)

        # Timer 
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_data)

        # Plot widget 
        self.plot_widget = pg.PlotWidget(title="Real-time Data")
        self.plot_widget.showGrid(x=True, y=True)
        self.plot_widget.setLabel('left', 'Magnitude', units='Gs')
        self.plot_widget.setLabel('bottom', 'Time', units='s')
        self.plot_widget.setBackground('w')

        self.layout.addWidget(self.plot_widget)

        # Create curve
        self.curve = self.plot_widget.plot(
            pen=pg.mkPen(color="#FA7AB7", width=2),   # line
            symbol='o',
            symbolSize=10,
            symbolBrush=pg.mkBrush(color='#FA7AB7'),                    # dot fill
            symbolPen=pg.mkPen(color='#FA7AB7', width=2)     # dot outline
        )

    # -----------------------------
    # Serial communication
    # -----------------------------

    def send_command(self):
        if self.ser and self.ser.is_open:
            self.output_window.append("Serial port is open.")
        if self.ser.out_waiting == 0:
            self.output_window.append("Output buffer is empty. Sending command...")
        command = "MEASURE\n"
        self.ser.write(command.encode())
        self.output_window.append(f"Command sent: {command.strip()}")

    def read_message(self):
        if self.ser and self.ser.is_open:
            self.output_window.append("Serial port is open.")
        if self.ser.in_waiting > 0:
            message = self.ser.readline().decode().strip()
            try:
                self.output_window.append("Data available in input buffer. Reading...")
                if "Gaussians:" in message:
                    value = float(message.split("Gaussians:")[1].strip())
                    self.magnitude_data.append(value)
                    self.time_data.append(time.time() - self.start_time)
                    self.output_window.append(f"Message received: {value}")
            except (ValueError, IndexError):
                self.output_window.append(f"Invalid data: {message}")

    # -----------------------------
    # Plot update
    # -----------------------------

    def update_data(self):
        self.send_command()
        self.read_message()
        if len(self.time_data) == 0 or len(self.magnitude_data) == 0:
            self.output_window.append("INFO: No data to plot yet.")
        self.curve.setData(self.time_data, self.magnitude_data)
    # Note: if the plot is updating too quickly, reduce the timer interval


    # -----------------------------
    # Button handlers
    # ----------------------
    
    def run_background(self):
        self.output_window.append("Run background button clicked!")
        self.start_time = time.time()
        self.timer.start(self.interval)

        self.output_window.append(f"Background data collection started for 20000 milliseconds")

        QTimer.singleShot(20000, self.finish_background_collection) 

    def finish_background_collection(self):

        self.output_window.append("Background data collection finished")
        self.timer.stop()
        
        self.background_magnitude_data = self.magnitude_data.copy()
        self.background_time_data = self.time_data.copy()
    
    def text_changed(self, text):
        self.interval = int(text.strip().split()[0]) * 1000  # Convert to milliseconds
        self.timer.setInterval(self.interval)
        self.output_window.append(f"Interval set to: {self.interval} ms")

    def open_help_window(self):
        self.help_window = QWidget()
        self.help_window.setWindowTitle("Help")
        self.help_window.setGeometry(500, 500, 300, 200)

        layout = QVBoxLayout()
        self.help_window.setLayout(layout)

        label = QLabel("This is the help window. Add instructions here.")
        layout.addWidget(label)

        self.help_window.show()

    def start_clicked(self):
        self.output_window.append("Start button clicked!")
        if self.timer.isActive():
            self.output_window.append("INFO: System is already running.")
        self.start_time = time.time()
        self.timer.start(self.interval) 

        # Clear previous data
        self.magnitude_data.clear()
        self.time_data.clear()
        self.update_data()

    def stop_clicked(self):
        if not self.timer.isActive():
            self.output_window.append("INFO: System is already stopped.")
        self.output_window.append("Stop button clicked!")
        self.timer.stop()
    
    def send_command_clicked(self):
        self.output_window.append("Send Command button clicked!") 
        self.send_command()

    # -----------------------------
    # Close properly
    # -----------------------------

    def closeEvent(self, event):
        if self.ser and self.ser.is_open:
            self.ser.close()
            self.output_window.append("Serial port closed safely.")
        event.accept()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MyWindow()
    window.show()
    sys.exit(app.exec_())