#!/bin/bash
for i in *
do
 echo $i
 checkCoroner.sh $i
done
