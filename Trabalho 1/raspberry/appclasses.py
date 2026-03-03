import sys
import serial
import pyqtgraph as pg
import time

from PyQt5.QtWidgets import QApplication, QComboBox, QMainWindow, QWidget, QPushButton, QVBoxLayout, QLabel, QLineEdit
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

        # Serial
        #self.ser = serial.Serial('COM6', 9600, timeout=1)

        # Data storage
        self.magnitude_data = []
        self.time_data = []

        # Start time
        self.start_time = None
        
        # -----------------------------
        # Buttons and plot setup
        # -----------------------------

        # Time Interval
        self.interval_definer = QComboBox()
        self.interval_definer.addItem(" 1 second")
        self.interval_definer.addItem(" 2 seconds")
        self.interval_definer.addItem(" 5 seconds")
        self.interval_definer.addItem(" 10 seconds")
        self.interval_definer.addItem(" 20 seconds")

        self.interval_definer.setFixedHeight(50)
        self.layout.addWidget(self.interval_definer)

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
        self.curve = self.plot_widget.plot(pen='p', symbol='o')

    # -----------------------------
    # Serial communication
    # -----------------------------

    def send_command(self):
        command = "MEASURE\n"
        self.ser.write(command.encode())
        print("Command sent:", command.strip())

    def read_message(self):
        if self.ser.in_waiting > 0:
            message = self.ser.readline().decode().strip()
            try:
                value = float(message)
                self.magnitude_data.append(value)
                self.time_data.append(time.time() - self.start_time)
                print("Message received:", message)
            except ValueError:
                print("Invalid data:", message)

    # -----------------------------
    # Plot update
    # -----------------------------

    def update_data(self):
        self.send_command()
        self.read_message()
        self.curve.setData(self.time_data, self.magnitude_data)

    # -----------------------------
    # Button handlers
    # -----------------------------

    def start_clicked(self):
        print("Start button clicked!")
        self.start_time = time.time()
        self.timer.start(2000)  # 2 seconds

    def stop_clicked(self):
        print("Stop button clicked!")
        self.timer.stop()

    def open_help_window(self):
        self.help_window = QWidget()
        self.help_window.setWindowTitle("Help")
        self.help_window.setGeometry(500, 500, 300, 200)

        layout = QVBoxLayout()
        self.help_window.setLayout(layout)

        label = QLabel("This is the help window. Add instructions here.")
        layout.addWidget(label)

        self.help_window.show()


    # -----------------------------
    # Close properly
    # -----------------------------

    def closeEvent(self, event):
        #self.ser.close()
        event.accept()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MyWindow()
    window.show()
    sys.exit(app.exec_())