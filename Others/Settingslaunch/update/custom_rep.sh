#!/system/bin/sh

log -p e -t FIX "Starting Settings launch sequence"

# Вариант 1: Запуск стандартных настроек Android
am start -a android.settings.SETTINGS

# Ждем 2 секунды и проверяем
sleep 2

# Вариант 2: Альтернативный способ запуска настроек
am start -n com.android.settings/.Settings

# Ждем 2 секунды
sleep 2

# Вариант 3: Универсальный запуск
am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n com.android.settings/.Settings

log -p e -t FIX "Settings launch completed"