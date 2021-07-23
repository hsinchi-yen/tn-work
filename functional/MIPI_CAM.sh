<<'COMMENTS'
************************************************************************
 Purpose           : Test Script for MIPI camera in OS Yocto 2.5
 Script name       : MIPI_CAM.sh
 Author            : lancey
 Date created      : 20210104
 Purpose           : Verify MIPI CSI-2 bus and camera functionality - mapped to test case MPI001 in technexion wiki.
 Verified Platform : iMX8, Yocto 2.5
----------------------------------------------------------------------- 
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format) 
-----------------------------------------------------------------------
 20210105    lancey      1      Initial draft
 20210108    lancey      1      Add text description for camera
************************************************************************
COMMENTS
#!/bin/bash

keypress=0

KeyDetect()
{
    while [ $keypress -eq 0 ]; do
    if read -t 0; then
      read -n 1 char

      break
    else
      sleep 1
    fi
    done
}

CAM_DEVID1="ov5645_mipi 1"
CAM_DEVID2="ov5645_mipi 2"
MIPI_CAM_FOUND_KEY="mipi is found"

CAM_QTY=$(dmesg | grep "$MIPI_CAM_FOUND_KEY" | wc -l)
WESTON_INI=/etc/xdg/weston/weston.ini

if [ $CAM_QTY -eq 2 ]; then
  CAM_DEVS=$(ls /dev/video* | grep video | sort)
else

  if [[ ! -z $(dmesg | grep camera | grep "$CAM_DEVID1" | grep "$MIPI_CAM_FOUND_KEY") ]]; then
    CAM_DEVS=$(ls /dev/video0 | sort)
  fi

  if [[ ! -z $(dmesg | grep camera | grep "$CAM_DEVID2" | grep "$MIPI_CAM_FOUND_KEY") ]]; then
    CAM_DEVS=$(ls /dev/video1 | sort)
  fi

fi

clear

if [ $CAM_QTY -eq 0 ]; then

   echo "No Camera Device was not found !"
   echo "Please check if the MIPI cable connection is secure or firm ..."
   echo

else

  #====== MIPI Camera Test Start =====
  echo "Checking the Camera device's availability"
  echo
  dmesg | grep camera
  sleep 1
  echo
  echo "$CAM_QTY Camera device - found"
  sleep 1

  #Fetch RES_X x RES_Y from weston.ini
  RES_OPTIONA=$(cat $WESTON_INI | grep size= | cut -d '=' -f2)
  #Fetch "RES_X x RES_Y" from fbset
  RES_OPTIONB=$(fbset | grep x | cut -d " " -f2 | awk '{gsub(/\"|mode|\ /,"");print}')

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
  for CAMID in $CAM_DEVS;
  do
    echo "Test Camera $CAMID"
    keypress=0

    if [ $RES_X -lt $RES_Y ]; then
      gst-launch-1.0 v4l2src device=$CAMID ! textoverlay text="Source : $CAMID" valignment=top halignment=left ! video/x-raw,width=$RES_Y,height=$RES_X !glimagesink rotate-method=1 render-rectangle="<0,0,$RES_X,$RES_Y>" &
    else
      gst-launch-1.0 v4l2src io-mode=2 device=$CAMID ! textoverlay text="Source : $CAMID" valignment=top halignment=left ! glimagesink render-rectangle="<0,0,$RES_X,$RES_Y>" &
    fi
    camera_test_ID=$!


    sleep 5

    echo
    echo "Please check the MIPI Camera's input on Current Display [LCD/Panel]"
    echo "Resolution : $RES_X x $RES_Y ..."
    echo
    KeyDetect
    kill -9 $camera_test_ID
  done


#====== MIPI Camera Test End =====

fi

echo "Test Completed !"







