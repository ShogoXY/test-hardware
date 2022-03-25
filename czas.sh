#!/bin/bash
czas() {
printf "START: "
date +'%H:%M:%S %p'

while sleep 1
do

     
	czas=$(date +'%H:%M:%S %p')
   
	printf "\r %4s  $czas" 
	
done
 }
czas