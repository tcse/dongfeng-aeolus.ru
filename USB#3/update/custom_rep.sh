#!/system/bin/sh
# ============================================================================
# УДАЛЕНИЕ ES FILE EXPLORER ИЗ DONGFENG AEOLUS
# ============================================================================
# Проект: Автоматическая установка приложений на магнитолы Dongfeng Aeolus
# Форум: https://dongfeng-aeolus.ru/community/topicid/422/
# Телеграм: https://t.me/aeolusshinegs
# Репозиторий: https://github.com/tcse/dongfeng-aeolus.ru
# Авторы: Vitaly V. Chuyakov <vitaly@chuyakov.ru>, Deepseek AI
# Лицензия: GNU GPLv3
# Версия: 1.0.0
# Дата: 2025-12-03
# Назначение: Полное удаление ES File Explorer из системы
# ============================================================================

LOG="/data/local/tmp/es_quick_remove.log"
echo "Удаление ES с флешки: $(date)" > $LOG

# Останавливаем
am force-stop com.estrongs.android.pop 2>/dev/null
pkill -f es 2>/dev/null

# Удаляем из system
mount -o remount,rw /system 2>/dev/null
rm -rf /system/priv-app/ES* 2>/dev/null
rm -rf /system/app/ES* 2>/dev/null
rm -rf /system/priv-app/es* 2>/dev/null
rm -rf /system/app/es* 2>/dev/null
rm -rf /system/priv-app/com.estrongs.android.pop 2>/dev/null
rm -rf /system/app/com.estrongs.android.pop 2>/dev/null
mount -o remount,ro /system 2>/dev/null

# Удаляем из data
rm -rf /data/app/com.estrongs.android.pop* 2>/dev/null
rm -rf /data/data/com.estrongs.android.pop 2>/dev/null

# Удаляем через pm
pm uninstall com.estrongs.android.pop 2>/dev/null

# Сохраняем лог на флешку
cp "$LOG" /update/es_removed.log 2>/dev/null

sync
echo "ES удален. Перезагрузите устройство." >> $LOG
echo "✅ ES File Explorer удален!"