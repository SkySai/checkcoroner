#!/bin/bash
rm -rf NightmareOfMadness/
if [ $# -eq 0 ]; then

 echo "Enter the name of the file we're looking to extract information from. " 

 read coroner
else
 coroner="$1"
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



#read selection



if [ -f pref1.txt ]; then 
 # echo '****legacy 220 model, yes?****'
 codecPhoneSerial="$(cat pref1.txt | awk ' /systemboard/  {print $3}' | tr -d \")"
 codecSerial="$(echo "${codecPhoneSerial}" | awk 'FNR ==1 {print}')"
 phoneSerial="$(echo "${codecPhoneSerial}" | awk 'FNR ==2 {print}')"
 cameraSerial="$(cat pref1.txt | awk ' /sn_camera/ {print $3}' | awk 'FNR ==1 {print}')"
fi
if [ -f sysinfo.txt ]; then
 codecPhoneSerial="$(cat sysinfo.txt | awk ' /info.system.serialnumber/ {print $3}' | tr -d \")"
 codecSerial="$(echo "${codecPhoneSerial}" | awk 'FNR ==1 {print}')"
 phoneSerial="$(echo "${codecPhoneSerial}" | awk 'FNR ==2 {print}')"
 cameraSerial="$(cat sysinfo.txt | awk ' /info.camera.hdmi0.serialnumber/ {print $3}')"

fi

filename="output"$codecSerial".txt"
 #echo $filename
 echo Codec Serial = ${codecSerial} > ../$filename
 echo Phone Serial = ${phoneSerial} >> ../$filename
 echo Camera Serial = ${cameraSerial} >> ../$filename
#unit="good" > ../output.txt + $unit

 
if [ -f pref1.txt ]; then
 version="$(cat pref1.txt | awk '/version/ {print $3}' | awk 'FNR ==2 {print}')"
fi
if [ -f sysinfo.txt ]; then
 version="$(cat sysinfo.txt | awk ' /info.system.buildversion/ {print}' | awk -F'_' '{print $3}' | awk -F ' ' '{print $1}')"
fi
 	
	
tempFanStatus="normal"; #get ready to check fans

if [ -f sysmon.txt ]; then
 codecfans="$(cat sysmon.txt | awk '/fan/ {print $3}' | tr -d '"')"
 fan0avg="$(echo "${codecfans}" | awk 'FNR ==1 {print}')" 
 fan1avg="$(echo "${codecfans}" | awk 'FNR ==2 {print}')" 
 tempFanStatus="$(cat sysmon.txt | awk '/overheated/ {print $3}')"
 echo Fan 0 RPM "${fan0avg}" >> ../$filename
 echo Fan 1 RPM "${fan1avg}" >> ../$filename
fi
if [ -f tempmon.txt ]; then
 count=0;
 total=0; 
 fan1avg=0;
 fan0avg=0;
 checkIcon400Fan0="$(cat tempmon.txt | awk 'FNR==2 {print $5}')"
 if [ "$checkIcon400Fan0" -le 0 ]; then ## this is an icon 400; less fans
  echo "This is an Icon 400, please check fans manually" 
  for i in $( awk '{print $7}' tempmon.txt) #get average of fan1
  do
   total=$(($total + $i))
   ((count++))
  done
  if [ "$total" -le 0 ]; then
   echo A fan has failed >> ../$filename
   unit="bad"
   tempFanStatus="badfan"
  else
   fan1avg=$(($total / $count))
  fi
  if [ "$fan1avg" -gt 4500 ]; then #logic for checking if fan1 avg exceeds 'number' 
   echo Fan Speed High: "${fan1avg}" 
   unit="bad"
   tempFanStatus="badfan"
  fi
 else  #check both fans for general icons
  for i in $( awk '{print $17}' tempmon.txt) #get average of fan0
  do
   total=$(($total + $i))
   ((count++))
  done
  if [ "$total" -le 0 ]; then
   echo A fan has failed >> ../$filename
   unit="bad"
   tempFanStatus="badfan"
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
   unit="bad"
   tempFanStatus="badfan"
  else
   fan1avg=$(($total / $count))
  fi
  
 fi
 echo Fan 0 RPM "${fan0avg}" >> ../$filename
 echo Fan 1 RPM "${fan1avg}" >> ../$filename
 echo Temperature Status = "${tempFanStatus}" >> ../$filename
fi
if [ "$fan0avg" -gt 4500 ]; then #logic for checking if fan1 avg exceeds 'number' 
 echo Fan Speed High: "${fan0avg}"
 unit="not bad, not great"
 tempFanStatus="badfan"
fi
if [ "$fan1avg" -gt 4500 ]; then #logic for checking if fan1 avg exceeds 'number' 
 echo Fan Speed High: "${fan1avg}" 
 unit="not bad, not great"
 tempFanStatus="badfan"
fi


  ##done with fans / temperature -- check resetlog for watchdog and powerfaults. 
if [ -f sysmon.txt ]; then
 numWatchDogFaults="$(tail -n 40 'reset.log' | awk '/Watchdog/ {print $11}' | wc -l)" 
 numPowerFaults="$(tail -n 40 'reset.log' | awk '/PowerFault/ {print $11}' | wc -l )" 
 echo Number of Watchdog Faults: "${numWatchDogFaults}" >> ../$filename
 echo Number of PowerFaults: "${numPowerFaults}" >> ../$filename
fi
if [ -f data.tgz ]; then
 tar -zxf data.tgz
 cd data
 numWatchDogFaults="$(tail -n 40 'reset.log' | awk '/Watchdog/ {print $11}' | wc -l)" 
 numPowerFaults="$(tail -n 40 'reset.log' | awk '/PowerFault/ {print $11}' | wc -l )" 
 echo Number of Watchdog Faults: "${numWatchDogFaults}" >> ../../$filename
 echo Number of PowerFaults: "${numPowerFaults}" >> ../../$filename
 if [ "$numWatchDogFaults" -gt 3 ]; then
  unit="bad"
  ResetLogOutput="more than 3 watchDogFaults found"
 fi 
 if [ "$numPowerFaults" -gt 3 ]; then
  unit="bad"
  ResetLogOutput="more than 3 powerFaults Found"
 fi 
 cd ..
fi
  
  

if [ -f pref1.txt ]; then
 coreDumpsCount=0;
 #echo "$(ls -la | grep "core")" >> ../$filename
 coreDumpsCount="$(ls -la | grep "core" | wc -l)" 
 ((coreDumpsCount--))
 echo Number of Coredump Files in this coroner: "${coreDumpsCount}" >> ../$filename
 if [ "$coreDumpsCount" -gt 3 ]; then
  unit="bad"
  CoreDumpsOutput="more than 3 coredumps found"
 fi 
fi
if [ -f sysinfo.txt ]; then
 cd data
 coreDumpsCount=0;
 cd cores
 #echo "$(ls -la | grep "core")" >> ../$filename
 coreDumpsCount="$(ls -la | grep "core" | wc -l)" 
 echo Number of Coredump Files in this coroner: "${coreDumpsCount}" >> ../../../$filename
 if [ "$coreDumpsCount" -gt 3 ]; then
  unit="bad"
  CoreDumpsOutput="more than 3 coredumps found"
 fi 
 cd ..
fi
cd ..

numCarrierErrors=0;
numFrameErrors=0;
if [ -f reset.log ]; then
 numCarrierErrors="$(cat ifconfig.txt | grep carrier | awk -F ":" 'FNR==1 {print $6}')"
 if [ "$numCarrierErrors" -gt 10 ]; then
 unit="bad"
 ifConfigOutput="number of Carrier errors exceeds 10"
 fi
 numFrameErrors="$(cat ifconfig.txt | grep frame | awk -F ":" 'FNR==1 {print $6}')"
 echo "$(head -10 ifconfig.txt)" >> ../$filename
 if [ "$numFrameErrors" -gt 10 ]; then
 unit="bad"
 ifConfigOutput="number of Frame errors exceeds 10"
 fi
fi
 
if [ -f data.tgz ]; then
 numCarrierErrors="$(cat ifconfig.txt | grep carrier | awk -F ":" 'FNR==1 {print $6}')"
 echo "$(head -10 ifconfig.txt)" >> ../$filename
 if [ "$numCarrierErrors" -gt 10 ]; then
  unit="bad"
  ifConfigOutput="number of Carrier errors exceeds 10"
 fi
 numFrameErrors="$(cat ifconfig.txt | grep frame | awk -F ":" 'FNR==1 {print $6}')"
 if [ "$numFrameErrors" -gt 10 ]; then
  unit="bad"
  ifConfigOutput="number of Frame errors exceeds 10"
 fi
fi




echo Unit is "${unit}"

echo -n "

*********************************************

Coroner Information:

1) Serial Extraction                            "${codecSerial}"
2) System Version                               "${version}"
3) Temperature and Fans Status:                 "${tempFanStatus}" 
4) Reset Log Watchdog/Powerfaults               "${ResetLogOutput}"
5) Coredumps                                    "${CoreDumpsOutput}"
6) ifconfig 					"${ifConfigOutput}"


*********************************************
"

cd ..

rm -rf NightmareOfMadness/
