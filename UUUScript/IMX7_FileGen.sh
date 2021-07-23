#!/bin/bash

#Flash Source define
#=======================================================================
EMMCIMAGE="pico-imx7_xxxx.img"
FLASHCODE="imx7_flash_code.sh"
FLASHCODE_TERMEMU="imx7_emu_flash_code.sh"


#Define imx7 params
#imx7
SOCNAME="imx7"

#Define BoardType
#edm-imx7, tep1-imx7, pico-imx7
BOARDTYPE="pico-imx7"
#=======================================================================

#EMMCSCRIPT for imx7 series:
#emmc_imx7_img
EMMCSCRIPT="emmc_imx7_img"

#BOARDTYPE_tail="-flash.bin"

SPL="-SPL"
UBOOT="-u-boot.img"

#Define imx mfg uuu tool source path

UUU="uuu_flash"
IMX_UUU_TOOL="/Desktop/imx-mfg-uuu-tool"
UUU_DST="/uuu/linux64/uuu"

TERM_EMU="xfce4-terminal -H -e"

SPLNAME=""
UBOOTNAME=""

if [ -L $UUU ]
then
    rm -rf ./$UUU
fi

if [ -f $FLASHCODE ]
then
    rm -rf ./$FLASHCODE
fi

PWD="$(echo ~)"

#define spl uboot file name
SPLNAME="${SOCNAME}${SPL}"
UBOOTNAME="${SOCNAME}${UBOOT}"

#make uuu_file symbolink
ln -s "$PWD$IMX_UUU_TOOL$UUU_DST" "$UUU"

cat <<EOF >>$FLASHCODE
#!/bin/bash

EMMCSCRIPT=$EMMCSCRIPT
IMX_UUU_TOOL=$PWD$IMX_UUU_TOOL
SOCNAME=$SOCNAME
SPLNAME=$SPLNAME
UBOOTNAME=$UBOOTNAME
EMMCIMAGE=$EMMCIMAGE

echo "Script description :"
echo "$UUU -d -b $EMMCSCRIPT $PWD$IMX_UUU_TOOL/$SOCNAME/$BOARDTYPE/$SPLNAME $PWD$IMX_UUU_TOOL/$SOCNAME/$BOARDTYPE/$UBOOTNAME $EMMCIMAGE"
echo
echo "command perform ..."
echo 
sudo ./$UUU -d -b $EMMCSCRIPT $PWD$IMX_UUU_TOOL/$SOCNAME/$BOARDTYPE/$SPLNAME $PWD$IMX_UUU_TOOL/$SOCNAME/$BOARDTYPE/$UBOOTNAME $EMMCIMAGE
EOF

#Create Terminal shortcut with xfce4-terminal

cat <<EOF >>$FLASHCODE_TERMEMU
#!/bin/bash

$TERM_EMU ./$FLASHCODE

EOF

sudo chmod +x $FLASHCODE
sudo chmod +x $FLASHCODE_TERMEMU

sync
sleep 1
sudo chmod +x $FLASHCODE

echo "done !"

