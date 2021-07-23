#!/bin/bash

#Flash Source define
#=================================================================================
EMMCIMAGE="edm-g-imx8mp_edm-g-wb_rescue#13_20210421.img"
FLASHCODE="imx8_flash_code.sh"
FLASHCODE_TERMEMU="imx8_emu_flash_code.sh"

#Define imx8 params
#imx8mm, imx8mp, imx8mp
SOCNAME="imx8mp"

#Define BoardType
#imx8mm: axon-imx8mm, edm-g-imx8mm, flex-imx8mm, pico-imx8mm, xore-imx8mm
#imx8mp: axon-imx8mp, edm-g-imx8mp
#imx8mq: edm-imx8mq, pico-imx8mq
#imx8mn: edm-g-imx8mn

BOARDTYPE="edm-g-imx8mp"
#================================================================================

#EMMCSCRIPT for imx8 series
EMMCSCRIPT="emmc_img"
BOARDTYPE_tail="-flash.bin"

#Define imx mfg uuu tool source path

UUU="uuu_flash"
IMX_UUU_TOOL="/Desktop/imx-mfg-uuu-tool"
UUU_DST="/uuu/linux64/uuu"

TERM_EMU="xfce4-terminal -H -e"

if [ -L $UUU ]
then
    rm -rf ./$UUU
fi

if [ -f $FLASHCODE ]
then
    rm -rf ./$FLASHCODE
fi

PWD="$(echo ~)"

#make uuu_file symbolink
ln -s "$PWD$IMX_UUU_TOOL$UUU_DST" "$UUU"

cat <<EOF >>$FLASHCODE
#!/bin/bash

EMMCSCRIPT=$EMMCSCRIPT 
IMX_UUU_TOOL=$IMX_UUU_TOOL
SOCNAME=$SOCNAME
BOARDTYPE=$BOARDTYPE
BOARDTYPE_tail=$BOARDTYPE_tail 
EMMCIMAGE=$EMMCIMAGE

echo "Script description :"
echo "$UUU -d -b $EMMCSCRIPT $PWD$IMX_UUU_TOOL/$SOCNAME/$BOARDTYPE/$BOARDTYPE$BOARDTYPE_tail $EMMCIMAGE"
echo
echo "command perform ..."
echo 
sudo ./$UUU -d -b $EMMCSCRIPT $PWD$IMX_UUU_TOOL/$SOCNAME/$BOARDTYPE/$BOARDTYPE$BOARDTYPE_tail $EMMCIMAGE
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

