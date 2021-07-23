<<'COMMENTS'
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Read/Write eMMC storage and display R/W speed
                     use fio for rand R/W test.
 Script name       : eMMC_Fio_stress_Test.sh
 Author            : lancey
 Date created      : 20210111
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20200111    lancey      1      Initial draft for eMMC test
************************************************************************
COMMENTS
#!/bin/bash
#===FIOCFG===
IOENGINE=libaio
FIODIRECT=1
FIORUNTIME=300
TESTLOGPATH=/tmp/
#===FIOCFG===

#function for convert single char from lower case to upper case
Char_Converter()
{
  AnsR=$(echo $1 | tr '[:lower:]' '[:upper:]')
  echo "$AnsR"
}

#function for running fio test with desire parameters
#$1=disk, $2 r/w test mode, $3 block size, $4 r/w r percentage, $5 test que, $6 test threads, $7 test name
fio_test()
{
  sudo fio -filename=$1 \
  -direct=$FIODIRECT \
  -rw=$2 \
  -ioengine=$IOENGINE \
  -bs=$3 \
  -rwmixread=$4 \
  -iodepth=$5 \
  -numjobs=$6 \
  -runtime=$FIORUNTIME \
  -group_reporting -name="${7}" |\
  tee "${TESTLOGPATH}${7}.txt"
}

clear

if [ "$1" == "" ]; then
  DUTID=/dev/mmcblk2
else
  DUTID=$1
fi


echo "Please confirm your desired test device is $DUTID:"
read -p "Press Y For Test : " -n 1 Ans
printf "\n"
Ans=$(Char_Converter "$Ans")

while [ $Ans != "N" ]; do

  Ans=$(Char_Converter "$Ans")

  if [ $Ans = "Y" ]; then

    echo "Fio Read/Write 4k Test..."
    fio_test $DUTID "randrw" "4k" "50" "256" "4" "Fio_Read_Write_Test_RND_4K_256Q4T"
    echo ""

    sleep 3&
    wait $!

    echo "Fio Read/Write 64k Test..."
    fio_test $DUTID "write" "64K" "50" "64" "4" "Fio_Read_Write_Test_RND_64K_64Q4T"
    echo ""

    echo "--------------------------------------------"
    echo ""

    echo ""
    read -p "Continue For Testing (Y/N) :" -n 1 Ans
    Ans=$(Char_Converter "$Ans")

  else
    echo -e "\b"
    read -p "Please press the correct KEY (Y/N) :" -n 1 Ans
    Ans=$(Char_Converter "$Ans")
  fi

done
echo ""
echo "Test Completed Bye!!"

