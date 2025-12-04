#!/system/bin/sh

log -p e -t FIX "Hello open adb start"

#start open adb
# otg_control.sh 0
# sleep 2
otg_control.sh 1  

stop adbd
sleep 2
start adbd
log -p e -t FIX "Hello open adb end"
