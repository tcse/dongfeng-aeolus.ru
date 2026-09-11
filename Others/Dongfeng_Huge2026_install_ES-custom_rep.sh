#!/system/bin/sh
# ============================================================================
# УНИВЕРСАЛЬНЫЙ УСТАНОВЩИК ES FILE EXPLORER
# Версия: 3.0
# Поддержка: Android 8.1 (Shine, Shine GS, Box, Mage) + Android 10 (Huge)
# ============================================================================
# Проект: Автоматическая установка приложений на магнитолы Dongfeng Aeolus
# Форум: https://dongfeng-aeolus.ru/community/topicid/422/
# Телеграм: https://t.me/aeolusshinegs
# Репозиторий: https://github.com/tcse/dongfeng-aeolus.ru
# Лицензия: GNU GPLv3
# ============================================================================

# ========== ИНИЦИАЛИЗАЦИЯ ЛОГА (во внутренней памяти!) ==========
LOG_FILE="/data/local/tmp/es_install_$(date +%Y%m%d_%H%M%S).log"
USB_LOG=""
APK_PATH=""
USB_PATH=""
TARGET_DIR=""
INSTALL_SUCCESS=false

# Функция логирования (с актуальным временем)
log() {
    TS=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$TS] $1" | tee -a "$LOG_FILE"
    [ -n "$USB_LOG" ] && echo "[$TS] $1" >> "$USB_LOG" 2>/dev/null
    return 0
}

# ============================================================================
# БЛОК 1: ПОИСК USB ФЛЕШКИ С APK
# ============================================================================
find_usb_apk() {
    log "Поиск USB флешки с es.apk..."

    # Приоритетные пути (в порядке вероятности)
    for base in /mnt/media_rw /storage /mnt; do
        [ -d "$base" ] || continue

        # Перебираем все подпапки в base
        for sub in "$base"/*; do
            [ -d "$sub" ] || continue

            # Пропускаем внутреннюю память и системные папки
            case "$sub" in
                */emulated*|*/self*|*/sdcard*|*/0) continue ;;
            esac

            # 1a. Приоритетный путь: update/soft/es.apk
            if [ -f "$sub/update/soft/es.apk" ]; then
                APK_PATH="$sub/update/soft/es.apk"
                USB_PATH="$sub"
                return 0
            fi

            # 1b. Просто es.apk в корне флешки
            if [ -f "$sub/es.apk" ]; then
                APK_PATH="$sub/es.apk"
                USB_PATH="$sub"
                return 0
            fi

            # 1c. Любой *.apk с "es" в имени (регистронезависимо)
            for f in "$sub"/*.apk "$sub"/*/*.apk; do
                [ -f "$f" ] || continue
                fname=$(basename "$f" | tr 'A-Z' 'a-z')
                case "$fname" in
                    *es*.apk)
                        APK_PATH="$f"
                        USB_PATH=$(dirname "$f")
                        return 0
                        ;;
                esac
            done
        done
    done
    return 1
}

# ============================================================================
# БЛОК 2: ПРОВЕРКА СТАТУСА МОНТИРОВАНИЯ
# ============================================================================
check_mount_status() {
    # Проверяем: либо overlay на /system, либо реальный rw-remount
    if mount | grep -qE "overlay on /system| /system .* rw,"; then
        return 0  # RW доступен
    fi
    # Дополнительная проверка — пробуем записать
    if touch /system/.rw_test 2>/dev/null; then
        rm -f /system/.rw_test 2>/dev/null
        return 0
    fi
    return 1
}

# ============================================================================
# БЛОК 3: МОНТИРОВАНИЕ /system В RW (overlay для Android 10 + fallbacks)
# ============================================================================
mount_system_rw() {
    log "Попытка монтирования /system в RW..."

    # Уже RW?
    if check_mount_status; then
        log "✅ /system уже доступен для записи"
        return 0
    fi

    # --- Способ 1: overlay (правильный для Android 10) ---
    log "Попытка 1: overlay lowerdir=/system,upperdir=/data/overlay/upper"
    mkdir -p /data/overlay/upper /data/overlay/work 2>/dev/null
    mount -t overlay overlay \
        -o lowerdir=/system,upperdir=/data/overlay/upper,workdir=/data/overlay/work \
        /system >> "$LOG_FILE" 2>&1
    if check_mount_status; then
        log "✅ overlay смонтирован"
        return 0
    fi
    log "✗ overlay не сработал"

    # --- Способ 2: remount по реальному блочному устройству ---
    SYS_DEV=$(mount | awk '$3=="/system"{print $1; exit}')
    [ -z "$SYS_DEV" ] && SYS_DEV=$(mount | awk '$3=="/"{print $1; exit}')

    if [ -n "$SYS_DEV" ]; then
        log "Попытка 2: mount -o rw,remount $SYS_DEV /"
        mount -o rw,remount "$SYS_DEV" / >> "$LOG_FILE" 2>&1
        if check_mount_status; then
            log "✅ remount удался через $SYS_DEV"
            return 0
        fi
        log "✗ remount через $SYS_DEV не сработал"
    fi

    # --- Способ 3: dm-3 (динамический раздел Android 10) ---
    for blk in /dev/block/dm-3 /dev/block/dm-2 /dev/block/dm-1; do
        [ -e "$blk" ] || continue
        log "Попытка 3: mount -o rw,remount $blk /"
        mount -o rw,remount "$blk" / >> "$LOG_FILE" 2>&1
        if check_mount_status; then
            log "✅ remount удался через $blk"
            return 0
        fi
    done

    # --- Способ 4: by-name/system ---
    for blk in /dev/block/by-name/system /dev/block/by-name/system_a /dev/block/by-name/system_b; do
        [ -e "$blk" ] || continue
        log "Попытка 4: mount -o rw,remount $blk /"
        mount -o rw,remount "$blk" / >> "$LOG_FILE" 2>&1
        if check_mount_status; then
            log "✅ remount удался через $blk"
            return 0
        fi
    done

    # --- Способ 5: классический /system ---
    log "Попытка 5: mount -o remount,rw /system"
    mount -o remount,rw /system >> "$LOG_FILE" 2>&1
    if check_mount_status; then
        log "✅ remount через /system удался"
        return 0
    fi

    # --- Способ 6: busybox ---
    log "Попытка 6: busybox mount -o remount,rw /system"
    busybox mount -o remount,rw /system >> "$LOG_FILE" 2>&1
    if check_mount_status; then
        log "✅ busybox remount удался"
        return 0
    fi

    # --- Способ 7: remount / ---
    log "Попытка 7: mount -o rw,remount /"
    mount -o rw,remount / >> "$LOG_FILE" 2>&1
    if check_mount_status; then
        log "✅ remount / удался"
        return 0
    fi

    log "❌ ВСЕ СПОСОБЫ МОНТИРОВАНИЯ НЕ СРАБОТАЛИ"
    log "Текущее состояние монтирования:"
    mount | grep -E " /system | / " >> "$LOG_FILE" 2>&1
    return 1
}

# ============================================================================
# ОСНОВНАЯ ПРОГРАММА
# ============================================================================

log "=================================================="
log "УСТАНОВКА ES FILE EXPLORER v3.0"
log "Время начала: $(date '+%Y-%m-%d %H:%M:%S')"
log "User: $(id)"
log "Скрипт запущен из: $0"
log "=================================================="

# ---------------------------------------------------------------------------
# ШАГ 1: ПОИСК USB ФЛЕШКИ
# ---------------------------------------------------------------------------
log ""
log "=== ШАГ 1: ПОИСК USB ФЛЕШКИ ==="

if ! find_usb_apk; then
    log "❌ КРИТИЧЕСКАЯ ОШИБКА: es.apk не найден на USB!"
    log ""
    log "ДИАГНОСТИКА:"
    log "1. Подключенные устройства хранения:"
    df -h 2>&1 | grep -E "/storage|/mnt|/udisk|/media" >> "$LOG_FILE"
    log "2. Содержимое /storage:"
    ls -la /storage/ >> "$LOG_FILE" 2>&1
    log "3. Содержимое /mnt:"
    ls -la /mnt/ >> "$LOG_FILE" 2>&1
    log "4. Содержимое /mnt/media_rw:"
    ls -la /mnt/media_rw/ >> "$LOG_FILE" 2>&1
    log ""
    log "РЕКОМЕНДАЦИИ:"
    log "  - Убедитесь, что USB флешка подключена"
    log "  - Файл должен быть: /update/soft/es.apk или /es.apk"
    log "  - Проверьте, что флешка не смонтирована как /storage/emulated"
    exit 1
fi

# Флешка найдена — теперь можно создать лог на ней
USB_LOG="$USB_PATH/es_install_$(date +%Y%m%d_%H%M%S).log"
cp "$LOG_FILE" "$USB_LOG" 2>/dev/null

log ""
log "✅ USB ФЛЕШКА ОБНАРУЖЕНА!"
log "  Путь к флешке: $USB_PATH"
log "  Файл APK: $APK_PATH"

if [ -f "$APK_PATH" ]; then
    FILE_INFO=$(ls -lh "$APK_PATH" 2>/dev/null)
    FILE_SIZE=$(echo "$FILE_INFO" | awk '{print $5}')
    FILE_PERM=$(echo "$FILE_INFO" | awk '{print $1}')
    log "  Размер: $FILE_SIZE"
    log "  Права: $FILE_PERM"
fi

# ---------------------------------------------------------------------------
# ШАГ 2: АНАЛИЗ СИСТЕМЫ
# ---------------------------------------------------------------------------
log ""
log "=== ШАГ 2: АНАЛИЗ СИСТЕМЫ ==="

if [ -d "/system/priv-app" ]; then
    PRIVAPP_COUNT=$(ls -d /system/priv-app/* 2>/dev/null | wc -l)
    log "  /system/priv-app: существует ($PRIVAPP_COUNT приложений)"
fi
if [ -d "/system/app" ]; then
    APP_COUNT=$(ls -d /system/app/* 2>/dev/null | wc -l)
    log "  /system/app: существует ($APP_COUNT приложений)"
fi
if [ -d "/system/product/app" ]; then
    log "  /system/product/app: существует"
fi

# Выбор целевой директории
if [ -d "/system/priv-app" ]; then
    TARGET_DIR="/system/priv-app/ESFileExplorer"
    log "  Выбрано: /system/priv-app (привилегированные права)"
elif [ -d "/system/app" ]; then
    TARGET_DIR="/system/app/ESFileExplorer"
    log "  Выбрано: /system/app"
else
    log "❌ Нет доступных системных директорий!"
    exit 1
fi
log "  Целевая папка: $TARGET_DIR"

# Проверка существующей установки
log ""
log "Проверка существующей установки:"
EXISTING_PATHS=(
    "/system/priv-app/ESFileExplorer"
    "/system/priv-app/ES"
    "/system/priv-app/es"
    "/system/priv-app/com.estrongs.android.pop"
    "/system/app/ESFileExplorer"
    "/system/app/ES"
    "/system/app/es"
    "/system/app/com.estrongs.android.pop"
    "/system/product/app/ESFileExplorer"
    "/system/product/app/com.estrongs.android.pop"
)
FOUND_EXISTING=false
for ep in "${EXISTING_PATHS[@]}"; do
    if [ -d "$ep" ]; then
        log "  ⚠ Найдена установка: $ep"
        FOUND_EXISTING=true
    fi
done
[ "$FOUND_EXISTING" = false ] && log "  Существующая установка не обнаружена"

# ---------------------------------------------------------------------------
# ШАГ 3: УСТАНОВКА
# ---------------------------------------------------------------------------
log ""
log "=== ШАГ 3: УСТАНОВКА ==="

# --- 3.1. Сначала пробуем обычную установку через pm install ---
log ""
log "Попытка 1: pm install (не требует RW на /system)"
pm install -r "$APK_PATH" >> "$LOG_FILE" 2>&1
PM_RESULT=$?

if [ $PM_RESULT -eq 0 ]; then
    log "✅ ES установлен через pm install!"
    log "   Пакет: $(pm list packages 2>/dev/null | grep estrongs)"
    INSTALL_SUCCESS=true

    # Дополнительно: пробуем сделать системным (если получится — отлично)
    log ""
    log "Попытка сделать приложение системным (опционально)..."
    if mount_system_rw; then
        mkdir -p "$TARGET_DIR" 2>/dev/null
        cp "$APK_PATH" "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null
        if [ -f "$TARGET_DIR/ESFileExplorer.apk" ]; then
            chmod 755 "$TARGET_DIR" 2>/dev/null
            chmod 644 "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null
            chown system:system "$TARGET_DIR" 2>/dev/null
            chown system:system "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null
            chcon u:object_r:system_file:s0 "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null || true
            log "✅ APK также скопирован в $TARGET_DIR"
        fi
        mount -o remount,ro /system 2>/dev/null
    else
        log "ℹ️ Системная установка не удалась — оставляем как пользовательское"
    fi
else
    log "⚠️ pm install не сработал (код: $PM_RESULT)"
    log "Переходим к системной установке..."

    # --- 3.2. Системная установка ---
    if ! mount_system_rw; then
        log "❌ Система не монтируется в RW. Установка невозможна."
        log ""
        log "ВОЗМОЖНЫЕ РЕШЕНИЯ:"
        log "  1. Устройство с Magisk — установите модуль 'System RW'"
        log "  2. Перезагрузите устройство и запустите скрипт снова"
        log "  3. Используйте pm install (установка как пользовательское)"
        cp "$LOG_FILE" "$USB_LOG" 2>/dev/null
        sync
        exit 1
    fi

    # Финальная проверка записи
    if ! touch /system/.rw_test 2>/dev/null; then
        log "❌ /system всё ещё только для чтения. Отмена."
        cp "$LOG_FILE" "$USB_LOG" 2>/dev/null
        sync
        exit 1
    fi
    rm -f /system/.rw_test 2>/dev/null

    # Удаление старых версий
    log "Очистка предыдущих установок..."
    for ep in "${EXISTING_PATHS[@]}"; do
        if [ -d "$ep" ]; then
            log "  Удаляю: $ep"
            rm -rf "$ep" >> "$LOG_FILE" 2>&1
        fi
    done

    # Создание структуры
    log "Создание: $TARGET_DIR"
    mkdir -p "$TARGET_DIR" 2>/dev/null
    if [ ! -d "$TARGET_DIR" ]; then
        log "❌ Не удалось создать $TARGET_DIR"
        cp "$LOG_FILE" "$USB_LOG" 2>/dev/null
        sync
        exit 1
    fi

    # OAT-директории
    for arch in arm arm64 x86 x86_64; do
        mkdir -p "$TARGET_DIR/oat/$arch" 2>/dev/null
    done

    # Копирование APK
    log "Копирование APK..."
    cp "$APK_PATH" "$TARGET_DIR/ESFileExplorer.apk" >> "$LOG_FILE" 2>&1
    if [ ! -f "$TARGET_DIR/ESFileExplorer.apk" ]; then
        log "❌ Ошибка копирования APK"
        mount -o remount,ro /system 2>/dev/null
        cp "$LOG_FILE" "$USB_LOG" 2>/dev/null
        sync
        exit 1
    fi
    log "✅ APK скопирован ($(ls -lh "$TARGET_DIR/ESFileExplorer.apk" | awk '{print $5}'))"

    # Права
    log "Установка прав..."
    chmod 755 "$TARGET_DIR" 2>/dev/null
    chmod 644 "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null
    for arch in arm arm64 x86 x86_64; do
        chmod 755 "$TARGET_DIR/oat" 2>/dev/null
        chmod 755 "$TARGET_DIR/oat/$arch" 2>/dev/null
    done

    # Владелец
    if [[ "$TARGET_DIR" == "/system/priv-app/"* ]]; then
        chown system:system "$TARGET_DIR" 2>/dev/null
        chown system:system "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null
        chown system:system "$TARGET_DIR/oat" 2>/dev/null
        log "  Владелец: system:system"
    else
        chown root:root "$TARGET_DIR" 2>/dev/null
        chown root:root "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null
        chown root:root "$TARGET_DIR/oat" 2>/dev/null
        log "  Владелец: root:root"
    fi

    # SELinux контекст
    chcon u:object_r:system_file:s0 "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null || true
    chcon u:object_r:system_file:s0 "$TARGET_DIR" 2>/dev/null || true

    # Регистрация через pm
    log "Регистрация пакета через pm install..."
    pm install -r "$TARGET_DIR/ESFileExplorer.apk" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        log "✅ Пакет зарегистрирован"
        INSTALL_SUCCESS=true
    else
        log "⚠️ pm install не сработал — потребуется перезагрузка"
        INSTALL_SUCCESS=true  # всё равно считаем успехом, т.к. файл на месте
    fi

    # Возврат в RO
    log "Возврат /system в RO..."
    sync
    mount -o remount,ro /system 2>/dev/null
    if mount | grep -q " /system .* rw,"; then
        busybox mount -o remount,ro /system 2>/dev/null
    fi
    if mount | grep -q " /system .* rw,"; then
        log "⚠️ /system остался в RW — рекомендуется перезагрузка"
    else
        log "✅ /system возвращён в RO"
    fi
fi

# ---------------------------------------------------------------------------
# ШАГ 4: ПРОВЕРКА УСТАНОВКИ
# ---------------------------------------------------------------------------
log ""
log "=== ШАГ 4: ПРОВЕРКА ==="

if [ -f "$TARGET_DIR/ESFileExplorer.apk" ]; then
    FINAL_SIZE=$(ls -lh "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null | awk '{print $5}')
    FINAL_PERM=$(ls -la "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null | awk '{print $1}')
    FINAL_OWNER=$(ls -la "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null | awk '{print $3":"$4}')
    log "  ✅ Файл на месте: $TARGET_DIR/ESFileExplorer.apk"
    log "     Размер: $FINAL_SIZE | Права: $FINAL_PERM | Владелец: $FINAL_OWNER"
fi

PKG_CHECK=$(pm list packages 2>/dev/null | grep estrongs)
if [ -n "$PKG_CHECK" ]; then
    log "  ✅ Пакет зарегистрирован: $PKG_CHECK"
else
    log "  ⚠️ Пакет пока не виден — появится после перезагрузки"
fi

# ---------------------------------------------------------------------------
# ШАГ 5: ЗАВЕРШЕНИЕ
# ---------------------------------------------------------------------------
log ""
log "=== ШАГ 5: ЗАВЕРШЕНИЕ ==="

if [ "$INSTALL_SUCCESS" = true ]; then
    log "🎉 УСТАНОВКА ВЫПОЛНЕНА УСПЕШНО!"
else
    log "⚠️ УСТАНОВКА ЗАВЕРШИЛАСЬ С ПРОБЛЕМАМИ"
fi

log ""
log "📋 СВОДКА:"
log "  • Время: $(date '+%Y-%m-%d %H:%M:%S')"
log "  • USB: $USB_PATH"
log "  • APK: $(basename "$APK_PATH")"
log "  • Цель: $TARGET_DIR"
log "  • Статус: $(if [ "$INSTALL_SUCCESS" = true ]; then echo 'УСПЕХ'; else echo 'ПРОБЛЕМЫ'; fi)"

# Скрипт автозапуска
STARTUP_SCRIPT="/data/local/tmp/start_es.sh"
cat > "$STARTUP_SCRIPT" << 'STARTUP'
#!/system/bin/sh
echo "Запуск ES File Explorer..."
sleep 10
am start -n com.estrongs.android.pop/.view.FileExplorerActivity 2>/dev/null
sleep 2
am start -n com.estrongs.android.pop/.MainActivity 2>/dev/null
sleep 2
am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER \
    -n com.estrongs.android.pop/.view.FileExplorerActivity 2>/dev/null
sleep 15
am start -n com.estrongs.android.pop/.view.FileExplorerActivity 2>/dev/null
echo "ES File Explorer должен быть запущен"
STARTUP
chmod 755 "$STARTUP_SCRIPT" 2>/dev/null
log "  Скрипт автозапуска: $STARTUP_SCRIPT"

# Финальное сохранение лога
log ""
log "Сохранение лога на USB..."
cp "$LOG_FILE" "$USB_LOG" 2>/dev/null && log "✅ Лог сохранён: $USB_LOG" || log "⚠️ Не удалось сохранить лог на USB"

sync

log ""
log "🔄 ПОДГОТОВКА К ПЕРЕЗАГРУЗКЕ..."
log "⚠️ ВЫТАЩИТЕ ФЛЕШКУ во время перезагрузки, иначе скрипт запустится снова!"
log "Перезагрузка через 5 секунд..."

for i in 5 4 3 2 1; do
    log "  $i..."
    sleep 1
done

log "🚀 ПЕРЕЗАГРУЗКА..."
cp "$LOG_FILE" "$USB_LOG" 2>/dev/null
sync
reboot
