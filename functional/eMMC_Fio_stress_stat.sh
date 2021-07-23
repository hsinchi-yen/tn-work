<<'COMMENTS'
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Read/Write eMMC storage and display R/W speed
                     use fio for rand R/W test.
 Script name       : eMMC_Fio_stress_stat.sh
 Author            : lancey
 Date created      : 20210113
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20200113    lancey      1      Initial draft for eMMC test
************************************************************************
COMMENTS
#!/bin/bash
#===FIOCFG===
IOENGINE=libaio
FIODIRECT=1
FIORUNTIME=10
IODEPTH=128
TESTLOGPATH=/tmp/
BLKSIZE=(4 8 16 32 64 128 256 512 1024)
#===FIOCFG===

DEFAULT_DEV=/dev/mmcblk2

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
  -allow_mounted_write=1 \
  -group_reporting -name="${7}" |\
  tee "${TESTLOGPATH}${7}.txt"
}

fio_seq_r_test()
{

  for i in "${BLKSIZE[@]}"; do

    echo "Fio Seq Read ${i}K Test..."
    fio_test $1 "read" "${i}k" "100" "$IODEPTH" "4" "Fio_Read_Test_Seq_${i}K_${IODEPTH}Q4T"
    echo ""
    sleep 1&
    wait $!
    sync
    sleep 1

    echo -n "${i}k: " >> ${TESTLOGPATH}Fio_Read_Test_Seq.txt
    STATDATA=$(cat "${TESTLOGPATH}Fio_Read_Test_Seq_${i}K_${IODEPTH}Q4T".txt | grep "READ:" | cut -d ',' -f1)
    echo $STATDATA >> ${TESTLOGPATH}Fio_Read_Test_Seq.txt
    sync
    sleep 1

  done
}

fio_seq_w_test()
{
  for i in "${BLKSIZE[@]}"; do

    echo "Fio Seq Write ${i}K Test..."
    fio_test $1 "write" "${i}k" "100" "$IODEPTH" "4" "Fio_Write_Test_Seq_${i}K_${IODEPTH}Q4T"
    echo ""
    sleep 1&
    wait $!
    sync
    sleep 1

    echo -n "${i}k: " >> ${TESTLOGPATH}Fio_Write_Test_Seq.txt
    STATDATA=$(cat "${TESTLOGPATH}Fio_Write_Test_Seq_${i}K_${IODEPTH}Q4T".txt | grep "WRITE:" | cut -d ',' -f1)
    echo $STATDATA >> ${TESTLOGPATH}Fio_Write_Test_Seq.txt
    sync

  done
}

#FIO random read test
fio_rand_r_test()
{

  for i in "${BLKSIZE[@]}"; do

    echo "Fio Rand Read ${i}K Test..."
    fio_test $1 "randread" "${i}k" "100" "$IODEPTH" "4" "Fio_Read_Test_Rand_${i}K_${IODEPTH}Q4T"
    echo ""
    sleep 1&
    wait $!
    sync
    sleep 1

    echo -n "${i}k: " >> ${TESTLOGPATH}Fio_Read_Test_Rand.txt
    STATDATA=$(cat "${TESTLOGPATH}Fio_Read_Test_Rand_${i}K_${IODEPTH}Q4T".txt | grep "READ:" | cut -d ',' -f1)
    echo $STATDATA >> ${TESTLOGPATH}Fio_Read_Test_Rand.txt
    sync
    sleep 1

  done
}

#FIO random write test
fio_rand_w_test()
{

  for i in "${BLKSIZE[@]}"; do

    echo "Fio Rand Write ${i}K Test..."
    fio_test $1 "randwrite" "${i}k" "100" "$IODEPTH" "4" "Fio_Write_Test_Rand_${i}K_${IODEPTH}Q4T"
    echo ""
    sleep 1&
    wait $!
    sync
    sleep 1

    echo -n "${i}k: " >> ${TESTLOGPATH}Fio_Write_Test_Rand.txt
    STATDATA=$(cat "${TESTLOGPATH}Fio_Write_Test_Rand_${i}K_${IODEPTH}Q4T".txt | grep "WRITE:" | cut -d ',' -f1)
    echo $STATDATA >> ${TESTLOGPATH}Fio_Write_Test_Rand.txt
    sync
    sleep 1

  done
}

#FIO random read/write test
fio_randrw_test()
{
  for i in "${BLKSIZE[@]}"; do

    echo "Fio RAND Read/Write ${i}K Test..."
    fio_test $1 "randrw" "${i}k" "50" "$IODEPTH" "4" "Fio_Read_Write_Test_Rand_${i}K_${IODEPTH}Q4T"
    echo ""
    sleep 1&
    wait $!
    sync
    sleep 1

    echo -n "${i}k: " >> ${TESTLOGPATH}Fio_Read_Write_Test_Rand.txt
    STATDATA=$(cat "${TESTLOGPATH}Fio_Read_Write_Test_Rand_${i}K_${IODEPTH}Q4T".txt | grep -E "READ:|WRITE:" | cut -d ',' -f1)
    echo $STATDATA >> ${TESTLOGPATH}Fio_Read_Write_Test_Rand.txt
    sync

  done
}

clear

if [ "$1" == "" ]; then
  DUTID=$DEFAULT_DEV
else
  DUTID=$1
fi


echo "Please confirm your desired test device is $DUTID:"
read -p "Press Y For Test : " -n 1 Ans
printf "\n"
Ans=$(Char_Converter "$Ans")

while [ $Ans != "N" ]; do

  Ans=$(Char_Converter "$Ans")

  if [ $Ans == "Y" ]; then
    echo
    #seq read
    rm ${TESTLOGPATH}Fio_Read_Test_Seq.txt
    touch ${TESTLOGPATH}Fio_Read_Test_Seq.txt
    fio_seq_r_test $DUTID

    #seq write
    rm ${TESTLOGPATH}Fio_Write_Test_Seq.txt
    touch ${TESTLOGPATH}Fio_Write_Test_Seq.txt
    fio_seq_w_test $DUTID

    #rand read
    rm ${TESTLOGPATH}Fio_Read_Test_Rand.txt
    touch ${TESTLOGPATH}Fio_Read_Test_Rand.txt
    fio_rand_r_test $DUTID

    #rand write
    rm ${TESTLOGPATH}Fio_Write_Test_Rand.txt
    touch ${TESTLOGPATH}Fio_Write_Test_Rand.txt
    fio_rand_w_test $DUTID

    #rand read/write
    rm ${TESTLOGPATH}Fio_Read_Write_Test_Rand.txt
    touch ${TESTLOGPATH}Fio_Read_Write_Test_Rand.txt
    fio_randrw_test $DUTID

    echo
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

echo
echo "Fio_Read_Test_Seq"
cat ${TESTLOGPATH}Fio_Read_Test_Seq.txt
echo

echo "Fio_Write_Test_Seq"
cat ${TESTLOGPATH}Fio_Write_Test_Seq.txt
echo

echo "Fio_Read_Test_Rand"
cat ${TESTLOGPATH}Fio_Read_Test_Rand.txt
echo

echo "Fio_Write_Test_Rand"
cat ${TESTLOGPATH}Fio_Write_Test_Rand.txt
echo

echo "Fio_Read_Write_Test_Rand"
cat ${TESTLOGPATH}Fio_Read_Write_Test_Rand.txt
echo

echo ""
echo "Test Completed,Bye!!"

