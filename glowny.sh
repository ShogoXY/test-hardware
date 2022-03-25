#!/bin/bash
wynik=$(date +%y%m%d_%H%M%S)
czas=$wynik
numer_seryjny=$(sudo dmidecode -s baseboard-serial-number)


mkdir -p /home/$USER/raport
mkdir -p /home/$USER/raport/$numer_seryjny
mkdir -p /home/$USER/raport/$numer_seryjny/$wynik
folder=/home/$USER/raport/$numer_seryjny/$wynik

cd $folder

logi_jadra=0-kernel-log.txt

echo -e "Logi jadra linux zebrane tuz przed rozpoczeciem dzialania skryptow testowych\n" >> $logi_jadra


sudo cat /var/log/kern.log >> $logi_jadra
lspci=0-lspci.txt
lspci > $lspci
echo "" >> $lspci
lspci -v >> $lspci


#################################################################
### wyslanie logow jadra linux na serwer
#
#
##ftp -n <<EOF
##open 192.168.3.1
##user tester tester
##cd upload
##cd $katalog
##mkdir $numer_seryjny
##cd $numer_seryjny
##mkdir $czas
##cd $czas
##put $logi_jadra
##put $lspci
##EOF
#
#
#wget 192.168.3.1/dmidecode.deb
#chmod +x dmidecode.deb
#sudo dpkg -i dmidecode.deb
#

t=1-raport-glowny.txt
#xfce4-terminal --hide-menubar --geometry=140x45 -T "Wyniki na zywo" -e "tail -f $t"
printf "
==================================================================
*****************         RAPORT SERWISOWY        ****************
==================================================================

==================================================================
`date +%H:%M:%S` [1/3] Rozpoznawanie sprzetu
==================================================================

----------------------------------------------------------- SYSTEM

Producent:     $(sudo dmidecode -s system-manufacturer)
Model:         $(sudo dmidecode -s system-product-name)
Numer seryjny: $(sudo dmidecode -s system-serial-number)


---------------------------------------------------------- OBUDOWA

Producent: $(sudo dmidecode -s chassis-manufacturer)
Rodzaj:    $(sudo dmidecode -s chassis-type)
Numer seryjny: $(sudo dmidecode -s chassis-serial-number)


----------------------------------------------------- PLYTA GLOWNA

Producent:     $(sudo dmidecode -s baseboard-manufacturer)
Model:         $(sudo dmidecode -s baseboard-product-name)
Wersja BIOS:   $(sudo dmidecode -s bios-version)
Numer seryjny: $(sudo dmidecode -s baseboard-serial-number)


--------------------------------------------------------- PROCESOR

$(sudo dmidecode -s processor-version)


------------------------------------------------------- PAMIEC RAM

$(sudo dmidecode -t 17 | grep -E 'Locator:|Size:|Manufacturer|Serial Number|Part Number' | sed -E "s/Size/\nRozmiar/g; s/\t//g; s/Manufacturer/Producent/g; s/Serial Number/Numer seryjny/g; s/Locator/Polozenie/g; s/Bank Locator/Polozenie banku/g" | grep -v "Bank Polozenie")


--------------------------------------------------- KARTY SIECIOWE

$(inxi -c0 -n | sed -E "s/Card-/\n/g" | sed -e "s/^Network\://" | sed -e "s/driver\:/\ndriver\:/g" | sed -e "s/mac\:/ZZQQE\nmac/" | sed -e 's/^[ \t]*//' | sed '/driver:/,/ZZQQE/d' )


--------------------------------------------------------- ZASILACZ

$(sudo dmidecode -t 39 |grep -iE "Location|name|manufacturer|serial number|Model|revision|capacity|system power")




--------------------------------------------------------- BMC/IPMI

$(sudo bmc-info | grep -E "Manufacturer|Firmware")


-------------------------------------------------------------- FRU

$(sudo ipmi-fru)
" |tee -a $t

##################################################################
# zapisanie czujników z IPMI oraz logów sel do pliku
# później będzie to wpisane do pliku wraz z
# wykazem czujników po testach
##################################################################

f=bmc-czujniki-i-logi.txt

printf "
------------------------------------------- Czujniki przed testami

$(sudo ipmimonitoring )

------------------------------------------- Logi SEL przed testami

$(sudo ipmi-sel )
" >> $f


##################################################################
# wykrywanie napędów, dysków i kontrolerów
echo -e "\n----------------------------------------------------- NAPĘDY/DYSKI\n"| tee -a $t

ls /dev/sr? >> /dev/null 2>&1
sr=$?
ls /dev/cd? >> /dev/null 2>&1
cd=$?
ls /dev/dvd? >> /dev/null 2>&1

dvd=$?

if [ $cd -eq 0 ] || [ $dvd -eq 0 ] || [ $sr -eq 0 ]; then
echo -e "\n--- Lista napedow/magrywarek CD/DVD\n" | tee -a $t
echo -e "$(lsblk --nodeps -no name,model,serial -p | grep -E "/dev/sr|/dev/dvd|/dev/cd)")" | tee -a $t
else
echo -e "\n--- Nie wykryto napedow/nagrywarek CD/DVD\n" | tee -a $t
fi

ls /dev/sd? >> /dev/null 2>&1

if [ $? -eq 0 ]; then
echo -e "--------------------------------------------------- DYSKI SATA/SAS\n" |tee -a $t

echo -e "\n--- Lista dyskow SATA/SAS rozpoznanych i dostepnych bezposrednio dla systemu\nczyli podpietych pod kontroler na plycie glownej,\npod karte HBA lub z ustawieniem JBOD pod kontrolerem RAID:\n" | tee -a $t
p=smart-dyskow-sata-sas
echo -e "$(lsblk --nodeps -o name,model,serial -p | grep -v -E "/dev/loop|/dev/nvme|/dev/sr|/dev/dvd|/dev/cd")" | tee -a $t
echo "" | tee -a $t
else
	echo -e "\n--- Nie wykryto dyskow SATA/SAS podpietych pod kontroler na plycie glownej,\npod karte HBA lub z ustawieniem JBOD pod kontrolerem RAID\n" | tee -a $t
fi
echo -e "------------------------------------------------------- DYSKI NVMe\n" |tee -a $t
# Wykrywanie do 40 dyskow NVMe i zapisywanie logow smart

ls /dev/nvme? >> /dev/null 2>&1

if [ $? -eq 0 ]; then
ls /dev/nvme[0-9] > lista_nvme
ls /dev/nvme1[0-9] >> /dev/null 2>&1

	if [ $? -eq 0 ]; then
	ls /dev/nvme1[0-9] >> lista_nvme
	fi
ls /dev/nvme2[0-9] >> /dev/null 2>&1

	if [ $? -eq 0 ]; then
	ls /dev/nvme2[0-9] >> lista_nvme
	fi
ls /dev/nvme3[0-9] >> /dev/null 2>&1

	if [ $? -eq 0 ]; then
	ls /dev/nvme3[0-9] >> lista_nvme
	fi



echo -e "\n--- Lista dyskow NVMe:\n" | tee -a $t
echo -e "widzianych przez system:\n" | tee -a $t
$(cat lista_nvme) | tee -a $t
echo -e "\nwidzianych przez program nvme:\n" | tee -a $t
$(sudo nvme list) | tee -a $t

else
	echo -e "--- Nie wykryto dyskow NVMe\n" | tee -a $t
fi

rm lista_nvme >> /dev/null 2>&1


echo -e "\n--------------------------------------------------- KONTROLERY RAID\n" |tee -a $t
# Wykrywanie kontrolerow RAID 6Gb/s, 12Gb/s i NVMe LSI

#sudo mkdir /opt2
#wget 192.168.3.1/storcli35.deb &> /dev/null

FILE=/home/$USER/storcli64
if [ -f "$FILE" ]; then
   echo "plik istnieje"
else
    sudo dpkg -x /home/$USER/storcli_007.1912.deb /opt2
    sudo ln /opt2/opt/MegaRAID/storcli/storcli64 /home/$USER/
fi



storcli64=/home/$USER/storcli64

lk2=$(sudo $storcli64 show | grep 'Number of Controllers' | cut -c25)
if [ $lk2 -eq 0 ]; then
	echo -e "--- Nie wykryto kontrolerow RAID LSI 92xx, 93xx i 94xx" | tee -a $t
	echo -e "$(lspci | grep -i lsi)" | tee -a $t
else
	echo -e "--- Liczba wykrytych kontrolerow RAID LSI 92xx, 93xx i 94xx: $lk2\n" | tee -a $t
fi
while [ $lk2 -gt 0 ] ; do
	lk2=$(( $lk2 - 1 ))
	sudo $storcli64 /c$lk2 show | grep -E 'Product Name|Serial Number' | tee -a $t;
	sudo $storcli64 /c$lk2/cv show all | grep -E 'Status' | grep -vE 'Firmware_Status|GasGaugeStatus' | grep 'Success'
	if [[ $? -eq 0 ]]; then
	echo -e "\nDo kontrolera $lk2 podpiety jest CacheVault" | tee -a $t
	sudo $storcli64 /c$lk2/cv show all | grep -E 'Serial Number|State|Type' | tee -a $t
	else
	echo -e "\nNie wykryto CacheVault podpiete pod kontroler $lk2" | tee -a $t
	fi
	sudo $storcli64 /c$lk2 show all | grep -E 'Controller Status|BBU Status|Physical Drives' >> status
	cat status | tee -a $t	
	ile=`cat status | grep "Physical Drives"`	
	if [[ $? -eq 0 ]]; then
	echo -e "\nDyski podpiete pod powyzszy kontroler" | tee -a $t
	sudo $storcli64 /c$lk2 /eall /sall show all | grep -E "SN|Model Number" | sed -e "s/SN/\nNumer seryjny/g; s/Model Number/Model/g" | tee -a $t
	fi
done
x=logi-events-kontrolera-lsi-nr-$lk2.txt
x1=logi-eventloginfo-kontrolera-lsi-nr-$lk2.txt
x2=logi-termlog-kontrolera-lsi-nr-$lk2.txt
x3=logi-alilog-kontrolera-lsi-nr-$lk2.txt
x4=szczegolowe-info-o-kontrolerze-lsi-nr-$lk2.txt
echo -e "\nWiecej informacji dotyczacych powyzszego kontrolera znajdziesz w folderze lsi" | tee -a $t

mkdir -p lsi
sudo $storcli64 /c$lk2 show events >> $folder/lsi/$x
sudo $storcli64 /c$lk2 show eventloginfo >> $folder/lsi/$x1
sudo $storcli64 /c$lk2 show termlog >> $folder/lsi/$x2
sudo $storcli64 /c$lk2 show alilog >> $folder/lsi/$x3
sudo $storcli64 /c$lk2 show all >> $folder/lsi/$x4
sudo $storcli64 /c$lk2/cv show all >> $folder/lsi/$x4



# rozpoznawanie sprzetu Adaptec

lspci | grep Adaptec > adaptec
if [ $? -eq 0 ]; then
	echo -e "\n--- Lista kontrolerow Adaptec:\n" | tee -a $t
	cat adaptec | tee -a $t
else
	echo -e "\n--- Nie wykryto kontrolerow Adaptec" | tee -a $t
fi

# rozpoznawanie kart fibre channel

lspci | grep Fibre
if [ $? -eq 0 ]; then
	echo -e "\n--- Lista kart Fibre Channel:\n" | tee -a $t
	lspci | grep Fibre | tee -a $t
	sleep 10
	echo "" | tee -a $t
	ql-hba-snapshot | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | tee -a $t
else
	echo -e "\n--- Nie wykryto kart Fibre Channel" | tee -a $t
fi


####################
#clean empty files
###################
find $folder -size 0 -print -delete >> /dev/null 2>&1
mv $folder/storcli.log $folder/lsi/ &> /dev/null




####################################################################################### LAN

test_lan() {

printf "
==================================================================
`date +%H:%M:%S` [2/3] Testy
==================================================================
" | tee -a $t

#######################
## Testowanie kart sieciowych
######################


printf "
#################################################
#                                               #
#              TEST KART SIECIOWYCH             #
#                                               #
#################################################


" | tee -a $t

# lista interfejsow i adresow IP

sudo ip r show | grep " src " | cut -d " " -f 3,9 > lista_net

for i in `ls /sys/class/net`;do

	cat lista_net | grep $i; 
	
	if [ $? -ne 0 ];then
		sudo ifconfig $i up
		sudo dhclient $i
	fi
done


sudo ip r show | grep " src " | cut -d " " -f 3,9 > nowa_lista_net
cut -f1 -d " " nowa_lista_net > nic


for i in `ls /sys/class/net | grep -v lo`; do 
	
	cat /sys/class/net/$i/operstate | grep down; 
	
	if [ $? -eq 0 ]; then
		printf "
---------------------------------------------- Karty niepodlaczone\n" > niepodlaczone
	fi
done

for i in `ls /sys/class/net | grep -v lo`; do 
	
	cat /sys/class/net/$i/operstate | grep down; 
	
	if [ $? -eq 0 ]; then
		echo -e "$i - mac $(cat /sys/class/net/$i/address)" >> niepodlaczone
	fi
done

cat niepodlaczone | tee -a $t

printf "
------------------------------------------------- Karty podlaczone" | tee -a $t

for i in `cat nic`; do 
	echo -e "\n$i - mac $(/sbin/ifconfig $i | grep ether | awk '{print $2}')" | tee -a $t; 
	ajpi=$(cat nowa_lista_net | grep $i | cut -f2 -d " " ); 
	iperf -p 888 -B $ajpi -c 192.168.3.1 | tee -a $t
done


rm $folder/lista_net >> /dev/null 2>&1

rm $folder/nic >> /dev/null 2>&1

rm $folder/nowa_lista_net >> /dev/null 2>&1



}

################################################################################################# MEMORY

test_pamieci() {

zapisz_temp_cpu () {
sudo ipmimonitoring | grep -Ei 'cpu|Temp_CPU0 |CPU0 Temp' >> $folder/temp_cpu0
sudo ipmimonitoring | grep -Ei 'cpu 1|Temp_CPU1 |CPU1 Temp' >> $folder/temp_cpu1
}





printf "
#################################################
#                                               #
#              TEST PAMIĘCI RAM                 #
#                                               #
#################################################
" | tee -a $t


printf "
----------------------------------------------------- Test pamieci\n" | tee -a $t



mem () {


x=0
while [ $x -eq 0 ]
do
#	if [ $? -eq 0 ]
#	then
	zapisz_temp_cpu
		sleep 5

#	else 
#	x=0
#fi

done &
#sudo memtester $(free -m |grep -iE "mem" |awk '{print $4 -900 }') 2|tee $folder/memtest_raport.txt
sudo memtester 150M 2|tee $folder/memtest_raport.txt 




if [ $? -eq 0 ]; then
	echo -e "\nNie wykryto problemow z pamiecia RAM. Wszystko OK!" | tee -a $t
else
	echo -e "\nTest nieudany, kod: $?" | tee -a $t
	echo "Znaczenia kodow" | tee -a $t
	echo "x01: Error allocating or locking memory, or invocation error" | tee -a $t
	echo "x02: Error during stuck address test" | tee -a $t
	echo "x03: Error during one of the other test" | tee -a $t
fi

pkill -f /home/$USER/czas.sh
kill %5 &> /dev/null
kill %4 &> /dev/null
kill %3 &> /dev/null
kill %2 &> /dev/null
kill %1 &> /dev/null
kill %- &> /dev/null

}




xfce4-terminal --geometry=30x5 -T "MEMTEST TIME" -e /home/$USER/czas.sh & mem 


rm /tmp/memfile >> /dev/null 2>&1


echo -e "\nTemperatura procesora CPU0 podczas testowania pamieci mierzona co 5s:\n" >> $t
cat $folder/temp_cpu0 >> $t
rm $folder/temp_cpu0 &> /dev/null
if [ -s $folder/temp_cpu1 ]
then
echo -e "\nTemperatura procesora CPU1 podczas testowania pamieci mierzona co 5s:\n" >> $t
cat $folder/temp_cpu1 >> $t
rm $folder/temp_cpu1 &> /dev/null
fi



}

############################################################################################## CPU
test_cpu() {



zapisz_temp_cpu () {
sudo ipmimonitoring  | grep -Ei 'cpu|Temp_CPU0 |CPU0 Temp' >> $folder/tempc_cpu0
sudo ipmimonitoring  | grep -Ei 'cpu 1|Temp_CPU1 |CPU1 Temp' >> $folder/tempc_cpu1
}
printf "
#################################################
#                                               #
#                  STRESS TEST                  #
#             TEST CPU ORAZ PAMIECI             #
#                                               #
#################################################
" |tee -a $t

#plot &

echo -e "odczekaj 15 sec \n"


a=0
for i in {1..3}
do
    
    zapisz_temp_cpu
    printf "$a.."
    sleep 5
    a=$((a+5))
done
echo ""
mins=1

a=$((mins))
b=$((a*60+15))


czas=`date '+%F %T'`

echo "Start time     -  $czas"
czasplus=`date -d ''$b' seconds' '+%F %T' `
echo "Estimate time  -  $czasplus"
echo ""
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%
printf "\r`date '+%F %T'` -- Progress : [${_fill// /#}${_empty// /-}] ${_progress}%% "

}
#"

# Variables
_start=1

# This accounts as the "totalState" variable for the ProgressBar function
_end=72

# Proof of concept

loop() {
for number in $(seq ${_start} ${_end})
do

    ProgressBar ${number} ${_end}
    sleep 1

done

}


stress () {
	sleep 10
	stress-ng --cpu 0 --cpu-method all --vm 3 --vm-bytes 90% -t 1m >> /dev/null 2>&1

}
save_cpu(){
for i in {1..7}
do
    zapisz_temp_cpu
     sleep 10
done
}


######################################## main function
stress & loop & save_cpu 


echo -e "\nodczekaj 15 sec \n"
a=0
for i in {1..3}
do
    
    zapisz_temp_cpu
    printf "$a.."
    sleep 5
    a=$((a+5))
done


echo ""



echo -e "\nTemperatura procesora CPU0 mierzona 15s przed, co 10s, do 15s po tescie:\n" >> $t
cat  $folder/tempc_cpu0 >> $t
rm $folder/tempc_cpu0 &> /dev/null
if [ -s $folder/tempc_cpu1 ]

then
echo -e "\nTemperatura procesora CPU1 mierzona 15s przed, co 10s, do 15s po tescie:\n" >> $t
cat $folder/tempc_cpu1 >> $t
rm $folder/tempc_cpu1 &> /dev/null
fi

printf '\nFinished!\n'

}

################################################################################################## DISKS

test_dyski () {


function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%
printf "\r`date '+%F %T'` -- Progress : [${_fill// /#}${_empty// /-}] ${_progress}%% "

}
#`
# Variables
_start=1

# This accounts as the "totalState" variable for the ProgressBar function
_end=120
_end2=120

# Proof of concept

loop() {
for number in $(seq ${_start} ${_end})
do

    ProgressBar ${number} ${_end}
    sleep 1

done

}

loop2() {
for number in $(seq ${_start} ${_end2})
do

    ProgressBar ${number} ${_end2}
    sleep 1

done

}



a=1
ile_dyskow=$(ls /dev/sd? |wc -l) &> /dev/null
ls /dev/sd? > /dev/null 2>&1

if [ $? -eq 0 ]; then
	
printf "
#################################################
#                                               #
#       Test S.M.A.R.T - Dyski SATA/SAS         #
#                                               #
#################################################


" |tee -a $t

    for i in `ls /dev/sd?`; do sudo smartctl -t short $i > /dev/null 2>&1

	echo ""
        file=$(sudo smartctl -a $i |grep Serial |awk '{print $3}')
        czas=`date '+%F %T'`

	czasplus=`date -d ''10' minutes' '+%F %T' `
	echo "-------------------- Test dysku $a z $ile_dyskow --------------------" | tee -a $t
	echo "$i S/N: $file " | tee -a $t
	echo "$file " >> full_log_disk
	echo "End time  -  $czasplus"
	echo ""

        loop

	echo ""


    	error=`sudo smartctl -A $i |grep -iE 'Reallocated|Current|Uncorrect|Command_Time|ATTRIBUTE|FAIL|grown|scsi error'`
    	echo "" | tee -a $t
    	echo "" | tee -a $t
    	printf '%s\n\n' "$error" | tee -a $t
    	echo ""

    	sudo smartctl -x $i > $file.txt
    	let "a=a+1"
done
else
	echo -e "Nie wykryto dyskow SATA/SAS" | tee -a $t
fi

printf '\nFinished!\n'





############################################# NVME



a=1
ile_dyskow=$(ls /dev/nvme? |wc -l) &> /dev/null
ls /dev/nvme? &> /dev/null 

if [ $? -eq 0 ]; then

printf "
#################################################
#                                               #
#        TEST S.M.A.R.T - DYSKI NVMe            #
#                                               #
#################################################
" | tee -a $t



    for i in `ls /dev/nvme?`; do sudo smartctl -x $i > /dev/null 2>&1

	echo ""
    file=$(sudo smartctl -a $i |grep Serial |awk '{print $3}')
    czas=`date '+%F %T'`

	czasplus=`date -d ''2' minutes' '+%F %T' `
	echo "Test dysku $a z $ile_dyskow" | tee -a $t
	echo "S/N: $file " | tee -a $t
	echo "$file " >> full_log_disk
	echo "End time  -  $czasplus"
	echo ""

        loop2

	echo ""


    	error=`sudo smartctl -A $i |grep -iE 'Available Spare:|Integrity Errors|Error Information Log|overall|scsi error'`
    	echo "" | tee -a $t
    	echo "" | tee -a $t
    	printf '%s\n\n' "$error" | tee -a $t
    	echo "#################################################"

    	sudo smartctl -x $i > $file.txt
    	let "a=a+1"
done
else
	echo -e "Nie wykryto dyskow NVMe" | tee -a $t
fi

printf '\nFinished!\n'

echo -e "Szczegółowe dane SMART dysków znajdują sie w plikach:\n" | tee -a $t
cat full_log_disk | tee -a $t 2> /dev/null
echo ""
rm full_log_disk >> /dev/null 2>&1


}

#################################################################################################### END RAPORT

end_raport() {
echo -e "\n--- Wykrywanie bledow sprzetowych\n" | tee -a $t

sudo edac-util | grep 'edac-util: No errors to report.'
if [ $? -eq 0 ]; then
echo -e "Informacje z EDAC: Brak bledow. Wszystko OK!" | tee -a $t
else
echo -e "Informacje z EDAC: UWAGA!\n" | tee -a $t
sudo edac-util -v | tee -a $t
fi

if [ -s /var/log/mcelog ]; then
echo -e "Informacje z mcelog: UWAGA!\n" | tee -a $t
sudo cat /var/log/mcelog | tee -a $t
else
echo -e "Informacje z mcelog: Brak bledow. Wszystko OK!\n" | tee -a $t
fi

echo -e "\n==================================================================" >> $t
echo -e "`date +%H:%M:%S` [3/3] Informacje z IPMI" >> $t
echo "==================================================================" >> $t

echo -e "\n- Logi SEL po testach:\n" >> $f
sudo ipmitool sel list >> $f
sudo ipmitool sel clear
sleep 5
echo -e "\n- Logi SEL po czyszczeniu [powinno nie byc nic/albo informacja o ich czyszczeniu]:\n" >> $f

sudo ipmitool sel list >> $f
echo -e "\n- Czujniki po testach:\n" >> $f
sudo ipmimonitoring >> $f
cat $f >> $t

echo -e "\n==================================================================" | tee -a $t
echo -e "*****************             KONIEC              ****************" | tee -a $t
echo "==================================================================" | tee -a $t

sudo dmesg >> dmesg-po-testach
find $folder -size 0 -print -delete >> /dev/null 2>&1
rm $folder/niepodlaczone &> /dev/null
rm $folder/status &> /dev/null
}




printf " 
###########################################

"
echo "Czy chcesz wykonać testy? [y/N]"
echo ""


read -p "" odpowiedz
odpowiedz=${odpowiedz:-no}

#odpowiedz="y"


if [[ "$odpowiedz" =~ ^([yY][eE][sS]|[yY]|[tT])$ ]]
then
	
	
	echo "Rozpoczyna się test"
	test_lan
	test_pamieci
	test_cpu
	test_dyski
	end_raport
        pkill -f plot.sh
	sleep 5
	echo ""
	echo ""
	rm $folder/temp_* >> /dev/null 2>&1
	cd

	if [ -s plot_2_cpu.txt ]; then
		# The file is not-empty.
		gnuplot /home/$USER/plot_time_cpu2 &> /dev/null
		
	else
		# The file is empty.
		gnuplot /home/$USER/plot_time_cpu &> /dev/null
	fi

	mv /home/$USER/test.png $folder/ &> /dev/null
	rm /home/$USER/plot.txt &> /dev/null
	rm /home/$USER/plot2.txt &> /dev/null
	thunar $folder
	
else

	echo "KONIEC, Dziękuje!"
	echo "Wyniki zanajdują sie w folderze $folder"
	thunar $folder
fi
