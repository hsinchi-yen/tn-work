<<'COMMENTS'
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Dump the system info. - Yocto ver/Kernel/cpu/mem/emmc size /emmc life for inspection
 OS_Platform       : Yocto 3.0, Yocto 2.5
 Script name       : SysInfo_view.sh
 Author            : lancey
 Date created      : 20201125
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20200926    lancey      1      Initial draft for test
 20200928    lancey      1      add soc info/temp/current freq/board info
 20201106    lancey      1      revise dump CPU clock message
 20201119    lancey      1      add MMCLOC variable for get mmc path from different SOM
 20201124    lancey      1      add WIFI_INTERFACE/WIFI_CHIP_TEMP reading from iwpriv command
 20210108    lancey      1      add SOC_UID
 20210127    lancey      1      add BT/WLAN/ETH MAC address
************************************************************************
COMMENTS
#!/bin/bash
DivderLine()
{
  #
  #$1 print symbol, #$2 loop time ,
  for (( i = 0; i < $2; i++ )); do
      echo -ne "${1}"
  done
  echo -ne "\n"
}

clear

#get eMMC location
MMCLOC=$(lsblk | grep mmcblk | awk 'FNR ==1 {print $1}')

echo "Image - OS - Kernel - Uboot Version Information "
DivderLine "-" 80
cat /etc/os-release
cat /proc/version
echo "----------U-boot---------------------------------"


# get the U-boot info.
dd if=/dev/$MMCLOC skip=32 bs=1k count=1200 2>/dev/null | strings | grep 'U-Boot' | head -2

#get the qty of SOC
CPUS=$(grep "processor" /proc/cpuinfo | wc -l)

#get the CPU current speed
CPU_CUR_CLK=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq | awk '{$1=$1/1000; print $1;}')

DivderLine "-" 80
# get the CPU current speed
printf "CPU Current Speed (MHz) : \t $CPU_CUR_CLK\n"

# get the current temperature of CPU
CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp|cut -c1-2)

#Display CPU temp / core and related info
printf "CPU current Temp.(DegC) : \t $CPU_TEMP\n"
echo "CPU core : $CPUS"
#lscpu | awk 'NR>=14 && NR<=15'

#Display CPU Cur/Max/Min Clock
CPU_CUR_CLK=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq)
CPU_MAX_CLK=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
CPU_MIN_CLK=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
echo "CPU Current clock : $CPU_CUR_CLK KHz"
echo "CPU Maximum clock : $CPU_MAX_CLK KHz"
echo "CPU Minimum clock : $CPU_MIN_CLK KHz"

#get the SOC ID , SOC version, Family
SOCFAMILY=$(cat /sys/devices/soc0/family)
echo "SOC FAMILY : $SOCFAMILY"
SOCREV=$(cat /sys/devices/soc0/revision)
echo "SOC_VERSION : $SOCREV"
SOCID=$(cat /sys/devices/soc0/soc_id)
echo "SOCID : $SOCID"
SOC_UID=$(cat /sys/devices/soc0/soc_uid)
echo "SOC_UID : $SOC_UID"


WIFI_CHIP_INFO=$(iwpriv wlan0 get_temp)
#WIFI_CHIP_INF=$(echo "$WIFI_CHIP_INFO" | cut -d ' ' -f 1)
WIFI_CHIP_TEMP=$(echo "$WIFI_CHIP_INFO" | cut -d ':' -f 2)
DivderLine "-" 80
#echo "WIFI INTERFACE : $WIFI_CHIP_INF"
echo "WIFI CHIP Temp.(DegC) : $WIFI_CHIP_TEMP"
DivderLine "-" 80

ETHINF=$(ifconfig eth0 | grep HWaddr | cut -d ' ' -f1)
ETHADDR=$(ifconfig eth0 | grep HWaddr | cut -d ' ' -f11)

WIFIINF=$(ifconfig wlan0 | grep HWaddr | cut -d ' ' -f1)
WIFIADDR=$(ifconfig wlan0 | grep HWaddr | cut -d ' ' -f10)

BT_INF=$(hciconfig -a | grep hci | cut -d ':' -f1)
BT_ADDR=$(hciconfig -a | grep "BD Address:" | cut -d ' ' -f3)

echo  -e "Ethernet Interface : \t$ETHINF, \tMAC address : \t$ETHADDR"
echo  -e "WIFI Interface : \t$WIFIINF, \tMAC address : \t$WIFIADDR"
echo  -e "Bluetooth Interface : \t$BT_INF, \tMAC address : \t$BT_ADDR"

#Get the Board Info
BOARDINFO=$(cat /sys/devices/soc0/machine)
#MODEL_ID=$(cat /proc/device-tree/model)
DivderLine "-" 80
echo "BOARD INFO. 1: $BOARDINFO"
#echo "BOARD INFO. 2: $MODEL_ID"

#get memory size and conver it to MB unit
MEMSIZE=$(cat /proc/meminfo | grep MemTotal | awk '{$2=$2/1000; print $2,"Mb";}')
echo "Memory Size : $MEMSIZE"

#get the eMMC storage size
eMMCSIZE=$(fdisk -l | grep Disk | awk -F ',' 'FNR == 1 {print $1}' | cut -d ' ' -f 3,4)
echo "eMMC Size : $eMMCSIZE"

#get eMMC location
#MMCLOC=$(lsblk | grep mmcblk | awk 'FNR ==1 {print $1}')

echo ""
echo "---------------eMMC Life Information-------------"
mmc extcsd read /dev/$MMCLOC | grep "eMMC Life"
mmc extcsd read /dev/$MMCLOC | grep "eMMC Pre EOL"
