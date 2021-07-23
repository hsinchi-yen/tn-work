<<'COMMENTS'
************************************************************************
 Purpose           : For verified Ethernet 10/100/1000Mbps, LED indicators, Ipv4/6 throughput performance
 Script name       : ETH_Test_Suite.sh
 Author            : lancey
 Date created      : 20201118
----------------------------------------------------------------------- 
 Revision History  : 0.1
 Date        Author      Ref    Revision (Date in YYYYMMDD format) 
-----------------------------------------------------------------------
 20201117    lancey      0      initial draft for Ethernet function verification test
************************************************************************
COMMENTS
#!/bin/bash

#Pre define test parameter
TEST_DNS="www.google.com.tw"
ETH_INF="eth0"
IPERF_SERV="10.88.88.147"
#IPERF_SERV="10.88.88.203"
#IPERF_SERV="10.88.88.167"

IPERF_PORT="5201"
#iperf test time
IPERF_TESTTIME=10

#IP-10.88.88.147
#IPV6_PING_SERV="fd78:42c6:7e0a:1:f11d:5b15:b564:8ad0"
IPV6_PING_SERV="fd78:42c6:7e0a:1:fbfb:d02c:718a:92a0"

#IP-10.88.88.203
#IPV6_PING_SERV="fd78:42c6:7e0a:1:b0eb:e07a:42ca:3fcd"
#IPV6_PING_SERV="fd78:42c6:7e0a:1:4bb9:e60:96bc:51d0"

clear
rm -rf /tmp/*
sync

# Ethernet Interface UP/DOWN TEST
echo "$ETH_INF is set to DOWN"
ifconfig $ETH_INF down
sleep 3&
wait $!
ifconfig $ETH_INF
sleep 1&
wait $!
ping -c 3 $TEST_DNS

echo "$ETH_INF is set to UP"
ifconfig $ETH_INF up
sleep 5&
wait $!
sleep 1

ifconfig $ETH_INF
sleep 1&
wait $!
#ping -c 3 $TEST_DNS


# Ipv4 ping test
echo "IPv4 Ping Test..."
echo ""
ping -c 5 $TEST_DNS | tee /tmp/IPV4_PINGLOG.txt
sleep 5 &
wait $!

# Ipv6 ping test
echo "IPv6 Ping Test..."
echo ""
ping -6 -c 5 $IPV6_PING_SERV | tee /tmp/IPV6_PINGLOG.txt
sleep 5 &
wait $!

sleep 1
#Test 100Mbps
echo "Ethernet Test Start ...."
echo ""
sleep 1
echo "================================================"
echo "Set Eth to 100M mode and flashing LED indicators"
echo "================================================"
echo ""

ethtool -s $ETH_INF speed 100 duplex full
sleep 3&
wait $!
iperf3 -c $IPERF_SERV -i 2 -t 10 -p $IPERF_PORT > /tmp/Eth_100Mb_Test.txt &
sleep 15&
wait $!

#Test 10Mbps
echo "================================================"
echo "Set Eth to 10M mode and flashing LED indicators "
echo "================================================"
echo ""

ethtool -s $ETH_INF speed 10 duplex full
sleep 3&
wait $!
iperf3 -c $IPERF_SERV -i 2 -t 10 -p $IPERF_PORT > /tmp/Eth_10Mb_Test.txt &
sleep 15&
wait $!

#Test 1000Mbps
echo "================================================"
echo "Set Eth to 1G mode and flashing LED indicators  "
echo "================================================"
echo ""

ethtool -s $ETH_INF speed 1000 duplex full
sleep 3&
wait $!
iperf3 -c $IPERF_SERV -i 2 -t 10 -p $IPERF_PORT > /tmp/Eth_1000Mb_Test.txt &
sleep 15&
wait $!

#Throughput Performance Test for 30 seconds
echo "================================================"
echo "IPV4 : Throughput Performance Test ...          "
echo "================================================"

iperf3 -c $IPERF_SERV -i 2 -t $IPERF_TESTTIME -p $IPERF_PORT | tee /tmp/Eth_IPv4_TP_Test.txt
sleep 1&
wait $!
sync
echo "================================================"
echo "IPV6 : Throughput Performance Test ...          "
echo "================================================"
iperf3 -6 -c $IPV6_PING_SERV -i 2 -t $IPERF_TESTTIME -p $IPERF_PORT | tee /tmp/Eth_IPv6_TP_Test.txt
sleep 1&
wait $!
sync

echo "Ethernet Test is completed, please check log file in /tmp/"
ls -l /tmp/
