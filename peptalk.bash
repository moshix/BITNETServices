#!/bin/bash
# pep talk generator for logins, HNET and more
# COPYRIGHT 2022 BY MOSHIX
#
# DEPENDENCIES:
# - bash > 4.0
#
# Ver 0.01 - Start to create skeleton
# Ver 0.02 - Made it work 
# Ver 0.03 - Add colors and terminal handling
# Ver 0.04 - add values to associative array onlinuers: timestamp%room
# Ver 0.05 - parse incoming messages from
# Ver 0.06 - give "clean" switch for no screen formatted output 
VERSION="0.06"


# terminal handling globals

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
blink=`tput blink`
rev=`tput rev`
reset=`tput sgr0`

p1=`shuf -i 1-18 -n 1`
p2=`shuf -i 1-18 -n 1`
p3=`shuf -i 1-18 -n 1`
p4=`shuf -i 1-18 -n 1`
#echo "$p1 $p2 $p3 $p4"

l1=`sed "${p1}q;d" /root/peptalk/pep.1`
l2=`sed "${p2}q;d" /root/peptalk/pep.2`
l3=`sed "${p3}q;d" /root/peptalk/pep.3`
l4=`sed "${p4}q;d" /root/peptalk/pep.4`
if [ "$1" == "clean" ]; then #  no screeen formating/colors etc.
        echo "$l1 $l2 $l3 $l4"
else
        echo " ${cyan}"
        echo "🍺🍺"
        echo "$l1 $l2 $l3 $l4"
        echo "${reset}"
fi

exit
