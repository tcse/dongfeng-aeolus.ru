#!/system/bin/sh

log -p e -t DFM "=== DFM-Sidebar Auto-Start Script ==="
log -p e -t DFM "Starting DFM-Sidebar launch sequence"

# ============================================================
# ВАРИАНТ 1: Запуск через полное имя Activity (рекомендуемый)
# ============================================================
log -p e -t DFM "Attempt 1: Launch via full Activity name"

# Запускаем MainActivity
am start -n com.example.dfmsidebar/.MainActivity

# Ждем 1 секунду
sleep 1

# ============================================================
# ВАРИАНТ 2: Запуск через пакет и Activity (альтернативный)
# ============================================================
log -p e -t DFM "Attempt 2: Launch via package and activity"

am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n com.example.dfmsidebar/.MainActivity

# Ждем 1 секунду
sleep 1

# ============================================================
# ВАРИАНТ 3: Универсальный запуск (если Activity не найдена)
# ============================================================
log -p e -t DFM "Attempt 3: Universal launch"

am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER com.example.dfmsidebar

# Ждем 1 секунду
sleep 1

# ============================================================
# ВАРИАНТ 4: Запуск SidebarService напрямую
# ============================================================
log -p e -t DFM "Attempt 4: Start SidebarService directly"

am startservice -n com.example.dfmsidebar/.SidebarService

# Ждем 1 секунду
sleep 1

# ============================================================
# ВАРИАНТ 5: Запуск через broadcast intent
# ============================================================
log -p e -t DFM "Attempt 5: Broadcast intent"

am broadcast -a android.intent.action.BOOT_COMPLETED -p com.example.dfmsidebar

# ============================================================
# ПРОВЕРКА: Запущен ли сервис
# ============================================================
log -p e -t DFM "Checking if SidebarService is running..."

# Проверяем через dumpsys
SERVICE_CHECK=$(dumpsys activity services com.example.dfmsidebar/.SidebarService | grep "ServiceRecord")

if [ -n "$SERVICE_CHECK" ]; then
    log -p e -t DFM "✅ SidebarService is running!"
else
    log -p e -t DFM "❌ SidebarService is NOT running - trying fallback"
    
    # Фолбэк: запускаем через monkey (системный утилита)
    monkey -p com.example.dfmsidebar -c android.intent.category.LAUNCHER 1
fi

# ============================================================
# ЗАВЕРШЕНИЕ
# ============================================================
log -p e -t DFM "=== DFM-Sidebar launch sequence completed ==="
log -p e -t DFM "Check if app is now running"

# Выводим информацию о пакете для отладки
log -p e -t DFM "Package info:"
dumpsys package com.example.dfmsidebar | grep -E "versionName|versionCode" | while read line; do
    log -p e -t DFM "$line"
done

exit 0
