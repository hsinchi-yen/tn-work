<<'COMMENTS'
************************************************************************
 Purpose           : Test Script for performs a simple scan and connection test for 4G networks on yocto 2.5
 Script name       : GSM007_Test.sh
 Author            : lancey
 Date created      : 20210105
 Purpose           : Verify LTE (mPCIE/M2) functionality - test procedure refer to koduwiki of technexion - GSM007.
 Test Scenario ref : http://10.20.30.20/dokuwiki/doku.php?id=test_procedures:gsm007
 Verified Platform : iMX8, Yocto 2.5
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20210107    lancey      1      Initial draft
************************************************************************
COMMENTS

#!/bin/bash

# Dinfine related GSM command Variables

COMM_LTE_NAME="wwan0"
IS_INF_LTE=$(ifconfig $COMM_LTE_NAME)
# check the LTE Module status
STATUS_CHK="/usr/lib/ofono/test/list-modems"
# config APN
APNCONFIGSET="/usr/lib/ofono/test/create-internet-context internet"
# check APN
APNCONFIGCHK="/usr/lib/ofono/test/list-contexts | grep AccessPointName"

LTE_MODULE_INFO=$($STATUS_CHK | grep -E "Manufacturer|Model" | cut -d '=' -f2 | awk '{gsub(/\ /,"");print}')
# grab the interface name and trim unwanted characters
MODEM_INF=$($STATUS_CHK | grep -E "\[ \/\w+\ \]" | awk '{gsub(/\ |\[|\]/,"");print}')

# Special command for Huawei EM770W / sierra
HUAWEI_INF="/huawei_0"
HUAWEI_EM770W_CMD=/usr/lib/ofono/test/test-network-registration
SIERRA_INF="/sierra_0"
PPPOE_INF="ppp0"

# launch a wwan connection
PREFIX_ENABLE_MODEM=/usr/lib/ofono/test/online-modem
MODEMACTIVATION=/usr/lib/ofono/test/activate-context
LTE_LOGFILE=/tmp/LTE_STATUS_LOG.txt

# TEST DNS
GOOGLEDNS="www.google.com.tw"
GOOOGLEDNSIP="8.8.8.8"
# PING checking Times
PINGTIMES="3"

#PPPOE error fetch
PPPOEERRMSG="ppp0: error fetching interface information: Device not found"

#SIM card inserted INFO
SIMACTKEY="\[ org.ofono.AllowedAccessPoints \]"

isPingchk()
{
  if (route | grep -q UG); then
    ping $GOOGLEDNS -c $PINGTIMES | tee /tmp/pinglog.txt
    sleep 1
    sync
    sleep 2
  else
    ping $GOOOGLEDNSIP -c $PINGTIMES | tee /tmp/pinglog.txt
    sleep 1
    sync
    sleep 2
  fi

  pktmsg=$(cat /tmp/pinglog.txt | grep packet)
  TX_pkg=$(echo $pktmsg | cut -d " " -f1)
  RX_pkg=$(echo $pktmsg | cut -d " " -f4)
  echo
  echo "========================================="
  echo "*          TX Packets: $TX_pkg                *"
  echo "*          RX Packets: $RX_pkg                *"
  echo "========================================="
  echo
  sleep 1&
  wait $!

  if [ -z $TX_pkg ]; then
      TX_pkg=0
  fi

  if [ -z $RX_pkg ]; then
      RX_pkg=0
  fi

  if [ $TX_pkg -gt 0 -a $RX_pkg -gt 0 ]; then
    echo
    echo "Ping Success"
    return 0
  else
    echo
    echo "Ping Fail"
    return 1
  fi
}

Disable_OtherNetwork_INF() {

  NETDEVS=$(ifconfig -a | grep -E "wlan|eth" | cut -d " " -f1)
  echo
  for NETDEV in $NETDEVS; do
      echo "Interface $NETDEV down"
      ifconfig $NETDEV down
      sleep 1&
      wait $!
  done
  sleep 1&
  wait $!
  echo
  echo "Other Network connection interfaces are DOWN"
  echo

  ifconfig $COMM_LTE_NAME up
  sleep 1
}

Enable_OtherNetwork_INF() {

  NETDEVS=$(ifconfig -a | grep -E "wlan|eth" | cut -d " " -f1)

  for NETDEV in $NETDEVS; do
      echo "Interface $NETDEV up"
      ifconfig $NETDEV up
      sleep 1&
      wait $!
  done
  echo
  echo "Other Network connection interfaces are UP"
  echo

}

SIM_DETECTION() {
  #echo $SIMACTKEY
  sleep 1
  isSIM=$($STATUS_CHK | grep -E "$SIMACTKEY" |  awk '{gsub(/^\ +|\ +$/,"");print}')
  if [[ $isSIM == $SIMACTKEY ]]; then
      #echo "isSIM = $isSIM"
      return 0
  else
      #echo "isSIM = $isSIM"
      return 1
  fi
}

LTE_CONNECTION_SET() {
  $STATUS_CHK | tee $LTE_LOGFILE
  sync
  sleep 1&
  wait $!

  LTE_MODULE_INFO=$(cat $LTE_LOGFILE | grep -E "Manufacturer|Model" | cut -d '=' -f2 | awk '{gsub(/\ /,"");print}')

  if [[ -z $LTE_MODULE_INFO ]]; then
      sleep 1
      LTE_MODULE_INFO="None"
  fi

  # grab the interface name and trim unwanted characters
  MODEM_INF=$($STATUS_CHK | grep -E "\[ \/\w+\ \]" | awk '{gsub(/\ |\[|\]/,"");print}')

  if [ $MODEM_INF != $SIERRA_INF ]; then
     $APNCONFIGSET
     sleep 1
  fi

  $APNCONFIGCHK
  sleep 1

  #enable MODEM
  $PREFIX_ENABLE_MODEM $MODEM_INF
  sleep 5&
  wait $!

  #issue a modem connection
  $MODEMACTIVATION
  sleep 10&
  wait $!
}

clear
echo "LTE Module Test is starting ..."
echo
sleep 1

#check if the $COMM_LTE_NAME IP is existed"
if [[ ! -z $IS_INF_LTE ]]; then
    echo
    echo "LTE module is attached"
    echo
    sleep 1&
    wait $!


    #check if SIMCARD is inserted
    SIM_DETECTION
    isSIM=$?

    if [[ $isSIM -eq 1 ]]; then

        echo
        echo "SIM CARD is not available"
        echo

        sleep 1
    else

        echo
        echo "SIM CARD is Detected"
        echo
        sleep 1

      #start test if wwan , sim are available

      # check if it's huawel module
      if [[ $MODEM_INF == $HUAWEI_INF ]]; then

        if [[ $(ifconfig $PPPOE_INF | grep "inet addr") == "" ]]; then
           echo "PPPOE,$MODEM_INF"
           LTE_CONNECTION_SET
        else
          echo "$COMM_LTE_NAME Interface is already UP !"
          echo
          sleep 1&
          wait $!


          if [[ -z $LTE_MODULE_INFO ]]; then
            sleep 1
            LTE_MODULE_INFO="Not Available"
          fi
          sleep 1
        fi

      else

        if [[ -z $(ifconfig $COMM_LTE_NAME | grep "inet addr") ]]; then
          echo "WWAN0,$MODEM_INF"
          LTE_CONNECTION_SET
        else
          echo "$COMM_LTE_NAME Interface is already UP !"
          sleep 1&

          if [[ -z $LTE_MODULE_INFO ]]; then
            sleep 1
            LTE_MODULE_INFO="Not Available"
          fi

          wait $!
        fi

      fi

      Disable_OtherNetwork_INF

      echo "Show $COMM_LTE_NAME IP INFO"
      echo "============================================================"

      if [[ $MODEM_INF == $HUAWEI_INF ]]; then
        ifconfig $PPPOE_INF
      fi

      ifconfig $COMM_LTE_NAME
      sleep 1&
      wait $!

      isPingchk
      PingResult=$?

      #echo $PingResult
      if [ ! $PingResult -eq 0 ]; then
        echo
        echo "LTE Module INFO "
        echo "================================="
        echo "$LTE_MODULE_INFO"
        echo
        echo "*** LTE Module [wwan0] TEST : FAIL"
        echo "Please check if there is somethong wrong with LTE module / cable / Attenna / SIM etc,. ***"
        echo
        sleep 2&
        wait $!
      else
        echo
        echo "LTE Module INFO"
        echo "================================="
        echo "$LTE_MODULE_INFO"
        echo
        echo "*** LTE Module [wwan0] TEST : PASS ***"
        echo
        sleep 2&
        wait $!
      fi

      Enable_OtherNetwork_INF
      sleep 2&
      wait $!

      echo
      echo "LTE module Test is complete !!!"
      echo
    fi

else
    echo
    echo "LTE module is not attached, please check ..."
    echo
    sleep 2&
    wait $!
fi