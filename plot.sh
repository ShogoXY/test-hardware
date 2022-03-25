#!/bin/bash

# 1 do 30 = 60 sec
# 1 do 60 = 120sec
#wartość podzielić przez 2

x=0
while [ $x -eq 0 ];do
    echo -e "$(sudo ipmimonitoring  | grep -Ei 'CPU'|grep -v VRM|awk '{print $10}') \t$(date +%T)" >> /home/$USER/plot.txt
    sudo ipmimonitoring  | grep -Ei 'CPU0 |CPU 0|cpu_0'|grep -v VRM|awk '{print $10}' >> /home/$USER/plot_1_cpu.txt
    sudo ipmimonitoring  | grep -Ei 'CPU1 |CPU 1|cpu_1'|grep -v VRM|awk '{print $10}' >> /home/$USER/plot_2_cpu.txt	
    now=$(date +%T)

    echo -e "$(cat /home/$USER/plot_1_cpu.txt)""\t$(cat /home/$USER/plot_2_cpu.txt)""\t$now" >> /home/$USER/plot2.txt	
    sleep 2

done 