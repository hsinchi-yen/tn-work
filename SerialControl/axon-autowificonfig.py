"""This script is used for controlling the debug console
send command to board to bring up the wifi connection
"""
import serial, time
import re

loginprompt = "axon-imx8mm login:"
inprompt = "root@axon-imx8mm:~#"
Target_SSID = "Synology_520HMX_5G"
Wifipasskey = "82273585"

#iperf test parameter
IperfServ = "10.88.88.147"

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

macidRegex = re.compile('([a-fA-F]|\d){12}')
wifiphraseRegex = re.compile('wifi_\w{12}_\w.+_managed_psk')

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
        count=0
        while inprompt not in serdata:
            if count <= 50:
                serdata = ser.read_until(loginprompt).decode('UTF-8')
                if serdata != "":
                    print(serdata)
                else:
                    pass

            if loginprompt in serdata:
                ser.write('root\n'.encode('UTF-8'))
                serdata = ser.read_all().decode('UTF-8')
                print("root account is log in")
                print(serdata)

            time.sleep(0.1)
            count += 1

            if count >= 50:
                print("Already loggin")
                ser.write('\n'.encode('UTF-8'))
                serdata = ser.read_all().decode('UTF-8')

        #get eth macid
        ser.write("ifconfig eth0 | grep HWaddr | awk '{print $NF}' | sed 's/://g'\n".encode('UTF-8'))
        time.sleep(1)
        sermacid = ser.read_all().decode('UTF-8')
        ethmacid = macidRegex.search(sermacid).group()

        #start to config wifi

        #send connmanctl
        ser.write('connmanctl\n'.encode('UTF-8'))
        #connmanctl shell
        time.sleep(0.5)
        ser.write('enable wifi\n'.encode('UTF-8'))
        time.sleep(0.5)
        ser.write('scan wifi\n'.encode('UTF-8'))
        time.sleep(2)
        ser.write('exit\n'.encode('UTF-8'))
        time.sleep(0.5)
        #shell
        ser.write('connmanctl services > /tmp/wifiservices\n'.encode('UTF-8'))
        time.sleep(0.5)
        ser.write("cat /tmp/wifiservices | grep ".encode('UTF-8'))
        ser.write(Target_SSID.encode('UTF-8'))
        time.sleep(0.5)
        ser.write(" | grep 001\n".encode('UTF-8'))
        ser.flush()
        time.sleep(0.5)
        wifisvs = ser.read_all().decode('UTF-8')
        time.sleep(0.5)

        #print(wifisvs)
        wifikey = wifiphraseRegex.search(wifisvs).group()
        #print(wifikey)

        #connmanctl shell
        ser.write('connmanctl\n'.encode('UTF-8'))
        time.sleep(0.5)
        #connmanctl shell
        ser.write('agent on\n'.encode('UTF-8'))
        time.sleep(0.5)
        ser.write('connect '.encode('UTF-8'))
        time.sleep(0.5)
        ser.write(wifikey.encode('UTF-8'))
        time.sleep(0.5)
        ser.write('\n'.encode('UTF-8'))
        time.sleep(0.5)
        #enter Passphrase
        ser.write(Wifipasskey.encode('UTF-8'))
        ser.write('\n'.encode('UTF-8'))
        time.sleep(0.5)

        ser.write('state\n'.encode('UTF-8'))
        wifistatus = ser.read_all().decode('UTF-8')
        time.sleep(0.5)

        ser.write('exit\n'.encode('UTF-8'))
        print("wifi status :",wifistatus)
        print("wifi connection completed")

    except Exception as e1:
        print("communicating error " + str(e1))

else:
    print("open serial port error")



