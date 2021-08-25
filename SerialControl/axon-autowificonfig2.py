"""This script is used for controlling the debug console
send command to board to bring up the wifi connection
Version 2: use OOB
"""
import serial
import time
import re

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

    def cmdread(self, waitstring="\n"):
        self.waitstring = waitstring
        response = self.ser.read_until(self.waitstring).decode('UTF-8')
        lastline = loginprompt+waitstring
        fmtresponse = response.strip(lastline)
        return fmtresponse

loginprompt = "axon-imx8mm login:"
inprompt = "root@axon-imx8mm:~#"
Target_SSID = "Synology_520HMX_5G"
Wifipasskey = "82273585"
waitstring = "~# "

#iperf test parameter
IperfServ = "10.88.88.147"

serctrl = serial_com("COM5")

macidRegex = re.compile('([a-fA-F]|\d){12}')
wifiphraseRegex = re.compile('wifi_\w{12}_\w.+_managed_psk')

print("test starting")

try:
    serctrl.ser.open()
except Exception as ex:
    print("open serial port error " + str(ex))
    exit()

if serctrl.ser.isOpen():

    try:
        serctrl.ser.reset_input_buffer()  # flush input buffer
        serctrl.ser.reset_output_buffer() # flush output buffer

        serdata = ""
        count = 0
        while inprompt not in serdata:
            if count <= 30:
                serdata = serctrl.cmdread()
                if serdata != "":
                    print(serdata)

            if loginprompt in serdata:
                #serctrl.ser.write('root\n'.encode('UTF-8'))
                serctrl.cmdsend('root\n')
                serdata = serctrl.cmdread(waitstring)
                print("root account is log in")
                #print(serdata)

            time.sleep(0.1)
            count += 1

            if count > 30:
                serctrl.cmdsend('\n')
                serdata = serctrl.ser.read_all().decode('UTF-8')

        time.sleep(3)
        #get eth macid
        #serctrl.cmdsend("ifconfig eth0 | grep HWaddr | awk '{print $NF}' | sed 's/://g'\n")
        #time.sleep(1)
        #sermacid = serctrl.ser.read_all().decode('UTF-8')
        #ethmacid = macidRegex.search(sermacid).group()
        #print(ethmacid)

        #start to config wifi

        #send connmanctl
        serctrl.cmdsenddly("connmanctl\n", 0.5)
        reponse = serctrl.ser.read_all().decode('UTF-8')
        print(reponse)
        #connmanctl shell
        #time.sleep(0.5)
        serctrl.cmdsenddly('enable wifi\n', 0.5)
        serctrl.cmdsenddly('scan wifi\n', 2)
        serctrl.cmdsenddly('exit\n', 0.5)
        serctrl.ser.flush()
        reponse = serctrl.ser.read_all().decode('UTF-8')
        print(reponse)

        #shell
        serctrl.cmdsenddly("connmanctl services > /tmp/wifiservices\n", 0.5)
        serctrl.cmdsend("sync\n")
        serctrl.cmdsenddly("cat /tmp/wifiservices | grep ", 0.5)
        serctrl.cmdsenddly(Target_SSID, 0.5)
        serctrl.cmdsenddly(" | grep 001\n", 0.5)
        wifisvs = serctrl.cmdread(waitstring)
        time.sleep(1)

        print(wifisvs)
        wifikey = wifiphraseRegex.search(wifisvs).group()
        print(wifikey)

        #connmanctl shell
        serctrl.cmdsenddly('connmanctl\n', 1)
        #connmanctl shell
        serctrl.cmdsenddly('agent on\n', 1)
        serctrl.cmdsenddly('connect ', 0.5)
        serctrl.cmdsenddly(wifikey, 0.5)
        serctrl.cmdsenddly('\n', 0.5)
        #enter Passphrase
        serctrl.cmdsend(Wifipasskey)
        serctrl.cmdsenddly('\n', 3)
        print(serctrl.cmdread())
        time.sleep(3)

        serctrl.cmdsend('state\n')
        print(serctrl.cmdread())
        time.sleep(1)
        serctrl.cmdsend('exit\n')
        print(serctrl.cmdread(waitstring))
        print("wifi connection completed")
        serctrl.cmdsenddly("\n", 2)

        #iperf test
        print("Iperf BI-direction test starting ...")
        serctrl.cmdsend("iperf3 -c ")
        serctrl.cmdsend(IperfServ)
        serctrl.cmdsenddly(" -t 30 -i 5 -p 5201&", 0.5)
        serctrl.cmdsend("\n")
        serctrl.cmdsend("iperf3 -c ")
        serctrl.cmdsend(IperfServ)
        serctrl.cmdsenddly(" -t 30 -i 5 -p 5202 -R&", 0.5)
        serctrl.cmdsend("\n")

        testmsg = serctrl.cmdread()
        while "iperf Done." not in testmsg:
            print(testmsg)
            testmsg=serctrl.cmdread()
            time.sleep(5)

        print(testmsg)
        print("iperf test completed")

    except Exception as e1:
        print("communicating error , the port is occupied" + str(e1))

else:
    print("open serial port error")



