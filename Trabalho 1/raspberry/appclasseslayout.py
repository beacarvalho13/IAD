import sys
from turtle import delay
from PyQt5 import QtWidgets
from PyQt5 import QtCore
from PyQt5 import QtCore
import serial
import pyqtgraph as pg
import time
import csv
import datetime

from PyQt5.QtWidgets import QApplication, QComboBox, QGroupBox, QHBoxLayout, QLineEdit, QMainWindow, QScrollArea, QWidget, QPushButton, QVBoxLayout, QLabel
from PyQt5.QtCore import QTimer

class MyWindow(QMainWindow):
    def __init__(self):
        super().__init__()  

        # Window setup
        self.setWindowTitle("Magnetic Measurement App")
        self.setGeometry(100, 100, 800, 800)
        self.setStyleSheet("QGroupBox { font-weight: bold; }")        
    

        # Data storage
        self.magnitude_data = []
        self.time_data = []
        self.phrase = ""

        # Background storage
        self.background_magnitude_data = []
        self.background_time_data = []
        self.background_active = False
        self.background_offset = 0.0

        # Timer setup
        self.start_time = None
        self.interval = 1000   
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_data)
        
        # Central widget
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)

        # MAIN LAYOUT (vertical)
        self.main_layout = QVBoxLayout()
        self.central_widget.setLayout(self.main_layout)

        self.main_layout.setContentsMargins(15,15,15,15)
        self.main_layout.setSpacing(12)

        # -----------------------------
        # TERMINAL (TOP)
        # -----------------------------
        self.output_window = QtWidgets.QTextBrowser()
        self.main_layout.addWidget(self.output_window)
        self.output_window.setMinimumHeight(200)
        
        # -----------------------------
        # TWO COLUMN SECTION
        # -----------------------------
        self.columns_layout = QHBoxLayout()
        self.main_layout.addLayout(self.columns_layout)
        self.columns_layout.setSpacing(30)

        # Create group boxes
        self.control_group = QGroupBox("Measurement Controls")
        self.system_group = QGroupBox("System Settings")

        # Create layouts for each group
        self.left_layout = QVBoxLayout()
        self.right_layout = QVBoxLayout()

        self.left_layout.setContentsMargins(10,15,10,10)
        self.right_layout.setContentsMargins(10,15,10,10)

        # Assign layouts to the group boxes
        self.control_group.setLayout(self.left_layout)
        self.system_group.setLayout(self.right_layout)

        # Add the group boxes to the column layout
        self.columns_layout.addWidget(self.control_group)
        self.columns_layout.addWidget(self.system_group)

        # Columns equal width
        self.columns_layout.setStretch(0, 1)
        self.columns_layout.setStretch(1, 1)

        # Spacing inside columns
        self.left_layout.setSpacing(10)
        self.right_layout.setSpacing(10)

        # -----------------------------
        # LEFT COLUMN WIDGETS
        # -----------------------------

        # Command input
        self.text_widget = QLineEdit()
        self.text_widget.setPlaceholderText(" Type a command...")
        self.left_layout.addWidget(self.text_widget)
        self.text_widget.returnPressed.connect(self.text_input)
        self.text_widget.setMinimumHeight(50)

        # Start
        self.start_button = QPushButton("Start")
        self.left_layout.addWidget(self.start_button)
        self.start_button.clicked.connect(self.start_clicked)
        self.start_button.setMinimumHeight(50)

        # Stop
        self.stop_button = QPushButton("Stop")
        self.left_layout.addWidget(self.stop_button)
        self.stop_button.clicked.connect(self.stop_clicked)
        self.stop_button.setMinimumHeight(50)


        # Send command
        self.send_button = QPushButton("Send Command")
        self.left_layout.addWidget(self.send_button)
        self.send_button.clicked.connect(self.send_command_clicked)
        self.send_button.setMinimumHeight(50)


        # -----------------------------
        # RIGHT COLUMN WIDGETS
        # -----------------------------

        # Time interval
        self.interval_definer = QComboBox()
        self.interval_definer.addItems([
            "1 second",
            "2 seconds",
            "5 seconds",
            "10 seconds",
            "20 seconds"
        ])
        self.right_layout.addWidget(self.interval_definer)
        self.interval_definer.currentTextChanged.connect(self.text_changed )
        self.interval_definer.setMinimumHeight(50)


        # Run background
        self.background_button = QPushButton("Run Background")
        self.background_button.setStyleSheet("background-color:#c8e6c9;color:#2e7d32;font-weight:bold;")
        self.right_layout.addWidget(self.background_button)
        self.background_button.clicked.connect(self.run_background)
        self.background_button.setMinimumHeight(50)


        # Help
        self.help_button = QPushButton("Help Window")
        self.right_layout.addWidget(self.help_button)
        self.help_button.clicked.connect(self.open_help_window)
        self.help_button.setMinimumHeight(50)


        # Export CSV
        self.export_button = QPushButton("Export to CSV")
        self.right_layout.addWidget(self.export_button)
        self.export_button.clicked.connect(self.export_to_csv)
        self.export_button.setMinimumHeight(50)


        # -----------------------------
        # GRAPH (BOTTOM)
        # -----------------------------
        self.plot_widget = pg.PlotWidget(title="Real-time Data")
        self.plot_widget.showGrid(x=True, y=True)
        self.plot_widget.setXRange(0, 20)
        self.plot_widget.setYRange(-100, 100)
        self.plot_widget.setLabel('left', 'Magnitude', units='Gs')
        self.plot_widget.setLabel('bottom', 'Time', units='s')
        self.plot_widget.setBackground('w')

        self.main_layout.addWidget(self.plot_widget)    

        # Create curve
        self.line = self.plot_widget.plot(pen=pg.mkPen(color="#FA7AB7", width=2))
        self.scatter = pg.ScatterPlotItem(size=10,symbol='o')
        self.plot_widget.addItem(self.scatter)

        # Crosshair lines
        self.vLine = pg.InfiniteLine(angle=90, movable=False, pen=pg.mkPen(color='k', style=QtCore.Qt.DotLine))
        self.hLine = pg.InfiniteLine(angle=0, movable=False, pen=pg.mkPen(color='k', style=QtCore.Qt.DotLine))
        self.plot_widget.addItem(self.vLine, ignoreBounds=True)
        self.plot_widget.addItem(self.hLine, ignoreBounds=True)

        # Text label to display coordinates
        self.label = pg.TextItem("", anchor=(0,1))
        self.plot_widget.addItem(self.label)

        #self.proxy = pg.SignalProxy(self.plot_widget.scene().sigMouseMoved, rateLimit=60, slot=self.mouse_moved)

        # Serial
        self.ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
        if self.ser and self.ser.is_open:
            self.output_window.append("Successful connection to port.")
        else:
            self.output_window.append("Unable to connect to port")

    # -----------------------------
    # Serial communication
    # -----------------------------

    def send_command(self):
        command = self.phrase + "\n"
        self.ser.write(command.encode())

    def read_message(self):
        start_wait = time.time()
        timeout = 0.3  

        '''if self.phrase != "MEASURE":
            return'''
        
        while self.ser.in_waiting == 0:
            if time.time() - start_wait > timeout:
                self.output_window.append("No response from Arduino.")
                return
            QtWidgets.QApplication.processEvents()
            
        message = self.ser.readline().decode().strip()

        try:
            if self.background_active:
                value = float(message)
            else:
                value = float(message) - self.background_offset
            self.magnitude_data.append(value)
                
            if self.start_time is None:
                self.start_time = time.time()
                
            self.time_data.append(time.time() - self.start_time)
            if value > 9000:
                self.output_window.append(f"Unknown Command: {self.phrase}")
                return
            self.output_window.append(f"Message received: {message}")
            
        except ValueError:
            self.output_window.append(f"Invalid data: {message}")

    # -----------------------------
    # Plot update
    # -----------------------------

    def update_data(self):

        if not self.background_active:
            return

        self.send_command()
        self.read_message()

        if len(self.time_data) == 0 or len(self.magnitude_data) == 0:
            #self.output_window.append("INFO: No data to plot yet.")
            return

        self.line.setData(self.time_data, self.magnitude_data)

        #Scatter plot with color coding
        spots = []
        for t, v in zip(self.time_data, self.magnitude_data):

            if v > 0:
                color = 'r'
            elif v < 0:
                color = 'b'
            else:
                color = 'k'

            spots.append({'pos': (t, v),'brush': pg.mkBrush(color)})

        self.scatter.setData(spots)

        # Auto scale graph
        self.plot_widget.enableAutoRange(axis='y')
        self.plot_widget.enableAutoRange(axis='x')

    '''def mouse_moved(self, event):
        pos = event[0]  # get mouse position
        if self.plot_widget.sceneBoundingRect().contains(pos):
            mousePoint = self.plot_widget.getPlotItem().vb.mapSceneToView(pos)
            x = mousePoint.x()
            y = mousePoint.y()
            self.vLine.setPos(x)
            self.hLine.setPos(y)
            self.label.setText(f"Time: {x:.2f} s\nMagnitude: {y:.2f} Gs")
            self.label.setPos(x, y)'''
            
    # -----------------------------
    # Button handlers
    # -----------------------------

    def text_input(self):
        command = self.text_widget.text().strip().upper()

        if command == "CLEAR":
            self.clear_data()
        elif command == "MEASURE":
            self.phrase = "MEASURE"
            self.output_window.append("MEASURE command set. Click 'Send Command' to execute.")
        elif command == "TERMINAL":
            self.output_window.clear()
            self.output_window.append("Terminal cleared.")
        elif command == "STATS":    
            if self.timer.isActive():
                self.output_window.append("Please stop the measurement before viewing statistics.")
                return
            if self.magnitude_data is None or len(self.magnitude_data) == 0:
                self.output_window.append("No data available to calculate statistics.")
                return
            self.open_stats()

        else:
            self.phrase = command
            self.output_window.append(f"{command} may not work as a command.")

        self.text_widget.clear()

    def run_background(self):
        self.output_window.append("Run background button clicked!")

        self.background_active = True
        self.background_button.setStyleSheet("background-color: #ffeb3b;") # Amarelo (Atenção)

        self.magnitude_data.clear()
        self.time_data.clear()

        self.start_time = time.time()
        self.timer.start(self.interval)

        self.output_window.append(f"Background data collection started for 20000 milliseconds")

        QTimer.singleShot(20000, self.finish_background_collection) 

    def finish_background_collection(self):
        self.background_active = False

        self.background_button.setStyleSheet("background-color: #f0f0f0;") # Cinzento padrão
        self.output_window.append("Background data collection finished")
        
        self.timer.stop()
        
        self.background_magnitude_data = self.magnitude_data.copy()
        self.background_time_data = self.time_data.copy()

        if self.magnitude_data:
            self.background_offset = sum(self.magnitude_data) / len(self.magnitude_data)
            self.output_window.append(f"New Background Offset: {self.background_offset}")
        
        self.magnitude_data.clear()
        self.time_data.clear()

        self.line.setData([], [])
        self.scatter.setData([])

    def text_changed(self, text):
        self.interval = int(text.strip().split()[0]) * 1000 
        self.timer.setInterval(self.interval)
        self.output_window.append(f"Interval set to: {self.interval} ms")

    def open_help_window(self):
        self.help_window = QWidget()
        self.help_window.setWindowTitle("Help")
        self.help_window.setGeometry(500, 500, 500, 500)

        layout = QVBoxLayout(self.help_window)

        # Scroll Area
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        layout.addWidget(scroll)

        # Container widget inside scroll
        scroll_content = QWidget()
        scroll_layout = QVBoxLayout(scroll_content)

        help_text = """
        Magnetic Measurement App - Help Guide

        This application allows you to collect, visualize, and export magnetic field
        measurements received from an Arduino device.

        --------------------------------------------------
        GENERAL WORKFLOW
        --------------------------------------------------
        1. Connect the Arduino device.
        2. Enter the command MEASURE in the text box.
        3. Click "Send Command" or press "Start".
        4. The data will be displayed in real-time on the graph.
        5. Stop the measurement when finished.
        6. Export the collected data to a CSV file if needed.

        --------------------------------------------------
        TEXT COMMANDS
        --------------------------------------------------
        MEASURE
            Enables measurement mode. The system will send the
            MEASURE command to the Arduino to request data.

        CLEAR
            Clears all stored data and resets the graph.

        TERMINAL
            Clears the terminal output window.

        STATS
            Opens a statistics window.

        --------------------------------------------------
        BUTTON FUNCTIONS
        --------------------------------------------------
        Run Background
            Collects background measurements for 20 seconds.
            The average value is used as a background offset
            that will be subtracted from future measurements.

        Start
            Begins real-time data collection and plotting.

        Stop
            Stops data acquisition.

        Send Command
            Sends the MEASURE command once and reads a value.

        Export to CSV
            Saves the collected data (time and magnitude)
            to a CSV file with a timestamped filename.

        Help Window
            Opens this help guide.

        --------------------------------------------------
        GRAPH INFORMATION
        --------------------------------------------------
        The graph shows magnetic magnitude vs time.

        Red points  : Positive magnetic values
        Blue points : Negative magnetic values
        Black points: Zero value

        The line represents the measurement trend.

        --------------------------------------------------
        TIME INTERVAL
        --------------------------------------------------
        Use the dropdown menu to change how often
        measurements are taken (1–20 seconds). 
        The standard value is 1 second.

        --------------------------------------------------
        STATISTICS
        --------------------------------------------------
        The program can calculate:
        • Mean value
        • Standard deviation
        • Maximum value
        • Minimum value

        --------------------------------------------------
        NOTES
        --------------------------------------------------
        • Make sure the Arduino serial port is connected.
        • Data is stored only during active measurements.
        • Export your data before clearing it if needed.

        """

        label = QLabel(help_text)
        label.setWordWrap(True)

        scroll_layout.addWidget(label)
        scroll.setWidget(scroll_content)
        self.help_window.show()
    
    def open_stats(self):
        self.stats_window = QWidget()
        self.stats_window.setWindowTitle("Statistics")
        self.stats_window.setGeometry(500, 500, 300, 200)

        layout = QVBoxLayout()
        self.stats_window.setLayout(layout)
        mean = sum(self.magnitude_data) / len(self.magnitude_data) if self.magnitude_data else 0
        stddev = (sum((x - mean) ** 2 for x in self.magnitude_data) / len(self.magnitude_data)) ** 0.5 if self.magnitude_data else 0
        max_value = max(self.magnitude_data) if self.magnitude_data else 0
        min_value = min(self.magnitude_data) if self.magnitude_data else 0

        label = QLabel(f"Mean: {mean:.2f}")
        layout.addWidget(label)

        label = QLabel(f"Standard Deviation: {stddev:.2f}")
        layout.addWidget(label)

        label = QLabel(f"Max Value: {max_value:.2f}")
        layout.addWidget(label)

        label = QLabel(f"Min Value: {min_value:.2f}")
        layout.addWidget(label)

        self.stats_window.show()
        
    # Basic buttons

    def start_clicked(self):
        if self.phrase == "":
            self.output_window.append("INFO: No phrase entered. Please enter a phrase before sending.")
            return
        self.output_window.append("Start button clicked!")
        if self.timer.isActive():
            self.output_window.append("INFO: System is already running.")
        self.start_time = time.time()
        self.timer.start(self.interval) 
        self.background_active = True

        # Clear previous data
        self.magnitude_data.clear()
        self.time_data.clear()
        self.update_data()

    def stop_clicked(self):
        if not self.timer.isActive():
            self.output_window.append("INFO: System is already stopped.")
            return
        self.background_active = False
        self.output_window.append("Stop button clicked!")
        self.timer.stop()
    
    def send_command_clicked(self):
        if self.phrase == "":
            self.output_window.append("INFO: No phrase entered. Please enter a phrase before sending.")
            return
        self.output_window.append("Send Command button clicked.")
        self.background_active = True
        self.update_data()

    def clear_data(self):
        self.output_window.append("Clearing data...")
        self.timer.stop()
        self.magnitude_data.clear()
        self.time_data.clear()
        self.background_magnitude_data.clear()
        self.background_time_data.clear()
        self.background_offset = 0.0
        self.line.setData([], [])
        self.scatter.setData([])

        self.output_window.append("Data cleared.")

    def export_to_csv(self):
        if not self.time_data or not self.magnitude_data:
            self.output_window.append("No data to export.")
            return

        self.x = datetime.datetime.now()
        filename = f"measurement_{self.x.year}_{self.x.month}_{self.x.day}_{self.x.hour}_{self.x.minute}_{self.x.second}.csv"

        try:
            with open(filename, "w", newline="", encoding="utf-8") as file:
                writer = csv.writer(file)
                writer.writerow(["Time (s)", "Magnitude (Gs)"])
                for t, m in zip(self.time_data, self.magnitude_data):
                    writer.writerow([t, m])

            self.output_window.append(f"Data exported successfully to {filename}")

        except Exception as e:
            self.output_window.append(f"Error exporting CSV: {e}")

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
