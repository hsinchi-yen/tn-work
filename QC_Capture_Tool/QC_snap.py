"""
The purpose of this script : dump the frame buffer data from QC disk
The script is only supported on ubuntu platform
reuired utilit - fbtopng

revised : 2021/09/06 - extra config file to text file
revised : 2021/09/17 - add retry function when eth connection loss
"""

import os
import sys
import re
import serial
import time

# ---------- Class and function definition for serial command set START----------
class SerialCom:
    def __init__(self, comport="/dev/ttyS0"):
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

    def cmdread(self, waitstring="\r\n"):
        self.waitstring = waitstring
        response = self.ser.read_until(self.waitstring).decode('UTF-8')
        lastline = waitstring
        fmtresponse = response.strip(lastline)
        return fmtresponse
# ---------- Class and function definition for serial command set END----------

# ---------- Subfunction for reading message from console Start----------
def msg_readuntil(desiremsg, secs = 0.5):
    global serctrl
    loop_count = 0
    testmsg = serctrl.cmdread()
    while desiremsg not in testmsg:
        print(testmsg)
        testmsg = serctrl.cmdread()
        time.sleep(secs)
        print(testmsg)
        time.sleep(0.2)
        loop_count += 1
        print("message is not receving ...")
        if loop_count > 3:
            break

    return testmsg
# ---------- Subfunction for reading message from console End----------

#----------- Subfunction for obtain config setting start --------------
def sys_config_loader(config_file):
    file_check_result = os.system("test -f " + config_file)
    if file_check_result == 0:
        f = open(config_file, 'r', encoding='UTF-8')
        conf_que = []
        for line in f:
                conf_text = str(line).split(":")
                conf_que.append(conf_text[1].strip('\n'))
        return conf_que
        f.close()
    else:
        f.close()
        print("the config file :", config, "is not existed !")

#----------- Subfunction for obtain config setting end   --------------

#------------ Console Command for Frame buffer dump -------------------
def fb_dumper():
            global fbdev, remote_serv
            print("Dump framebuffer data ...")
            serctrl.cmdsend("dd if=")
            serctrl.cmdsend(fbdev)
            serctrl.cmdsend(" | ")
            serctrl.cmdsend('nc -w ')
            serctrl.cmdsend('3 ')
            serctrl.cmdsend(remote_serv)
            serctrl.cmdsend(' 12345')
            serctrl.cmdsenddly('\n', 1)
            #print(serctrl.cmdread())

#------------ Console Command for Frame buffer End -------------------

#------------ Console Command for IP addr check ----------------------
def con_IP_checker():

    global loginprompt
    global serctrl

    IPAddr_Fetch_Regex = re.compile(r'inet addr:\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}')

    IsIP = None
    Loop_count = 1
    print("Sender IP address check...")

    while IsIP == None:
        serctrl.cmdsenddly("ifconfig eth0 | grep 'inet addr'\n", 1)
        serdata = serctrl.cmdread(loginprompt)
        if IPAddr_Fetch_Regex.search(serdata) != None:
            IsIP = IPAddr_Fetch_Regex.search(serdata).group()
    #print(IsIP)
        else:
            IsIP = None
            time.sleep(1)
            print("%s attempt ..." %str(Loop_count))

        if Loop_count > 10:
            serctrl.ser.close()
            sys.exit("Error, Please check your network connection.")
        else:
            Loop_count += 1

#------------ Command for IP addr check End -------------------

def dot_print(x):
    for i in range(x):
        print(".", end=" ")
        time.sleep(1)
    print("\n")

loginprompt = "~#"
raw_file = "/tmp/fb0.raw"
fbdev = "/dev/fb0"
png_file = "fb0.png"

#conf_params[0] : serial port , conf_params[1] : ip address
conf_params = sys_config_loader("sys.conf")
#remote_serv = "10.88.88.147"
remote_serv = conf_params[1]

Res_W_H_Regex = re.compile("\d{3,4}x\d{3,4}")

#serctrl = SerialCom("/dev/ttyS0")
serctrl = SerialCom(conf_params[0])

#clear all existed nc process
os.system("killall nc")
print("Kill All nc process ...")

try:
    serctrl.ser.open()
except Exception as ex:
    print("open serial port error " + str(ex))
    print("The serial port is occupied !!, please check !!")
    exit()

if serctrl.ser.isOpen():

    try:
        serctrl.ser.reset_input_buffer()  # flush input buffer
        serctrl.ser.reset_output_buffer()  # flush output buffer

        print("Screenshot capture is processing...")

    # get the fb0 screen resolution
        serctrl.cmdsenddly("fbset\n", 0.1)
        res_msg = serctrl.cmdread()
        Res_WNH = Res_W_H_Regex.search(res_msg).group()

    # get for resolution width and height
        print("The current resolution :", Res_WNH)
        pic_size = Res_WNH.split("x")
        pic_width = pic_size[0]
        pic_height = pic_size[1]


        msg = ""

        while "records" not in msg:
            os.system("killall nc")
            con_IP_checker()
            print("Initialing the remote linsting port fore receving file")
            print("nc -l -p 12345 | dd of=" + raw_file)
            os.system("nc -l -p 12345 | dd of=" + raw_file + "&")
            time.sleep(0.5)
            fb_dumper()
            msg = msg_readuntil("records", 1)

    # local command

    # Use fbtopng to convert raw to png

        print("Screenshot convertion...")
        print("./fbtopng %s %s %s %s" %(pic_width, pic_height, raw_file, png_file))
        os.system("./fbtopng %s %s %s %s" %(pic_width, pic_height, raw_file, png_file))
        os.system("sync")

        print("%s Image is downloaded!" %png_file)
        time.sleep(0.5)

        print("Diaply the file ...")
        os.system("eog " + png_file +"&")
        print("Completd.")

    # raw file clear for local and remote
        #os.system("rm -rf %s" %(raw_file))
        #serctrl.cmdsenddly("rm -rf " + raw_file + "\n", 0.5)
        #print(serctrl.cmdread(loginprompt))

    except Exception as e1:
        print("communicating error , the port is occupied" + str(e1))
        serctrl.ser.close()
        print("the comport is closed")
