<<'COMMENTS'
************************************************************************
 Script name       : IO_stress.sh
 Author            : lancey
 Date created      : 20201211
 Purpose           : for quick execute stress-ng for IO stress test
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20201211   lancey      1      Initial draft
 20201214   lancey      1      modified for fine tuen sequence
************************************************************************
COMMENTS
#!/bin/bash

CPUSTRESSOR()
{
  CPUQTY=$1
  case $CPUQTY in
  4)
      taskset 0x1 stress-ng --cpu $CPUQTY --io 1 &
      taskset 0x2 stress-ng --cpu $CPUQTY --io 1 &
      taskset 0x4 stress-ng --cpu $CPUQTY --io 1 &
      taskset 0x8 stress-ng --cpu $CPUQTY --io 1 &
  ;;
  2)
      taskset 0x1 stress-ng --cpu $CPUQTY --io 1 &
      taskset 0x2 stress-ng --cpu $CPUQTY --io 1 &
  ;;
  1)
      taskset 0x1 stress-ng --cpu $CPUQTY --io 1 &
  ;;
esac

echo "Commands are executed in Background ... "
sleep 10

}

#get the qty of SOC
CPUS=$(grep "processor" /proc/cpuinfo | wc -l)

echo "check if stress-ng available "
isStressor=$(find / -iname stress-ng)

if [ -z "$isStressor" ]; then
      echo "stress-ng is not available"
      
else
      echo "Running the stress-ng for IO ..."
      CPUSTRESSOR $CPUS
      top
fi


