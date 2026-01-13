#!/system/bin/sh

log -p i -t PERMISSION_GRANT "Granting READ_LOGS permission to com.example.temper"

# Выдача разрешения через pm с правами root
su -c "pm grant com.example.temper android.permission.READ_LOGS"

log -p i -t PERMISSION_GRANT "Permission granted successfully"