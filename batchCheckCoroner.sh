#!/bin/bash
for i in $(ls | grep -v output | grep -v NightmareOfMadness) 
do
 checkCoroner.sh $i
done