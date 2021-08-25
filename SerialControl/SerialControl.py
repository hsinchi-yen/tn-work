import serial, time

loginprompt = "axon-imx8mp login:"
inprompt = "root@axon-imx8mp:~#"

ser = serial.Serial()
ser.port = "5"

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

        # write 8 byte data
        ser.write('dmesg\n'.encode('UTF-8'))
        ser.flush()
        time.sleep(0.5)  # wait 0.5s

        response2 = ser.read_until(loginprompt).decode('UTF-8')
        time.sleep(5)
        print(response2)

        ser.write('root\n'.encode('UTF-8'))
        response = ser.read_until(inprompt).decode('UTF-8')
        print(response)

        ser.write('\n'.encode('UTF-8'))
        response = ser.read_until(inprompt).decode('UTF-8')
        print(response)

        time.sleep(0.5)

        ser.close()
    except Exception as e1:
        print("communicating error " + str(e1))

else:
    print("open serial port error")

if "Linux version 5.4.70-2.3." in response2:
    print("Yes, it's kernel 5")

