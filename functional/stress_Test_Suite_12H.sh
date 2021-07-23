<<'COMMENTS'
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : 12 hours stress test for CPU / MEM / WLAN / GPU / VPU
                     stress-ng, stressapptest, iperf3
 OS_Platform       : Yocto 3.0, Yocto 2.5
 Script name       : stress_Test_Suite_12H.sh
 Author            : lancey
 Date created      : 20210930
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20200930    lancey      1      Initial draft for test
 20210302    lancey      2      Modify for each case could count the estimated times for 12 hours (43200)
************************************************************************
COMMENTS
#!/bin/bash

#Get Date and Time
GetTime()
{
  rtime=$(date +"%Y-%m-%d %H:%M:%S")
  echo $rtime
}

#Get System seconds
GetCurSecond()
{
  rseconds=$(date +%s)
  echo $rseconds
}

secs_to_human() {
    if [[ -z ${1} || ${1} -lt 60 ]] ;then
        min=0 ; secs="${1}"
    else
        time_mins=$(echo "scale=2; ${1}/60" | bc)
        min=$(echo ${time_mins} | cut -d'.' -f1)
        secs="0.$(echo ${time_mins} | cut -d'.' -f2)"
        secs=$(echo ${secs}*60|bc|awk '{print int($1+0.5)}')
    fi
    echo "Time Elapsed : ${min} minutes and ${secs} seconds."
}

cpu_stress_test(){
  #$CPUS = $1
  echo "CPU stress-ng Test"
  stress-ng -c $1 -t 3600 -v --metrics-brief
  sleep 1
}
#Total Test Time
T_time=43200

#PreConfig CASES setting --- Start
CPU_STRESSOR=1

#memtester
MEM_STRESSOR_3=1
#stressapptest
MEM_STRESSOR=1
#stress-ng
MEM_STRESSOR_2=1

GPU_STRESSOR=1
VPU_STRESSOR=1

#Iperf test cases
#----------------------------------------------
# Uni direction - Upload (TX)
IPERF_STRESSOR_0=0
# Uni direction - Download (RX)
IPERF_STRESSOR_1=0
# Bi Direction - (TX/RX)
IPERF_STRESSOR_2=0
# iperf3 - Message display interval
IPERF_PARM_INFO_INTERVAL=10
# iperf3 - length of Test time (in Seconds)
IPERF_PARM_TESTTIME=600
#Iperf server address
SERV_IP="10.88.88.147"
#----------------------------------------------

#PreConfig CASES setting --- End

# Check CPU processors
CPUS=$(grep "processor" /proc/cpuinfo | wc -l)

# grab 70% of the real available memory
fMEMS=$(free -m | grep Mem: | awk '{print $4}')
tMEMS=$(expr $fMEMS*0.7 | bc | grep -Eo '[0-9]{1,4}[^.]')

#Video Clip time is 3:31 , 211 seconds
VIDEOsrc="/opt/ApinkDumh.mp4"


if [ $CPU_STRESSOR -eq 1 ]; then
  uptime
  #CPU stress test for 12 hours
  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    GetTime
    cpu_stress_test $CPUS
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done

fi

if [ $MEM_STRESSOR_3 -eq 1 ]; then
#Memory stress Test - memtester for 12 hours
  uptime
  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    echo "Memory stress test - memtester"
    GetTime
    memtester $tMEMS 1 | tee /home/root/memtester_log.txt
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done

fi

if [ $MEM_STRESSOR -eq 1 ]; then
#Memory stress Test for 12 hours
  uptime
  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    echo "Memory stress test"
    GetTime
    stressapptest -s 600 -M $tMEMS -c
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done
fi

if [ $MEM_STRESSOR_2 -eq 1 ]; then
#Memory stress Test for 12 hours
  uptime

  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    echo "Memory stress-ng test"
    GetTime
    stress-ng --brk 2 --stack 2 --bigheap 2 -t 600 --metrics-brief
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done
fi

# Uni direction - Upload (TX)
if [ $IPERF_STRESSOR_0 -eq 1 ]; then
  uptime
  #Iperf stress Test for 12 hours
  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    echo "iperf3 test -Uni direction - Upload (TX)"
    GetTime
    iperf3 -c $SERV_IP -i $IPERF_PARM_INFO_INTERVAL -t $IPERF_PARM_TESTTIME
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done
fi

# Uni direction - Download (RX)
if [ $IPERF_STRESSOR_1 -eq 1 ]; then
  uptime
  #Iperf stress Test for 12 hours - RX
  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    echo "iperf3 test - Uni direction - Download (RX)"
    GetTime
    iperf3 -c $SERV_IP -i $IPERF_PARM_INFO_INTERVAL -t $IPERF_PARM_TESTTIME -R
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done
fi

# Bi-Direction - (TX/RX)
if [ $IPERF_STRESSOR_2 -eq 1 ]; then
  uptime
#Iperf stress Test for 12 hours - TX/RX
  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    echo "iperf3 test - Bi-Direction - (TX/RX)"
    GetTime
    iperf3 -c $SERV_IP -i $IPERF_PARM_INFO_INTERVAL -t $IPERF_PARM_TESTTIME -bidir
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done
fi

if [ $GPU_STRESSOR -eq 1 ]; then
# 129 cycle test for 12 hours
# glmark test time 5:36 , 336 seconds
  uptime
  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    echo "GPU burning Test for 12 hours"
    GetTime
    glmark2-es2-wayland --fullscreen --annotate
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done
  uptime
fi

if [ $VPU_STRESSOR -eq 1 ]; then
# 205 cycle test for 12 hours
# video clip length  3:31 , 211 seconds
  uptime
  startsecs=$(GetCurSecond)
  timediff=0
  while [ $timediff -lt $T_time ]; do
    echo "VPU burning Test for 12 hours"
    GetTime
    gst-launch-1.0 playbin uri=file://$VIDEOsrc video-sink=autovideosink
    finalsecs=$(GetCurSecond)
    timediff=$(($finalsecs-$startsecs))
    secs_to_human $timediff
  done
  #echo "VPU burning Test for 12 hours"
  #for (( i = 1; i <=205 ; i++ )); do
    #gst-launch-1.0 playbin uri=file://$VIDEOsrc video-sink=autovideosink
    #sleep 1
  #done
  uptime
fi
uptime