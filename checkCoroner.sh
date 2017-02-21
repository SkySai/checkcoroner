#!/bin/bash
rm -rf NightmareOfMadness/
if [ $# -eq 0 ]; then

 echo "Enter the name of the file we're looking to extract information from. " 

 read coroner
else
 coroner="$@"
fi

 mkdir NightmareOfMadness
 cp "$coroner" NightmareOfMadness
 cd NightmareOfMadness
 Unmunge -x "$coroner"



unit="good"
SerialOutput=""
VersionOutput=""
TempFanOutput=""
ResetLogOutput="good"
CoreDumpsOutput="good"
ifConfigOutput="good"

function 220ExtractSerial {
 codecPhoneSerial="$(cat pref1.txt | awk ' /systemboard/  {print $3}' | tr -d \")"
 codecSerial="$(echo "${codecPhoneSerial}" | awk 'FNR ==1 {print}')"
 phoneSerial="$(echo "${codecPhoneSerial}" | awk 'FNR ==2 {print}')"
 cameraSerial="$(cat pref1.txt | awk ' /sn_camera/ {print $3}' | grep -v "none" )"
}

function iconExtractSerial {
 codecPhoneSerial="$(cat sysinfo.txt | awk ' /info.system.serialnumber/ {print $3}' | tr -d \")"
 codecSerial="$(echo "${codecPhoneSerial}" | awk 'FNR ==1 {print}')"
 phoneSerial="$(echo "${codecPhoneSerial}" | awk 'FNR ==2 {print}')"
 cameraSerial="$(cat sysinfo.txt | awk ' /info.camera.hdmi0.serialnumber/ {print $3}')"
}

function 220CheckFans {
 codecfans="$(cat sysmon.txt | awk '/fan/ {print $3}' | tr -d '"')"
 codecfans="$(cat sysmon.txt | awk ' /fan/ {print $3}' | tr -d \")"
 fan0avg="$(echo "${codecfans}" | awk 'FNR ==1 {print}')" 
 fan1avg="$(echo "${codecfans}" | awk 'FNR ==2 {print}')" 
 tempFanStatus="$(cat sysmon.txt | awk '/overheated/ {print $3}' | tr -d \")"  # tr -d \" takes out the "" from the output
}

function checkVersion {
if [ -f pref1.txt ]; then
 version="$(cat pref1.txt | awk '/version/ {print $3}' | awk 'FNR ==2 {print}' | tr -d \")"
fi
if [ -f sysinfo.txt ]; then
 version="$(cat sysinfo.txt | awk ' /info.system.buildversion/ {print}' | awk -F'_' '{print $3}' | awk -F ' ' '{print $1}' | tr -d \")"
fi
} 

function 220checkStatus {
 numFailedStatus="$(cat pref1.txt | grep status | grep ready | grep -i -c false)"
 if [ "$numFailedStatus" -gt 0 ]; then
  echo A PRIMARY SYSTEM FUNCTION HAS FAILED
  unit="bad"
 fi
}

function i400CheckFans { 
echo "This is an Icon 400, please check fans manually" 
for i in $( awk '{print $7}' tempmon.txt) #get average of fan1
 do
  total=$(($total + $i))
  ((count++))
 done
 if [ "$total" -le 0 ]; then
  echo A fan has failed >> ../$filename
  #unit="bad"
  #tempFanStatus="badfan"
 else
  fan1avg=$(($total / $count))
 fi
 if [ "$fan1avg" -gt 4500 ]; then #logic for checking if fan1 avg exceeds 'number' 
  echo Fan Speed High: "${fan1avg}" 
  #unit="bad"
  #tempFanStatus="badfan"
 fi
 for i in $( awk '{print $8}' tempmon.txt) ##check status
  do
   if [ "$i" != "normal" ]; then
    tempFanStatus="$i"
   fi
  done
}

function iconCheckFans {
for i in $( awk '{print $17}' tempmon.txt) #get average of fan0
  do
   total=$(($total + $i))
   ((count++))
  done
  if [ "$total" -le 0 ]; then
   echo A fan has failed >> ../$filename
   #unit="bad"
   #tempFanStatus="badfan"
  else
   fan0avg=$(($total / $count))
  fi
  count=0;
  total=0;
  for i in $( awk '{print $20}' tempmon.txt) ##check status
  do
   if [ "$i" != "normal" ]; then
    tempFanStatus="$i"
   fi
  done
  for i in $( awk '{print $18}' tempmon.txt) #get average of fan1
  do
   total=$(($total + $i))
   ((count++))
  done
  if [ "$total" -le 0 ]; then
   echo A fan has failed >> ../$filename
   #unit="bad"
   #tempFanStatus="badfan"
  else
   fan1avg=$(($total / $count))
  fi
}

function fanLogic {
if [ "$fan0avg" -gt 4500 ]; then #logic for checking if fan0 avg exceeds 'number' 
 echo Fan Speed High: "${fan0avg}"
# unit="not bad, not great"
 #tempFanStatus="badfan"
fi
if [ "$fan1avg" -gt 4500 ]; then #logic for checking if fan1 avg exceeds 'number' 
 echo Fan Speed High: "${fan1avg}" 
# unit="not bad, not great"
 #tempFanStatus="badfan"
fi
}

function 220WatchdogPowerFaults { 
 numWatchDogFaults="$(tail -n 40 'reset.log' | awk '/WDOG/ {print $11}' | wc -l)"  
 numPowerFaults="$(tail -n 40 'reset.log' | awk '/POWR/ {print $11}' | wc -l )" 
 echo Number of Watchdog Faults: "${numWatchDogFaults}" >> ../$filename 
 echo Number of PowerFaults: "${numPowerFaults}" >> ../$filename 

 if [ "$numPowerFaults" -gt 3 ]; then
  #unit="bad"
  ResetLogOutput="more than 3 powerFaults Found"
 fi 
 
  if [ "$numWatchDogFaults" -gt 3 ]; then
  #unit="bad"
  ResetLogOutput="more than 3 watchDogFaults found"
 fi 
}  

function iconWatchdogPowerFaults { 
 tar -zxf data.tgz
 cd data
 numWatchDogFaults="$(tail -n 40 'reset.log' | awk '/Watchdog/ {print $11}' | wc -l)" 
 numPowerFaults="$(tail -n 40 'reset.log' | awk '/PowerFault/ {print $11}' | wc -l )" 
 echo Number of Watchdog Faults: "${numWatchDogFaults}" >> ../../$filename
 echo Number of PowerFaults: "${numPowerFaults}" >> ../../$filename
 
 if [ "$numPowerFaults" -gt 3 ]; then
  #unit="bad"
  ResetLogOutput="more than 3 powerFaults Found"
 fi 
 
 if [ "$numWatchDogFaults" -gt 3 ]; then
  #unit="bad"
  ResetLogOutput="more than 3 watchDogFaults found"
 fi 
 cd ..
}	
	
function 220CoreDumps { 
coreDumpsCount=0;
coreDumpsCount="$(ls -la | grep "core" | wc -l)" 
((coreDumpsCount--))
echo Number of Coredump Files in this coroner: "${coreDumpsCount}" >> ../$filename
if [ "$coreDumpsCount" -gt 3 ]; then
 #unit="bad"
 CoreDumpsOutput="more than 3 coredumps found"
fi 
}

function iconCoreDumps { 
 cd data
 coreDumpsCount=0;
 cd cores
 coreDumpsCount="$(ls -la | grep "core" | wc -l)" 
 echo Number of Coredump Files in this coroner: "${coreDumpsCount}" >> ../../../$filename
 if [ "$coreDumpsCount" -gt 3 ]; then
  #unit="bad"
  CoreDumpsOutput="more than 3 coredumps found"
 fi 
 cd ..
cd ..
} 

function 220CheckIFConfig { 
numCarrierErrors="$(cat ifconfig.txt | grep carrier | awk -F ":" 'FNR==1 {print $6}')"
 if [ "$numCarrierErrors" -gt 10 ]; then
  #unit="bad"
  ifConfigOutput="number of Carrier errors exceeds 10"
 fi
 numFrameErrors="$(cat ifconfig.txt | grep frame | awk -F ":" 'FNR==1 {print $6}')"
 echo "$(head -10 ifconfig.txt)" >> ../$filename
 if [ "$numFrameErrors" -gt 10 ]; then
  #unit="bad"
  ifConfigOutput="number of Frame errors exceeds 10"
 fi
} 

function iconCheckIFConfig { 
numCarrierErrors="$(cat ifconfig.txt | grep carrier | awk -F ":" 'FNR==1 {print $6}')"
 echo "$(head -10 ifconfig.txt)" >> ../$filename
 if [ "$numCarrierErrors" -gt 10 ]; then
  #unit="bad"
  ifConfigOutput="number of Carrier errors exceeds 10"
 fi
 numFrameErrors="$(cat ifconfig.txt | grep frame | awk -F ":" 'FNR==1 {print $6}')"
 if [ "$numFrameErrors" -gt 10 ]; then
  #unit="bad"
  ifConfigOutput="number of Frame errors exceeds 10"
 fi
}

function iconCheckRootfs { 

 echo "$(cat df.txt | awk 'FNR==2 {print} ')" >> ../$filename

} 
####START###	
if [ -f pref1.txt ]; then 
 220ExtractSerial
fi
if [ -f sysinfo.txt ]; then
 iconExtractSerial
fi
filename="output"$codecSerial".txt"
echo Codec Serial = ${codecSerial} > ../$filename
echo Phone Serial = ${phoneSerial} >> ../$filename
for i in ${cameraSerial}
do
	echo Camera Serial = $i >> ../$filename
done
checkVersion
tempFanStatus="normal"; #get ready to check fans - set as "normal" - other functions can change this value to "bad" 
if [ -f sysmon.txt ]; then
 220CheckFans
fi
if [ -f tempmon.txt ]; then
 count=0;
 total=0; 
 fan1avg=0;
 fan0avg=0;
 checkIcon400Fan0="$(cat tempmon.txt | awk 'FNR==2 {print $5}')"
 if [ "$checkIcon400Fan0" -le 0 ]; then ## this is an icon 400; less fans
  i400CheckFans #check single fan for icon 400s
 else  
  iconCheckFans #check both fans for general icons
 fi
fi
fanLogic
echo Fan 0 RPM "${fan0avg}" >> ../$filename
echo Fan 1 RPM "${fan1avg}" >> ../$filename
echo Temperature Status = "${tempFanStatus}" >> ../$filename

#checkResetLog
if [ -f sysmon.txt ]; then
 220WatchdogPowerFaults
fi
if [ -f data.tgz ]; then
 iconWatchdogPowerFaults
fi

if [ -f pref1.txt ]; then
 220CoreDumps
fi
if [ -f sysinfo.txt ]; then
 iconCoreDumps
fi

#checkIFCONFIG
numCarrierErrors=0;
numFrameErrors=0;
if [ -f reset.log ]; then
 220CheckIFConfig
fi
 
if [ -f data.tgz ]; then
 iconCheckIFConfig
fi

#checkStatus
if [ -f reset.log ]; then
 220checkStatus
fi

if [ -f data.tgz ]; then
 iconCheckRootfs
fi

#echo Unit is "${unit}"

echo -n "

Unit is "${unit}" 

Coroner Information:

1) Serial Extraction                            "${codecSerial}"
2) System Version                               "${version}"
3) Temperature and Fans Status:                 "${tempFanStatus}" 
4) Reset Log Watchdog/Powerfaults               "${ResetLogOutput}"
5) Coredumps                                    "${CoreDumpsOutput}"
6) ifconfig 					"${ifConfigOutput}"


"

cd ..

rm -rf NightmareOfMadness/



