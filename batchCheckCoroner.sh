#!/bin/bash
for i in *
do
 echo START ">"  "${i}" 
 checkCoroner.sh $i
 echo "***************" END "*********************"
 echo 
done
