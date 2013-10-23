setMode -pff
setMode -pff
addConfigDevice  -name "camera_ImageMove" -path "C:\Users\Chelly\GitHub\camera_ImageMove"
setSubmode -pffserial
setAttribute -configdevice -attr multibootBpiType -value ""
addDesign -version 0 -name "0"
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr autoSize -value "FALSE"
setAttribute -configdevice -attr fileFormat -value "mcs"
setAttribute -configdevice -attr fillValue -value "FF"
setAttribute -configdevice -attr swapBit -value "FALSE"
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr spiSelected -value "FALSE"
setAttribute -configdevice -attr spiSelected -value "FALSE"
addPromDevice -p 1 -size 0 -name xcf04s
setMode -pff
setMode -pff
setSubmode -pffserial
setMode -pff
addDeviceChain -index 0
setMode -pff
setMode -pff
setMode -pff
addDeviceChain -index 0
addDevice -p 1 -file "C:/Users/Chelly/GitHub/camera_ImageMove/camera_to_display.bit"
setMode -pff
setSubmode -pffserial
generate
setCurrentDesign -version 0
setMode -bs
setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Identify -inferir 
identifyMPM 
assignFile -p 2 -file "C:/Users/Chelly/GitHub/camera_ImageMove/camera_ImageMove.mcs"
setAttribute -position 2 -attr packageName -value ""
Program -p 2 -e -v 
setMode -bs
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
saveProjectFile -file "C:\Users\Chelly\Xilinx_workspace\LED_TEST\\auto_project.ipf"
setMode -bs
setMode -pff
setMode -bs
deleteDevice -position 1
deleteDevice -position 1
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
deletePromDevice -position 1
setCurrentDesign -version 0
deleteDevice -position 1
deleteDesign -version 0
setCurrentDesign -version -1
