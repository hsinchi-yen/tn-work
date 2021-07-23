#!/bin/bash

#Flash Source define
#======================================================================
EMMCIMAGE="pico-imx6_pico-nymph_rescue#134_hdmi_20210312.img"
FLASHCODE="imx6_flash_code.sh"
FLASHCODE_TERMEMU="imx6_emu_flash_code.sh"

#EMMCSCRIPT for imx6 series:
#emmc_imx6_img , emmc_imx6ul_img
EMMCSCRIPT="emmc_imx6_img"

#Define imx6 params
#imx6, imx6ul
SOCNAME="imx6"

#Define BoardType
#axon-imx6, edm-imx6, pico-imx6, tek-imx6
BOARDTYPE="pico-imx6"
#======================================================================

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
echo "done !"

