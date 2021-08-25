import serial
import time
#import re

loginprompt = "root@axon-imx8mm:"

class serial_com:
    def __init__(self, comport="COM1"):
        self.comport = comport
        self.ser = serial.Serial()
        self.ser.port = self.comport

        # 115200,N,8,1
        self.ser.baudrate = 115200
        self.ser.bytesize = serial.EIGHTBITS  # number of bits per bytes
        self.ser.parity = serial.PARITY_NONE  # set parity check
        self.ser.stopbits = serial.STOPBITS_ONE  # number of stop bits
        self.ser.timeout = 0.5
        self.ser.writeTimeout = 0.5
        self.ser.xonxoff = False  # disable software flow control
        self.ser.rtscts = False  # disable hardware (RTS/CTS) flow control
        self.ser.dsrdtr = False  # disable hardware (DSR/DTR) flow control

    def cmdsend(self, command):
        self.command = command
        self.ser.write(self.command.encode('UTF-8'))

    def cmdsenddly(self, command, secs=0.5):
        self.command = command
        self.secs = secs
        self.ser.write(self.command.encode('UTF-8'))
        time.sleep(self.secs)

    def cmdread(self, waitstring):
        self.waitstring = waitstring
        response = self.ser.read_until(self.waitstring).decode('UTF-8')
        lastline = loginprompt+waitstring
        fmtresponse = response.strip(lastline)
        return fmtresponse

serctrl = serial_com("COM5")
serctrl.ser.open()

serctrl.cmdsend("ifconfig -a\n")
time.sleep(1)
#line = serctrl.ser.read_until('~#').decode('UTF-8')
recline = serctrl.cmdread("~# ")
print(recline)

serctrl.ser.close()