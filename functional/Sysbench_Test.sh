<<'COMMENTS'
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Run the Sysbench test set for CPU/MEM/DISK
 Script name       : Sysbench_Test.sh
 Author            : lancey
 Date created      : 20200924
 -----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format) 
-----------------------------------------------------------------------
 20200924    lancey      1      Initial draft for test
************************************************************************
COMMENTS
#!/bin/bash

# Check CPU processors
CPUS=$(grep "processor" /proc/cpuinfo | wc -l)

clear
sleep 1
echo "***** Sysbench Test Start *****"
echo "***** CPU Benchmark"

#echo $CPUS
sysbench --test=cpu --cpu-max-prime=100000 run | tee /tmp/sysbench_cpu.txt
sleep 1&
wait $!

echo "***** Sysbench Test Start *****"
echo "***** CPU Benchmark - MultiCore:$CPUS"
sysbench --test=cpu --num-threads=$CPUS --cpu-max-prime=100000 run | tee /tmp/sysbench_cpus.txt
sleep 1&
wait $!

echo "***** Sysbench Test Start *****"
echo "***** Memory Benchmark"
sysbench --test=memory --memory-block-size=8K --memory-total-size=100G  --num-threads=$CPUS run | tee /tmp/sysbench_mem.txt
sleep 1&
wait $!

echo "***** Sysbench Test Start *****"
echo "***** eMMC Benchmark - prepare"
sysbench --test=fileio --num-threads=4 --file-total-size=1G --file-test-mode=rndrw prepare
sleep 1&
wait $!
sync

echo "***** eMMC Benchmark Test"
sysbench --test=fileio --num-threads=4 --file-total-size=1G --file-test-mode=rndrw run | tee /tmp/sysbench_eMMC.txt
sleep 1&
wait $!
sync

echo "***** eMMC Benchmark Test"
sysbench --test=fileio --num-threads=4 --file-total-size=1G --file-test-mode=rndrw cleanup
sleep 1&
wait $!
sync

echo "View result for following files"
ls -l /tmp/*.txt

echo "Test Done!"