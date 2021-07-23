: '
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Run the csi camera detection test with power cycle or reboot
 Script name       : CSI_CAM_Test.sh
 Author            : lancey
 Date created      : 20210722
 Test Platform     : EDM-G IMX8MP + EDM-G WB
 -----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20210722    lancey      1      Initial draft for test
************************************************************************
'
#!/bin/bash

# Test Configuration Pre-define =======
#Test log
LOGFILE=/home/root/DEV_TEST_LOG.txt
TFTP_SERVER_IP=10.88.88.229

CAM_1_LOG=/home/root/CAM_1_LOG.txt
CAM_2_LOG=/home/root/CAM_2_LOG.txt

#Prefixfor boot time
REF_BOOT_TIME=0

#CommTimestape
COMM_TIMESTAMP=""

# CAMERA Devices - Tevi-ov5645
CAM_DEVADDR="003c"

declare -A CAM_DEVS
CAM_DEVS["CAM_1"]="003c (1)"
CAM_DEVS["CAM_2"]="003c (2)"
MIPI_CAM_FOUND_KEY="created link"

#Reboot params
REBOOTACTIVE=0
# WDT : Watchdog Trigger , RBT : reboot
BOOTMODE="RBT"
# counter time setter
SECS_COUNTDOWN=5
RESTARTTIME=500

# Test Configuration Pre-define END =======

#Generate a log file template
Log_Gen()
{
  cat <<EOF >/$LOGFILE
Peripherial Test Result
=========================================
Boot_Time=0

CAM_1_UP=0
CAM_1_DOWN=0

CAM_2_UP=0
CAM_2_DOWN=0

EOF
  sync
  sleep 1
}

#Modify the boot time from the test log file  - /$LOGFILE
BOOTLOG_Mod()
{
  echo "Test boot time log update ..."
  bootcount=$(cat $LOGFILE | grep Boot_Time | cut -d '=' -f2)
  bootcount=$(($bootcount+1))
  REF_BOOT_TIME=$bootcount
  sed -i -e "s/Boot_Time=[[:digit:]]\+/Boot_Time=$bootcount/g" $LOGFILE
}

#Modify the camera up log from
CAMLOG_Mod()
{
  echo "Test Camera log update ..."
  sed -i -e "s/$1=[[:digit:]]\+/$1=$2/g" $LOGFILE
  echo
}

# for time count down
CountDowner()
{
  #1 SEC_COUNTDOWN
  for (( i = $1 ; i >= 0 ; i-- )); do
	echo -ne "Time count down : $i "'\r'
	sleep 1
  done
  echo
}

SW_Rebooter()
{
  count=$(cat $LOGFILE | grep Boot_Time | cut -d '=' -f2)
  if [ $count -le $RESTARTTIME ]; then
    echo "System reboot"
	  sleep 2
    reboot
  else
    sleep 5
    echo "Test Completed - boot time : $count"
  fi
}

WD_Trigger()
{
  count=$(cat $LOGFILE | grep Boot_Time | cut -d '=' -f2)

  if [ $count -le $RESTARTTIME ]; then
    echo "======================"
    echo "*** enable watchdog"
    echo "======================"
    sleep 2
    wait $!
    echo 1 > /dev/watchdog

    echo "===================================="
    echo "*** trigger - kernel panic - watchdog"
    echo "===================================="
    sleep 2
    wait $!
    echo c > /proc/sysrq-trigger

  else
    echo "Test Completed - boot time : $count"
  fi
}

GetTime()
{
  TimeStamp=$(date +"%Y%m%d%H%M%S")
  echo "$TimeStamp"
}

#tftp upload function
tftp_upload()
{
  #$1 TFTP SERVER IP
  Savedimgs=$(ls | grep ".jpg")
  for img in $Savedimgs; do
    RtName="${REF_BOOT_TIME}-${COMM_TIMESTAMP}_${img}"
    echo "$img is uploading to tftp Server [$1] with new filename : [$RtName]..."
    tftp -p -l $img -r $RtName $1
    sleep 1
  done
}

#Remove saved capture images
Clearimages()
{
  Savedimgs=$(ls | grep ".jpg")
  for img in $Savedimgs; do
    echo "$img is removed"
    rm $img
  done
  sync && sleep 0.5
}

#use camera to capture images
Capture_Image()
{
  CAM_DEVADDR="003c"
  CAM_DEVID1="003c (1)"
  CAM_DEVID2="003c (2)"
  MIPI_CAM_FOUND_KEY="created link"

  CAM_QTY=$(dmesg | grep $CAM_DEVADDR | grep "$MIPI_CAM_FOUND_KEY" | wc -l)
  #grab the current resolution in weston
  WESTON_INI=/etc/xdg/weston/weston.ini

  if [ $CAM_QTY -eq 2 ]; then
    CAM_DEVS=$(ls /dev/video* | grep video | head -2 | sort )
  else

    if [[ ! -z $(dmesg | grep $CAM_DEVADDR | grep "$CAM_DEVID1") ]]; then
      dmesg | grep "$MIPI_CAM_FOUND_KEY"
      CAM_DEVS=$(ls /dev/video0 | sort)
    fi

    if [[ ! -z $(dmesg | grep $CAM_DEVADDR | grep "$CAM_DEVID2") ]]; then
      dmesg | grep "$MIPI_CAM_FOUND_KEY"
      CAM_DEVS=$(ls /dev/video1 | sort)
    fi
  fi

  if [ $CAM_QTY -eq 0 ]; then

    echo "No Camera Device was not found !"
    echo "Please check if the MIPI cable connection is secure or firm ..."
    echo

  else

    #====== MIPI Camera Test Start =====
    echo "Checking the Camera device's availability"
    echo
    dmesg | grep $CAM_DEVADDR
    sleep 1
    echo
    echo "$CAM_QTY Camera device - found"
    sleep 1

    #Fetch RES_X x RES_Y from weston.ini
    RES_OPTIONA=$(cat $WESTON_INI | grep size= | cut -d '=' -f2)
    #Fetch "RES_X x RES_Y" from fbset
    RES_OPTIONB=$(fbset | grep x | cut -d " " -f2 | awk '{gsub(/"|mode| /,"");print}')

    OPTIONB=$(echo $RES_OPTIONB | cut -d 'x' -f1)
    OPTIONA=$(echo $RES_OPTIONA | cut -d 'x' -f1)

    # Decide if screen resolution refer to weston or fbset
    if [ $OPTIONB -gt $OPTIONA ]; then
      RES_X=$(echo $RES_OPTIONA | cut -d 'x' -f1)
      RES_Y=$(echo $RES_OPTIONA | cut -d 'x' -f2)
    else
      RES_X=$(echo $RES_OPTIONB | cut -d 'x' -f1)
      RES_Y=$(echo $RES_OPTIONB | cut -d 'x' -f2)
    fi

  # When Camera devices are multiple
    CSIID=1
    for CAMID in $CAM_DEVS;
    do
      #Display cam image on Screen
      if [ $RES_X -lt $RES_Y ]; then
        gst-launch-1.0 v4l2src device=$CAMID ! textoverlay text="Source : $CAMID" valignment=top halignment=left ! \
        video/x-raw,width=$RES_Y,height=$RES_X ! \
        glimagesink rotate-method=1 render-rectangle="<0,0,$RES_X,$RES_Y>" &
      else
        gst-launch-1.0 v4l2src io-mode=2 device=$CAMID ! textoverlay text="Source : $CAMID" valignment=top halignment=left \
        ! glimagesink render-rectangle="<0,0,$RES_X,$RES_Y>" &
      fi
      camera_test_ID=$!

      CountDowner 10
      kill -9 $camera_test_ID

      #Capture Image from CAM
      echo "Capture $CAMID"
      sleep 1

     if [ $RES_X -lt $RES_Y ]; then
        gst-launch-1.0 v4l2src io-mode=2 device=$CAMID num_buffers=1 ! \
        video/x-raw,width=$RES_Y,height=$RES_X,framerate=30/1 ! \
        imxvideoconvert_g2d ! jpegenc ! filesink location=CSICAM_${CSIID}.jpg
      else
        gst-launch-1.0 v4l2src io-mode=2 device=$CAMID num_buffers=1 ! \
        video/x-raw,width=$RES_X,height=$RES_Y,framerate=30/1 ! \
        imxvideoconvert_g2d ! jpegenc ! filesink location=CSICAM_${CSIID}.jpg
     fi
      CSIID=$(($CSIID+1))

    done
    fi
#====== MIPI Camera Capture End =====
}

#Write CAM up/down log
CAM_UP_log_update()
{
  #echo "Count : $REF_BOOT_TIME, $dev : $1"
  #COMM_TIMESTAMP=$(GetTime)

  camlog=$(eval echo $2_LOG.txt)
  #echo "Filename : $camlog"
  echo "Time: $COMM_TIMESTAMP, Count : $REF_BOOT_TIME, $dev : $1" >> $camlog
}

CountDowner 3

# Build a test log template
if [ -f $LOGFILE ]; then
    echo "test log is existed"
    BOOTLOG_Mod
else
    Log_Gen
    BOOTLOG_Mod
fi

# CAM 1/2 Driver up log check
if [ -f $CAM_1_LOG ]; then
   echo "$CAM_1_LOG is existed"
else
   touch $CAM_1_LOG
fi

if [ -f $CAM_2_LOG ]; then
   echo "$CAM_2_LOG is existed"
else
   touch $CAM_2_LOG
fi

# update driver up time
COMM_TIMESTAMP=$(GetTime)
for dev in "${!CAM_DEVS[@]}"; do

  if [[ -n $(dmesg | grep "${CAM_DEVS[$dev]}") && -n $(dmesg | grep "$CAM_DEVADDR" | grep "${MIPI_CAM_FOUND_KEY}") ]]; then
      echo "$dev is FOUND"
      count=$(grep "${dev}_UP" $LOGFILE | cut -d '=' -f2)
      count=$(($count+1))
      CAMLOG_Mod "${dev}_UP" $count
      CAM_UP_log_update "PASS" "$dev"
  else
      echo "$dev is UNFOUND"
      count=$(grep "${dev}_DOWN" $LOGFILE | cut -d '=' -f2)
      count=$(($count+1))
      CAMLOG_Mod "${dev}_DOWN" $count
      CAM_UP_log_update "FAIL" "$dev"
  fi

done
sleep 1 && sync

cat $LOGFILE

#CountDowner

#Perform CameraTest
Capture_Image
sync && sleep 2

#upload capture images
tftp_upload $TFTP_SERVER_IP
sleep 2

Clearimages

# Check if reboot is needed.
if [ $REBOOTACTIVE -eq 1 ]; then

  case $BOOTMODE in
  "RBT")
    # reboot
    SW_Rebooter
  ;;
  "WDT")
    # watchdog trigger
    WD_Trigger
  ;;
  esac

else

  echo "Test Completed !"

fi