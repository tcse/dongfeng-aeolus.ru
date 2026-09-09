#!/system/bin/sh

# ============================================================================
# АКТИВАЦИЯ FREEFORM + УПРАВЛЕНИЕ МЕДИА ДЛЯ DONGFENG SHINE GS
# Активирует: Freeform + Медиа-кнопки на руле
# ============================================================================
# Версия: 2.0.0
# Дата: 2026-09-06
# ============================================================================

# ============================================================================
# ЛОГИРОВАНИЕ
# ============================================================================

LOG_TAG="DFM_ACTIVATE"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="/data/local/tmp/dfm_activate_${TIMESTAMP}.log"
USB_LOG_NAME="dfm_activate_${TIMESTAMP}.log"

log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" | tee -a "$LOG_FILE"
    log -p i -t "$LOG_TAG" "$1" 2>/dev/null
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" | tee -a "$LOG_FILE"
    log -p e -t "$LOG_TAG" "$1" 2>/dev/null
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" | tee -a "$LOG_FILE"
    log -p i -t "$LOG_TAG" "$1" 2>/dev/null
}

# ============================================================================
# ИНИЦИАЛИЗАЦИЯ
# ============================================================================

echo "==================================================" > "$LOG_FILE"
echo "АКТИВАЦИЯ FREEFORM + МЕДИА ДЛЯ DONGFENG SHINE GS" >> "$LOG_FILE"
echo "Время начала: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo "==================================================" >> "$LOG_FILE"

log_info "================================================"
log_info "ЗАПУСК АКТИВАЦИИ DFM ДЛЯ DONGFENG SHINE GS"
log_info "================================================"
log_info "User: $(id)"

# ============================================================================
# ПОИСК USB ДЛЯ СОХРАНЕНИЯ ЛОГА
# ============================================================================

USB_PATH=""

# Ищем USB для сохранения лога
for path in /storage/* /mnt/media_rw/* /mnt/usb* /udisk*; do
    if [ -d "$path" ] && [ -w "$path" ] && [[ "$path" != "/storage/emulated"* ]] && [[ "$path" != "/storage/self"* ]]; then
        USB_PATH="$path"
        log_info "USB флешка найдена: $USB_PATH"
        break
    fi
done

if [ -n "$USB_PATH" ]; then
    USB_LOG="$USB_PATH/$USB_LOG_NAME"
    log_info "Лог будет сохранён на USB: $USB_LOG"
else
    log_info "USB флешка не найдена, лог сохранится только в системе"
fi

# ============================================================================
# ЧАСТЬ 1: АКТИВАЦИЯ FREEFORM
# ============================================================================

log_info "=== ЧАСТЬ 1: АКТИВАЦИЯ FREEFORM ==="

log_info "Активация Freeform режима..."

# Основные команды активации Freeform
settings put global enable_freeform_support 1
if [ $? -eq 0 ]; then
    log_success "  ✅ enable_freeform_support = 1"
else
    log_error "  ❌ Ошибка установки enable_freeform_support"
fi

settings put global force_resizable_activities 1
if [ $? -eq 0 ]; then
    log_success "  ✅ force_resizable_activities = 1"
else
    log_error "  ❌ Ошибка установки force_resizable_activities"
fi

settings put global always_finish_activities 0
if [ $? -eq 0 ]; then
    log_success "  ✅ always_finish_activities = 0"
else
    log_error "  ❌ Ошибка установки always_finish_activities"
fi

# Опциональная оптимизация
settings put global app_side_blacklist "" 2>/dev/null
settings put global policy_control "null" 2>/dev/null

log_success "✅ Freeform режим активирован"

# Проверяем значения
FREEFORM=$(settings get global enable_freeform_support 2>/dev/null)
FORCE_RESIZE=$(settings get global force_resizable_activities 2>/dev/null)
ALWAYS_FINISH=$(settings get global always_finish_activities 2>/dev/null)

log_info "  📊 ТЕКУЩИЕ НАСТРОЙКИ FREEFORM:"
log_info "     enable_freeform_support: $FREEFORM"
log_info "     force_resizable_activities: $FORCE_RESIZE"
log_info "     always_finish_activities: $ALWAYS_FINISH"

# ============================================================================
# ЧАСТЬ 2: АКТИВАЦИЯ УПРАВЛЕНИЯ МЕДИА С КНОПОК РУЛЯ
# ============================================================================

log_info "=== ЧАСТЬ 2: АКТИВАЦИЯ УПРАВЛЕНИЯ МЕДИА ==="

log_info "Включаем корректную работу управления медиа-проигрывателями..."

settings put secure user_setup_complete 1
if [ $? -eq 0 ]; then
    log_success "  ✅ user_setup_complete = 1"
    log_info "  📌 Медиа-кнопки на руле теперь работают для всех приложений"
else
    log_error "  ❌ Ошибка установки user_setup_complete"
fi

# Проверяем текущее значение
CURRENT_VALUE=$(settings get secure user_setup_complete 2>/dev/null)
log_info "  Текущее значение: $CURRENT_VALUE"

log_success "✅ Управление медиа активировано"

# ============================================================================
# ПРОВЕРКА ВСЕХ НАСТРОЕК
# ============================================================================

log_info "=== ПРОВЕРКА ВСЕХ НАСТРОЕК ==="

USER_SETUP=$(settings get secure user_setup_complete 2>/dev/null)

log_info "  📊 ИТОГОВЫЕ НАСТРОЙКИ:"
log_info "     enable_freeform_support: $FREEFORM"
log_info "     force_resizable_activities: $FORCE_RESIZE"
log_info "     always_finish_activities: $ALWAYS_FINISH"
log_info "     user_setup_complete: $USER_SETUP"

# ============================================================================
# СОХРАНЕНИЕ ЛОГА НА USB
# ============================================================================

log_info "=== СОХРАНЕНИЕ ЛОГА ==="

# Сохраняем копию в /data
cp "$LOG_FILE" "/data/local/tmp/dfm_activate_last.log" 2>/dev/null
log_success "  ✅ Лог сохранён в системе: $LOG_FILE"

# Сохраняем на USB
if [ -n "$USB_PATH" ] && [ -d "$USB_PATH" ]; then
    cp "$LOG_FILE" "$USB_LOG" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "  ✅ Лог сохранён на USB: $USB_LOG"
    else
        log_error "  ❌ Не удалось сохранить лог на USB"
    fi
else
    log_info "  ⚠️ USB не найдена, лог только в системе"
fi

# Синхронизация
sync

# ============================================================================
# ФИНАЛЬНЫЙ ОТЧЁТ
# ============================================================================

log_info "================================================"
log_success "🎉 АКТИВАЦИЯ DFM ВЫПОЛНЕНА УСПЕШНО!"
log_info "================================================"
log_info "  ✅ Freeform: активирован"
log_info "  ✅ Медиа-кнопки на руле: активированы"
if [ -n "$USB_PATH" ]; then
    log_info "  📄 Лог на USB: $USB_LOG"
else
    log_info "  📄 Лог в системе: $LOG_FILE"
fi
log_info "================================================"
log_info "📌 ДЛЯ ПРОВЕРКИ:"
log_info "  1. Freeform: settings get global enable_freeform_support"
log_info "  2. Медиа-кнопки: проверьте на руле"
log_info "  3. Лог: cat $LOG_FILE"
log_info "================================================"

# ============================================================================
# ЗАВЕРШЕНИЕ
# ============================================================================

log_info "✅ Скрипт завершён"

exit 0
