# ==================================================
# УСТАНОВКА ES FILE EXPLORER - ИСПРАВЛЕННАЯ ВЕРСИЯ
# Версия: 2.0
# ==================================================

# Переменные
LOG_FILE="/storage/B4FE-5315/es_installation_$(date +%Y%m%d_%H%M%S).log"
APK_PATH=""
USB_PATH=""
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Функция логирования
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Функция проверки статуса монтирования
check_mount_status() {
    if mount | grep -q " /system .* rw,"; then
        return 0  # RW режим
    else
        return 1  # RO режим
    fi
}

# Функция монтирования системы
mount_system_rw() {
    log "Попытка монтирования системы в RW режим..."
    
    # Сначала проверяем текущий статус
    if check_mount_status; then
        log "✅ Система уже в RW режиме"
        return 0
    fi
    
    # Получаем реальный блок-девайс
    SYSTEM_DEVICE=$(mount | grep " / " | awk '{print $1}')
    if [ -z "$SYSTEM_DEVICE" ]; then
        SYSTEM_DEVICE=$(mount | grep " /system " | awk '{print $1}')
    fi
    
    log "Обнаружен системный девайс: $SYSTEM_DEVICE"
    
    # Способы монтирования (в порядке вероятности успеха)
    # Способ 1: Для Android 10+ с динамическими разделами
    if [ -n "$SYSTEM_DEVICE" ]; then
        log "Попытка 1: mount -o rw,remount $SYSTEM_DEVICE /"
        mount -o rw,remount "$SYSTEM_DEVICE" / 2>/dev/null
        if check_mount_status; then
            log "✅ Система смонтирована в RW (способ 1)"
            return 0
        fi
    fi
    
    # Способ 2: Классический метод
    log "Попытка 2: mount -o rw,remount /system"
    mount -o rw,remount /system 2>/dev/null
    if check_mount_status; then
        log "✅ Система смонтирована в RW (способ 2)"
        return 0
    fi
    
    # Способ 3: Через busybox
    log "Попытка 3: busybox mount -o remount,rw /system"
    busybox mount -o remount,rw /system 2>/dev/null
    if check_mount_status; then
        log "✅ Система смонтирована в RW (способ 3)"
        return 0
    fi
    
    # Способ 4: Прямое монтирование корня
    log "Попытка 4: mount -o rw,remount /"
    mount -o rw,remount / 2>/dev/null
    if check_mount_status; then
        log "✅ Система смонтирована в RW (способ 4)"
        return 0
    fi
    
    # Способ 5: Через /dev/block
    for block in /dev/block/dm-* /dev/block/by-name/system*; do
        if [ -e "$block" ]; then
            log "Попытка 5: mount -o rw,remount $block /"
            mount -o rw,remount "$block" / 2>/dev/null
            if check_mount_status; then
                log "✅ Система смонтирована в RW через $block"
                return 0
            fi
        fi
    done
    
    log "❌ НЕ УДАЛОСЬ смонтировать систему в RW режим"
    return 1
}

# ========== ОСНОВНАЯ ПРОГРАММА ==========

log "=================================================="
log "УСТАНОВКА ES FILE EXPLORER - ИСПРАВЛЕННАЯ ВЕРСИЯ"
log "Время начала: $(date)"
log "User: $(id)"
log "=================================================="

# ШАГ 1: ПОИСК USB ФЛЕШКИ
log ""
log "=== ШАГ 1: ПОИСК USB ФЛЕШКИ ==="
log "Поиск USB флешки с ES File Explorer..."

# Массив путей для проверки
USB_PATHS="/mnt/media_rw /storage /mnt"

for path in $USB_PATHS; do
    if [ -d "$path" ]; then
        log "Проверяю: $path"
        # Ищем APK файл
        found_apk=$(find "$path" -type f -name "*.apk" 2>/dev/null | grep -i "es" | head -n1)
        if [ -n "$found_apk" ]; then
            APK_PATH="$found_apk"
            USB_PATH=$(echo "$found_apk" | sed 's|/update/soft/.*' | sed 's|/storage/.*' || echo "$found_apk" | cut -d'/' -f1-3)
            log "  ✓ Найден: $found_apk"
            break
        fi
    fi
done

if [ -z "$APK_PATH" ]; then
    log "❌ ES File Explorer не найден на USB флешке"
    log "Пожалуйста, убедитесь, что файл es.apk находится в папке /update/soft/"
    exit 1
fi

log ""
log "✅ USB ФЛЕШКА УСПЕШНО ОБНАРУЖЕНА!"
log "  Путь к APK: $APK_PATH"
log "  Размер: $(du -h "$APK_PATH" | cut -f1)"
log "  Права: $(ls -l "$APK_PATH" | awk '{print $1}')"
[08.09.2026 22:01] DEMOLISHER: # ШАГ 2: ПРОВЕРКА СИСТЕМЫ
log ""
log "=== ШАГ 2: АНАЛИЗ СИСТЕМЫ ==="

# Проверяем доступные директории
SYSTEM_DIRS=""
if [ -d "/system/priv-app" ]; then
    SYSTEM_DIRS="$SYSTEM_DIRS priv-app"
    log "  /system/priv-app: существует"
fi
if [ -d "/system/app" ]; then
    SYSTEM_DIRS="$SYSTEM_DIRS app"
    log "  /system/app: существует"
fi
if [ -d "/system/product/app" ]; then
    SYSTEM_DIRS="$SYSTEM_DIRS product/app"
    log "  /system/product/app: существует"
fi

# Выбираем целевую директорию
if [ -d "/system/priv-app" ]; then
    TARGET_DIR="/system/priv-app/ESFileExplorer"
    log "Выбрано: /system/priv-app (привилегированные права)"
else
    TARGET_DIR="/system/app/ESFileExplorer"
    log "Выбрано: /system/app (стандартная установка)"
fi

# ШАГ 3: МОНТИРОВАНИЕ И УСТАНОВКА
log ""
log "=== ШАГ 3: УСТАНОВКА ==="

# Сначала проверяем, можно ли установить как обычное приложение (альтернативный вариант)
log "Проверка возможности установки через pm install..."
pm install -r "$APK_PATH" 2>/dev/null
if [ $? -eq 0 ]; then
    log "✅ Установка через pm install выполнена успешно!"
    log "ES File Explorer установлен как обычное приложение"
    log "Информация о пакете:"
    pm list packages | grep -i "esfile" | tee -a "$LOG_FILE"
    exit 0
else
    log "⚠️ Установка через pm install не удалась, пробуем установку в систему..."
fi

# Пытаемся смонтировать систему
if ! mount_system_rw; then
    log "❌ НЕВОЗМОЖНО ПРОДОЛЖИТЬ: система не монтируется в RW режим"
    log "Рекомендация: перезагрузите устройство и попробуйте снова"
    log "Или используйте Magisk модуль для системных приложений"
    exit 1
fi

# Создаем директорию
log "Создание структуры папок..."
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
        log "❌ Ошибка создания директории $TARGET_DIR"
        log "Даже после монтирования система осталась RO"
        log "Текущий статус монтирования:"
        mount | grep " /system " | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Копируем APK
log "Копирование APK в систему..."
cp "$APK_PATH" "$TARGET_DIR/es.apk" 2>/dev/null
if [ $? -ne 0 ]; then
    log "❌ Ошибка копирования APK"
    exit 1
fi

# Устанавливаем права
log "Установка прав доступа..."
chmod 644 "$TARGET_DIR/es.apk" 2>/dev/null
chcon u:object_r:system_file:s0 "$TARGET_DIR/es.apk" 2>/dev/null

# Синхронизация
log "Синхронизация изменений..."
sync

log ""
log "✅ УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА!"
log "  Путь: $TARGET_DIR/es.apk"
log "  Права: $(ls -l "$TARGET_DIR/es.apk")"
log ""

# Инструкции для пользователя
log "=== ИНСТРУКЦИИ ==="
log "1. Перезагрузите устройство для применения изменений"
log "2. После перезагрузки ES File Explorer будет доступен"
log "3. Если приложение не появилось, установите вручную:"
log "   pm install $TARGET_DIR/es.apk"

log ""
log "=================================================="
log "Лог сохранен в: $LOG_FILE"
log "=================================================="
