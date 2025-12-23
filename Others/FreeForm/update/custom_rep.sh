#!/system/bin/sh

log -p i -t FIX "Starting FreeForm activation"

# Основные команды активации
settings put global enable_freeform_support 1
settings put global force_resizable_activities 1
settings put global always_finish_activities 0

# Опциональная оптимизация
settings put global app_side_blacklist ""
settings put global policy_control "null"

log -p i -t FIX "FreeForm activation completed"