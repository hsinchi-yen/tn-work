"""
The purpose of this script : dump the frame buffer data from QC disk
The script is only supported on ubuntu platform
reuired utilit - fbtopng
"""

import os
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

    testmsg = serctrl.cmdread()
    while desiremsg not in testmsg:
        print(testmsg)
        testmsg = serctrl.cmdread()
        time.sleep(secs)
    print(testmsg)
# ---------- Subfunction for reading message from console End----------

def dot_print(x):
    for i in range(x):
        print(".", end=" ")
        time.sleep(1)
    print("\n")

loginprompt = "~#"
raw_file = "fb0.raw"
fbdev = "/dev/fb0"
png_file = "fb0.png"
remote_serv = "10.88.88.147"

Res_W_H_Regex = re.compile("\d{3,4}x\d{3,4}")

serctrl = SerialCom("/dev/ttyUSB0")

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
        # console command
        # check if the mounted partition is read-only status
        serctrl.cmdsend('\n')
        serctrl.cmdsenddly("grep \'ro\' \/proc\/mounts\n", 0.5)
        res_msg = serctrl.cmdread()

        # set the partition writable
        if "ext3 ro" in res_msg:
            serctrl.cmdsenddly("mount / -o remount,rw\n", 0.5)
            res_msg = serctrl.cmdread()
            print("working partition is set to r/w")
        else:
            print("working partition is set already r/w")

    # get the fb0 screen resolution
        serctrl.cmdsenddly("fbset\n", 0.5)
        res_msg = serctrl.cmdread()
        Res_WNH = Res_W_H_Regex.search(res_msg).group()

    # get for resolution width and height
        print("The current resolution :", Res_WNH)
        pic_size = Res_WNH.split("x")
        pic_width = pic_size[0]
        pic_height = pic_size[1]

    # dump framebuffer fb0 to local disk
        print("dump framebuffer data")
        serctrl.cmdsend("dd if=")
        serctrl.cmdsend(fbdev)
        serctrl.cmdsend(" of=")
        serctrl.cmdsend(raw_file)
        serctrl.cmdsend("\n")
        msg_readuntil("records", 2)
        serctrl.cmdsenddly("sync\n", 0.5)

    # stop qc test script
        #serctrl.cmdsenddly("./stop.sh\n", 1)
        #print(serctrl.cmdread())
        #print("stop qc script ...")
        dot_print(10)

        serctrl.cmdsenddly("udhcpc\n", 1)
        #print(serctrl.cmdread())
        dot_print(10)

    # local command
    # set nc command for listening
        #print("Kill current NC process")
        #os.system("killall nc")
        print("Intial remote linsting port fore receving file")
        os.system("nc -l -p 12345 > " + raw_file + "&")
        time.sleep(1)

    # console command
    # set nc command for sending
        serctrl.cmdsend('nc -w ')
        serctrl.cmdsend('3 ')
        serctrl.cmdsend(remote_serv)
        serctrl.cmdsend(' 12345 < ')
        serctrl.cmdsend(raw_file)
        serctrl.cmdsenddly('\n', 1)
        print(serctrl.cmdread())
        time.sleep(3)
    # local command
    # Use fbtopng to convert raw to png

        print("Screenshot convertion...")
        print("./fbtopng %s %s %s %s" %(pic_width, pic_height, raw_file, png_file))
        os.system("./fbtopng %s %s %s %s" %(pic_width, pic_height, raw_file, png_file))
        print("%s Image is downloaded!" %png_file)
        time.sleep(0.5)

    # raw file clear for local and remote
        os.system("rm -rf %s" %(raw_file))
        serctrl.cmdsenddly("rm -rf " + raw_file + "\n", 0.5)
        print(serctrl.cmdread())

    except Exception as e1:
        print("communicating error , the port is occupied" + str(e1))
        serctrl.ser.close()
        print("the comport is closed")
