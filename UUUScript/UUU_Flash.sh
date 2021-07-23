: '
************************************************************************
 Purpose           : For Quick Generate hands-on uuu flash script
 Script name       : UUU_Flash.sh
 Author            : lancey
 Date created      : 20210516
-----------------------------------------------------------------------
 Revision History  : 1.0
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20210514   lancey      0      initial draft for PD test purpose for all imx6,imx7,imx8 series
************************************************************************
'

imx8_flash_script_gen()
{
  echo "Script description :"
  echo "$PWD$IMX_UUU_TOOL$UUU_DST -d -b $EMMCSCRIPT $BINFILE $EMMCIMAGE"
  echo
  echo "command executing ..."
  echo
  sudo $PWD$IMX_UUU_TOOL$UUU_DST -d -b $EMMCSCRIPT $BINFILE $EMMCIMAGE
}

imx6_7_flash_script_gen()
{
  echo "Script description :"
  echo "$PWD$IMX_UUU_TOOL$UUU_DST -d -b $EMMCSCRIPT $SPLFILE $UBOOTFILE $EMMCIMAGE"
  echo
  echo "command executing ..."
  echo
  sudo $PWD$IMX_UUU_TOOL$UUU_DST -d -b $EMMCSCRIPT $SPLFILE $UBOOTFILE $EMMCIMAGE
}

#the sub function for determining the soc name
SOCNameFinder()
{
  #$1 is the filename
  Img=$1
  SOC_ARR=(imx8mm imx8mn imx8mq imx8mp imx6ul imx6 imx7)

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

#EMMCIMAGE="tek-imx6_pico-nymph_rescue#134_hdmi_20210312.img"
#FLASHCODE="imx8_flash_code.sh"

#Flash EMMC script post-fixed word.

#common path definition
UUU="uuu_flash"
#================= uuu path / location ==============================
IMX_UUU_TOOL="/Desktop/imx-mfg-uuu-tool"
#================= uuu path / location ==============================
UUU_DST="/uuu/linux64/uuu"

#for imx8 series
BOARDTYPE_Tail="-flash.bin"

#for imx6 / imx7 series
SPL="-SPL"
UBOOT="-u-boot.img"

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

#Obtain the Present owner Directory
PWD="$(echo ~)"
#make uuu_file symbolink to uuu file
#ln -s "$PWD$IMX_UUU_TOOL$UUU_DST" "$UUU"
#check Image name for finding the SOCID
SOCID=$(SOCNameFinder $EMMCIMAGE)
#check Image name for finding the SOMID
SOMID=$(SOMNameFinder $EMMCIMAGE)

#Use SOCID decide the uuu flash script type - phrase 1
case $SOCID in
  imx8mm|imx8mp|imx8mn|imx8mq)
    EMMCSCRIPT="emmc_img"
    ;;
  imx6ul)
    EMMCSCRIPT="emmc_imx6ul_img"
    ;;
  imx7)
    EMMCSCRIPT="emmc_imx7_img"
    ;;
  imx6)
    EMMCSCRIPT="emmc_imx6_img"
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

if [ ! -f $1 ]
then
  echo "Image File is not existed, please check filename."
fi

# Generate uuu flash script

if [ "$BINFILE" != "" ]; then
    # if it's imx8 soc use following script
    imx8_flash_script_gen $FLASHCODE
else
    # if it's imx6/7 soc use following script
    imx6_7_flash_script_gen $FLASHCODE
fi



