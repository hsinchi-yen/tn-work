<<'COMMENTS'
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Read/Write eMMC storage and display R/W speed
                     use fio for rand R/W test.
 Script name       : Storage_Dev_stress_log_test.sh
 Author            : lancey
 Date created      : 20210122
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20210125    lancey      1      Initial draft for stress Storage RW log test
 20210126    lancey      1      add eMMCblk error log
************************************************************************
COMMENTS
#!/bin/bash

#Test target
SDNAME=/dev/mmcblk2
FIOTMP=""
BLKERR=/tmp/eMMCblk_log.txt
STR_BLKERR="blk_update_request: I/O error,"
STR_RUNRECOVER="running CQE recovery"

#===FIOCFG===
IOENGINE=libaio
RWPARAM="randrw"
FIODIRECT=1
FIORUNTIME=20
IODEPTH=128
TESTLOGPATH=/tmp/
BLKSIZE=1024K
WRATIO=50
#===FIOCFG===

#function for running fio test with desire parameters
#$1=disk, $2 r/w test mode, $3 block size, $4 r/w r percentage, $5 test que, $6 test threads, $7 test name
FIO_test()
{
  fio -filename=$1 \
  -direct=$FIODIRECT \
  -rw=$2 \
  -ioengine=$IOENGINE \
  -bs=$3 \
  -rwmixread=$4 \
  -iodepth=$5 \
  -numjobs=$6 \
  -runtime=$FIORUNTIME \
  -group_reporting -name="${7}" > "${TESTLOGPATH}${7}.txt"

  sync
  sleep 2

  FIOTMP="${TESTLOGPATH}${7}.txt"
}

GetTime()
{
  TimeStamp=$(date +"%Y/%m/%d_%H:%M:%S")

  echo "$TimeStamp"
}

dmsg_clr()
{
  #echo "clear debug message / events"
  dmesg -c > /dev/null 2>&1
  sleep 3&
  wait $!
}

dmesg_log()
{
  #$TestCount=$1, $now_time=$2, $SOC_UID=$3
  BLKERR="/tmp/${3}_eMMCblk_log.txt"
  blkmsg=$(dmesg | grep "$STR_BLKERR" | tail -1)
  cqerec=$(dmesg | grep "$STR_RUNRECOVER" | tail -1)

  if [ -n "$cqerec" ]; then
      cqeRes="Yes"
  else
      cqeRes="No"
  fi

  if [ -n "$blkmsg" ]; then
      echo "COUNT: ${1}, ${now_time}, CQE recover: ${cqeRes}, BLOCK_Error: ${blkmsg}" >> $BLKERR
  else
      echo "COUNT: ${1}, ${now_time}, CQE recover: ${cqeRes}, BLOCK_Error: None" >> $BLKERR
  fi
  sync
  sleep 2

}

GetCPUTemp()
{
  t=$(cat /sys/class/thermal/thermal_zone0/temp)
  CPU_TEMP=$(( t/1000 ))
  echo $CPU_TEMP
}

#get SOC unique ID
SOC_UID=$(cat /sys/devices/soc0/soc_uid)
#generate eMMC test log entity
TESTLOGFILE="${TESTLOGPATH}${SOC_UID}_eMMClog.txt"
touch $TESTLOGFILE
TestCount=0

while [ 1 ]; do
  #get current time
  now_time=$(GetTime)

  #get SOC temp
  CPUTEMP=$(GetCPUTemp)

  TestCount=$((TestCount+1))

  #Perform R/W test
  dmsg_clr
  echo "Fio Read/Write $BLKSIZE Test..."
  FIO_test $SDNAME $RWPARAM $BLKSIZE $WRATIO "$IODEPTH" "4" "Fio_Read_Write_Test_Rand_${BLKSIZE}_${IODEPTH}Q4T"

  #grap the read speed
  READBW=$(cat "$FIOTMP" | grep "READ" | cut -d ' ' -f6 | awk '{gsub(/\(|\)|,/,"");print}')
  WRITEBW=$(cat "$FIOTMP" | grep "WRITE" | cut -d ' ' -f5 | awk '{gsub(/\(|\)|,/,"");print}')

  # grap params of eMMC info
  MMCLOG="${TESTLOGPATH}eMMClog.txt"
  mmc extcsd read $SDNAME | grep -E "eMMC Life|Pre EOL" > $MMCLOG
  eMMCLTPYA=$(cat $MMCLOG | grep "Life Time Estimation A" | cut -d ':' -f 2 | awk '{gsub(/ /,"");print}')
  eMMCLTPYB=$(cat $MMCLOG | grep "Life Time Estimation B" | cut -d ':' -f 2 | awk '{gsub(/ /,"");print}')
  eMMCEOLINFO=$(cat $MMCLOG | grep "Pre EOL information" | cut -d ':' -f 2 | awk '{gsub(/ /,"");print}')

  #write test result
  #echo "${now_time}, CPU(DegC): ${CPUTEMP}, READ: ${READBW}, WRITE: ${WRITEBW}, MMCLIFE_A: ${eMMCLTPYA}, MMCLIFE_B: ${eMMCLTPYB}, MMC_EOL_INFO: ${eMMCEOLINFO}"
  echo "COUNT: ${TestCount}, ${now_time}, CPU(DegC): ${CPUTEMP}, READ: ${READBW}, WRITE: ${WRITEBW}, MMCLIFE_A: ${eMMCLTPYA}, MMCLIFE_B: ${eMMCLTPYB}, MMC_EOL_INFO: ${eMMCEOLINFO}" | tee -a $TESTLOGFILE
  sleep 0.5
  sync

  dmesg_log $TestCount $now_time $SOC_UID

done

