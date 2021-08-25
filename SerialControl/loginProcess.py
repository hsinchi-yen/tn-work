"""This script is used for controlling the debug console
send command to board to bring up the wifi connection
"""
import serial, time

loginprompt = "axon-imx8mm login:"
inprompt = "root@axon-imx8mm:~#"

ser = serial.Serial()
ser.port = "COM5"

#115200,N,8,1
ser.baudrate = 115200
ser.bytesize = serial.EIGHTBITS #number of bits per bytes
ser.parity = serial.PARITY_NONE #set parity check
ser.stopbits = serial.STOPBITS_ONE #number of stop bits
ser.timeout = 0.5
ser.writeTimeout = 0.5
ser.xonxoff = False    #disable software flow control
ser.rtscts = False     #disable hardware (RTS/CTS) flow control
ser.dsrdtr = False     #disable hardware (DSR/DTR) flow control

try:
    ser.open()
except Exception as ex:
    print("open serial port error " + str(ex))
    exit()

if ser.isOpen():

    try:
        ser.flushInput()  # flush input buffer
        ser.flushOutput()  # flush output buffer

        serdata=""
        while inprompt not in serdata:
            serdata = ser.read_until(loginprompt).decode('UTF-8')
            print(serdata)

            if loginprompt in serdata:
                ser.write('root\n'.encode('UTF-8'))
                serdata = ser.read_all().decode('UTF-8')
                print("root account is log in")
                print(serdata)

            time.sleep(1)
            if serdata =="":
                ser.write('\n'.encode('UTF-8'))

    except Exception as e1:
        print("communicating error " + str(e1))

else:
    print("open serial port error")



