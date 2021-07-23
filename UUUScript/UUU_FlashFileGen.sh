: '
************************************************************************
 Purpose           : For Quick Generate hands-on uuu flash script
 Script name       : UUU_FlashFileGen.sh
 Author            : lancey
 Date created      : 20210514
-----------------------------------------------------------------------
 Revision History  : 1.0
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20210514   lancey      0      initial draft for PD test purpose for all imx6,imx7,imx8 series
 20210519	lancey		1	   change the SOMID/SOCID arrays sequence
************************************************************************
'
imx8_flash_script_gen()
{
  cat <<EOF >>$1
  #!/bin/bash

  echo "Script description :"
  echo "$UUU -d -b $EMMCSCRIPT $BINFILE $EMMCIMAGE"
  echo
  echo "command executing ..."
  echo
  sudo ./$UUU -d -b $EMMCSCRIPT $BINFILE $EMMCIMAGE
EOF

sudo chmod +x $1
}

imx6_7_flash_script_gen()
{
  cat <<EOF >>$1
  #!/bin/bash

  echo "Script description :"
  echo "$UUU -d -b $EMMCSCRIPT $SPLFILE $UBOOTFILE $EMMCIMAGE"
  echo
  echo "command executing ..."
  echo
  sudo ./$UUU -d -b $EMMCSCRIPT $SPLFILE $UBOOTFILE $EMMCIMAGE
EOF

sudo chmod +x $1
}

Term_emu_script_gen()
{
  TERM_EMU="xfce4-terminal -H -e"
  #Create Terminal shortcut with xfce4-terminal
  cat <<EOF >>$1
  #!/bin/bash
  #launch a xfce4-terminal utility with script
  $TERM_EMU ./$FLASHCODE
EOF

sudo chmod +x $1
}

#the sub function for determining the soc name
SOCNameFinder()
{
  #$1 is the filename
  Img=$1
  SOC_ARR=(imx8mm imx8mn imx8mq imx8mp imx7 imx6ul imx6)

  for SOC in "${SOC_ARR[@]}"; do
    echo "$Img" | grep "$SOC" > /dev/null 2>&1
    Result=$?
    if [[ "$Result" -eq 0 ]]; then
        echo $SOC
        break
    else
        continue
    fi
  done

}
#the sub function for determining the som name
SOMNameFinder()
{
  #$1 is the filename
  Img=$1
  SOM_ARR=(\
   "axon-imx8mm" "edm-g-imx8mm" "flex-imx8mm" "pico-imx8mm" "xore-imx8mm" \
   "axon-imx8mp" "edm-g-imx8mp" \
   "edm-imx8mq" "pico-imx8mq" \
   "edm-g-imx8mn" \
   "edm-imx7" "tep1-imx7" "pico-imx7" \
   "pico-imx6ul" "tek-imx6ul" "tep-imx6ul" \
   "axon-imx6" "edm-imx6" "pico-imx6" "tek-imx6")

  #imx8mm: axon-imx8mm, edm-g-imx8mm, flex-imx8mm, pico-imx8mm, xore-imx8mm
  #imx8mp: axon-imx8mp, edm-g-imx8mp
  #imx8mq: edm-imx8mq, pico-imx8mq
  #imx8mn: edm-g-imx8mn
  #imx7:edm-imx7, tep1-imx7, pico-imx7
  #imx6:axon-imx6, edm-imx6, pico-imx6, tek-imx6
  #imx6ul:pico-imx6ul, tek-imx6ul, tep-imx6ul

  for SOM in "${SOM_ARR[@]}"; do
    echo "$Img" | grep "$SOM" > /dev/null 2>&1
    Result=$?
    if [[ "$Result" -eq 0 ]]; then
        echo $SOM
        break
    else
        continue
    fi
  done

}

Progressbar()
{
  BAR='[######################################]'   # this is full bar, e.g. 42 chars
  echo "Compiling : "
  for i in {1..42}; do
    echo -ne "\r${BAR:0:$i}" # print $i chars of $BAR from 0 position
    sleep .01                 # wait 100ms between "frames"
  done
  echo -ne " Done !"
  echo 
}

#EMMCIMAGE="tek-imx6_pico-nymph_rescue#134_hdmi_20210312.img"
#FLASHCODE="imx8_flash_code.sh"

#Flash EMMC script post-fixed word.

#================ common path definition Start======================
UUU="uuu_flash"
IMX_UUU_TOOL="/Desktop/imx-mfg-uuu-tool"
UUU_DST="/uuu/linux64/uuu"
#================ common path definition End =======================

#for imx8 series - bin file tail word
BOARDTYPE_Tail="-flash.bin"

#for imx6 / imx7 series spl and uboot tail word
SPL="-SPL"
UBOOT="-u-boot.img"

#declar 3 variables for binfile, splfile, ubootfile
BINFILE=""
SPLFILE=""
UBOOTFILE=""

if [ "$1" != "" ]; then
    EMMCIMAGE=$1
else
    EMMCIMAGE="noname.img"
fi

if [ "$2" != "" ]; then
    FLASHCODE=$2
else
    FLASHCODE="noname.sh"
fi

FLASHCODE_TERMEMU=$3

if [ -L $UUU ]
then
    rm -rf ./$UUU
fi

if [ -f $FLASHCODE ]
then
    rm -rf ./$FLASHCODE
fi

#Obtain the Present owner Directory
PWD="$(echo ~)"
#make uuu_file symbolink to uuu file
ln -s "$PWD$IMX_UUU_TOOL$UUU_DST" "$UUU"
#check Image name for finding the SOCID
SOCID=$(SOCNameFinder $EMMCIMAGE)
#check Image name for finding the SOMID
SOMID=$(SOMNameFinder $EMMCIMAGE)

#Use SOCID decide the uuu flash script type - phrase 1
case $SOCID in
  imx8mm|imx8mp|imx8mn|imx8mq)
    EMMCSCRIPT="emmc_img"
    ;;
  imx6)
    EMMCSCRIPT="emmc_imx6_img"
    ;;
  imx6ul)
    EMMCSCRIPT="emmc_imx6ul_img"
    ;;
  imx7)
    EMMCSCRIPT="emmc_imx7_img"
    ;;
esac

#Use SOCID decide the uuu flash script type - phrase 2
case $SOCID in
  imx8mm|imx8mp|imx8mn|imx8mq)
    BINFILE=$PWD$IMX_UUU_TOOL/$SOCID/$SOMID/$SOMID$BOARDTYPE_Tail
    ;;
  imx6|imx6ul|imx7)
    SPLFILE=$PWD$IMX_UUU_TOOL/$SOCID/$SOMID/$SOCID$SPL
    UBOOTFILE=$PWD$IMX_UUU_TOOL/$SOCID/$SOMID/$SOCID$UBOOT
    ;;
esac

# Generate uuu flash script

if [ "$BINFILE" != "" ]; then
    # if it's imx8 soc use following script
    imx8_flash_script_gen $FLASHCODE
else
    # if it's imx6/7 soc use following script
    imx6_7_flash_script_gen $FLASHCODE
fi

if [ "$FLASHCODE_TERMEMU" == "" ]; then
  Term_emu_script_gen "emu_$FLASHCODE"
else
  Term_emu_script_gen "$FLASHCODE_TERMEMU"
fi

sync
Progressbar

echo
echo "Script - $FLASHCODE Is Generated Succefully."
echo

if [ ! -f $1 ]
then
  echo "Assigned image file is not existed, please check filename."
  echo
fi

if [ "$2" == "" ]
then
  echo "The Flashcode script name is not assigned."
  echo

  echo "command usage :"
  echo "$0 Image_Name Script_Name"
fi

