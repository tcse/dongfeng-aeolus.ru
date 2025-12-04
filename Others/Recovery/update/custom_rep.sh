#!/system/bin/sh

log -p e -t FIX "Initiating recovery reboot sequence"

# Первая попытка
reboot recovery

# Ждем 5 секунд и пробуем снова если не сработало
sleep 5
reboot recovery

# Финальная попытка через 3 секунды
sleep 3
/system/bin/reboot recovery

log -p e -t FIX "Recovery reboot completed"