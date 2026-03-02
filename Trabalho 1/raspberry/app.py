from PyQt5.QtWidgets import QApplication, QWidget, QPushButton
from PyQt5.QtCore import QTimer
import serial
import pyqtgraph as pg
import time

app = QApplication([])

ser = serial.Serial('COM6', 9600, timeout=1)

global magnitude_data 
magnitude_data = []

global time_data 
time_data = []


# Major functions

def send_command():
    command = "MEASURE\n"
    ser.write(command.encode())
    print("Command sent:", command.strip()) 

def read_message():
    if ser.in_waiting > 0:
        message = ser.readline().decode().strip()
        magnitude_data.append(float(message))

        time_data.append(time.time() - start_time)
        print("Message received:", message)

        plot_time_series()

timer1 = QTimer()
timer1.timeout.connect(send_command)

timer2 = QTimer()
timer2.timeout.connect(read_message)

# Funções para os botões

def start_clicked():
    print("Start button clicked!")
    global start_time
    start_time = time.time()
    timer1.start(2000)
    timer2.start(2000)


def stop_clicked():
    print("Stop button clicked!")
    timer1.stop()
    timer2.stop()

def send_command_clicked():
    print("Send Command button clicked!") 
    #send_command() 

    
# Pyqtgraph

def plot_time_series():

    plt = pg.plot(title="Real-time Data")

    plt.showGrid(x=True, y=True)
    plt.setLabel('left', 'Magnitude', units='T')
    plt.setLabel('bottom', 'Time', units='s')

    plt.setWindowTitle("Real-time Data Plot")

    line = plt.plot(time_data, magnitude_data, pen ='b', symbol ='o', symbolPen ='b',
                           symbolBrush = 0.2)

janela = QWidget()              
janela.setWindowTitle("Exemplo")
janela.setGeometry(100, 100, 300, 200)   

# Setup dos botões

botao1 = QPushButton("Start", janela)  
botao1.clicked.connect(start_clicked)
botao1.move(50, 30)
botao1.show()

botao2 = QPushButton("Stop", janela) 
botao2.clicked.connect(stop_clicked)
botao2.move(50, 70)
botao2.show()

botao3 = QPushButton("Send Command", janela) 
botao3.clicked.connect(send_command_clicked)
botao3.move(50, 110)
botao3.show()

janela.show()

plot_time_series()
 
app.exec_() 

ser.close()

