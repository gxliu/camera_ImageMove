setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "C:/Users/Unknown/Downloads/la-bin-0.8.tar/la-bin-0.8/LogicAnalyzer/fpga/la.bit"
assignFile -p 2 -file "C:/Users/Unknown/Downloads/la-bin-0.8.tar/la-bin-0.8/LogicAnalyzer/fpga/flash.mcs"
setAttribute -position 2 -attr packageName -value ""
Program -p 1 
Program -p 2 -e -v 
setCable -port auto
Identify -inferir 
identifyMPM 
assignFile -p 1 -file "C:/workspace/fpga/3rd_day/camera_practice_0_grayscale/camera_to_display.bit"
Program -p 1 
Program -p 1 
Program -p 1 
Program -p 1 
setMode -bs
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
