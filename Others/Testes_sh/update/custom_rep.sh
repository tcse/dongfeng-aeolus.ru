#!/system/bin/sh

log -p i -t SYSTEM_FIX "Starting combined system fixes"

# 1. Активация FreeForm/PIP режима для Leco Auto
log -p i -t SYSTEM_FIX "Activating FreeForm support"
settings put global enable_freeform_support 1
settings put global force_resizable_activities 1
settings put global always_finish_activities 0

# Опциональная оптимизация для FreeForm
settings put global app_side_blacklist ""
settings put global policy_control "null"
log -p i -t SYSTEM_FIX "FreeForm activation completed"

# 2. Выдача прав на чтение логов приложению temper
log -p i -t SYSTEM_FIX "Granting READ_LOGS permission to com.example.temper"

# Выдача разрешения через pm с правами root
su -c "pm grant com.example.temper android.permission.READ_LOGS"

log -p i -t SYSTEM_FIX "Permission granted successfully"

# Небольшая пауза для завершения всех операций
sleep 2

log -p i -t SYSTEM_FIX "All operations completed. Rebooting system..."

# Перезагрузка системы
reboot