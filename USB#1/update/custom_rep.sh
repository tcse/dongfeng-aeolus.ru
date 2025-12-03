#!/system/bin/sh

# ============================================================================
# УНИВЕРСАЛЬНЫЙ УСТАНОВЩИК ES FILE EXPLORER (С ПОВТОРНЫМ ЗАПУСКОМ)
# Устанавливает ES File Explorer из папки update/soft/es.apk
# ============================================================================
# Проект: Автоматическая установка приложений на магнитолы Dongfeng Aeolus
# Форум: https://dongfeng-aeolus.ru/community/topicid/422/
# Телеграм: https://t.me/aeolusshinegs
# Репозиторий: https://github.com/tcse/dongfeng-aeolus.ru
# Авторы: Vitaly V. Chuyakov <vitaly@chuyakov.ru>, Deepseek AI
# Лицензия: GNU GPLv3
# Версия: 1.0.0
# Дата: 2025-12-03
# ===========================================================================

# Основной лог файл в системе
MAIN_LOG="/data/local/tmp/es_install.log"

echo "==================================================" > $MAIN_LOG
echo "УСТАНОВКА ES FILE EXPLORER - СЕССИЯ $(date '+%Y%m%d_%H%M%S')" >> $MAIN_LOG
echo "Время начала: $(date '+%Y-%m-%d %H:%M:%S')" >> $MAIN_LOG
echo "User: $(id)" >> $MAIN_LOG
echo "Скрипт запущен из: $0" >> $MAIN_LOG
echo "==================================================" >> $MAIN_LOG

# 1. АВТОМАТИЧЕСКИЙ ПОИСК USB ФЛЕШКИ
echo "" >> $MAIN_LOG
echo "=== ШАГ 1: ПОИСК USB ФЛЕШКИ ===" >> $MAIN_LOG

USB_PATH=""
APK_FILE=""

# Расширенный список путей для поиска
SEARCH_PATHS=(
    "/storage/usb" "/storage/usb0" "/storage/usb1" "/storage/usb2"
    "/storage/usb_storage" "/storage/sd" "/storage/sdcard"
    "/mnt/usb" "/mnt/usb0" "/mnt/usb1" "/mnt/usb_sd"
    "/mnt/udisk" "/mnt/udisk0" "/mnt/udisk1" "/mnt/sd"
    "/udisk" "/udisk0" "/udisk1"
    "/media" "/media_rw" "/mnt/media_rw"
    "/storage" "/mnt"  # Общие пути
)

echo "Поиск USB флешки с ES File Explorer..." >> $MAIN_LOG
echo "Проверяемые пути:" >> $MAIN_LOG

# Проверка стандартных путей
for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "  Проверяю: $path" >> $MAIN_LOG
        
        # Проверка различных вариантов расположения APK ES
        APK_LOCATIONS=(
            "$path/update/soft/es.apk"
            "$path/es.apk"
            "$path/ES.apk"
            "$path/es_file_explorer.apk"
            "$path/ES_File_Explorer.apk"
            "$path/ESFileExplorer.apk"
            "$path/APK/es.apk"
            "$path/apps/es.apk"
            "$path/install/es.apk"
            "$path/software/es.apk"
        )
        
        for apk_location in "${APK_LOCATIONS[@]}"; do
            if [ -f "$apk_location" ]; then
                USB_PATH="$path"
                APK_FILE="$apk_location"
                echo "    ✓ Найден: $apk_location" >> $MAIN_LOG
                break 2
            fi
        done
    fi
done

# Если не нашли, сканируем все /storage/*
if [ -z "$USB_PATH" ]; then
    echo "" >> $MAIN_LOG
    echo "Поиск во всех подключенных storage..." >> $MAIN_LOG
    
    for storage in /storage/*; do
        # Пропускаем внутреннюю память и специальные папки
        if [[ "$storage" == */emulated ]] || [[ "$storage" == */self ]] || 
           [[ "$storage" == */emulated/0 ]] || [[ "$storage" == */0 ]]; then
            continue
        fi
        
        if [ -d "$storage" ]; then
            echo "  Сканирую: $storage" >> $MAIN_LOG
            
            # Ищем es.apk в этой папке
            FOUND_APK=$(find "$storage" -name "es.apk" -type f 2>/dev/null | head -1)
            
            if [ -n "$FOUND_APK" ]; then
                USB_PATH="$storage"
                APK_FILE="$FOUND_APK"
                echo "    ✓ Найден: $FOUND_APK" >> $MAIN_LOG
                break
            fi
            
            # Ищем любые APK с ES в названии
            FOUND_ALT=$(find "$storage" -name "*es*" -name "*.apk" -type f 2>/dev/null | head -1)
            if [ -n "$FOUND_ALT" ]; then
                USB_PATH="$storage"
                APK_FILE="$FOUND_ALT"
                echo "    ✓ Найден альтернативный: $FOUND_ALT" >> $MAIN_LOG
                break
            fi
            
            # Специально для пути update/soft
            if [ -f "$storage/update/soft/es.apk" ]; then
                USB_PATH="$storage"
                APK_FILE="$storage/update/soft/es.apk"
                echo "    ✓ Найден в update/soft: $APK_FILE" >> $MAIN_LOG
                break
            fi
        fi
    done
fi

# Проверяем результат поиска
if [ -z "$USB_PATH" ] || [ -z "$APK_FILE" ]; then
    echo "" >> $MAIN_LOG
    echo "✗ КРИТИЧЕСКАЯ ОШИБКА: USB флешка с es.apk не найдена!" >> $MAIN_LOG
    echo "" >> $MAIN_LOG
    echo "ДИАГНОСТИКА:" >> $MAIN_LOG
    echo "1. Подключенные устройства хранения:" >> $MAIN_LOG
    df -h | grep -E "/storage|/mnt|/udisk|/sd|/media" >> $MAIN_LOG 2>&1
    
    echo "" >> $MAIN_LOG
    echo "2. Содержимое /storage:" >> $MAIN_LOG
    ls -la /storage/ >> $MAIN_LOG 2>&1
    
    echo "" >> $MAIN_LOG
    echo "3. Содержимое /mnt:" >> $MAIN_LOG
    ls -la /mnt/ >> $MAIN_LOG 2>&1
    
    echo "" >> $MAIN_LOG
    echo "4. Текущий каталог:" >> $MAIN_LOG
    pwd >> $MAIN_LOG
    ls -la >> $MAIN_LOG 2>&1
    
    echo "" >> $MAIN_LOG
    echo "5. Рекомендации:" >> $MAIN_LOG
    echo "   - Убедитесь что USB флешка подключена" >> $MAIN_LOG
    echo "   - На флешке должен быть файл es.apk" >> $MAIN_LOG
    echo "   - Предпочтительное расположение: update/soft/es.apk" >> $MAIN_LOG
    echo "   - Или можно положить в корень флешки" >> $MAIN_LOG
    
    exit 1
fi

echo "" >> $MAIN_LOG
echo "✅ USB ФЛЕШКА УСПЕШНО ОБНАРУЖЕНА!" >> $MAIN_LOG
echo "  Путь к флешке: $USB_PATH" >> $MAIN_LOG
echo "  Файл APK: $APK_FILE" >> $MAIN_LOG

# Получаем подробную информацию о файле
if [ -f "$APK_FILE" ]; then
    FILE_INFO=$(ls -lh "$APK_FILE" 2>/dev/null)
    FILE_SIZE=$(echo "$FILE_INFO" | awk '{print $5}')
    FILE_PERM=$(echo "$FILE_INFO" | awk '{print $1}')
    FILE_DATE=$(echo "$FILE_INFO" | awk '{print $6, $7, $8}')
    
    echo "  Размер файла: $FILE_SIZE" >> $MAIN_LOG
    echo "  Права доступа: $FILE_PERM" >> $MAIN_LOG
    echo "  Дата изменения: $FILE_DATE" >> $MAIN_LOG
    
    # Пытаемся получить информацию о пакете
    echo "" >> $MAIN_LOG
    echo "Информация о APK:" >> $MAIN_LOG
    if which aapt >/dev/null 2>&1; then
        PACKAGE_INFO=$(aapt dump badging "$APK_FILE" 2>/dev/null | head -5)
        echo "  $PACKAGE_INFO" | sed 's/^/  /' >> $MAIN_LOG
    else
        echo "  aapt не найден, пропускаем анализ APK" >> $MAIN_LOG
    fi
else
    echo "  ⚠ Предупреждение: Не удалось получить информацию о файле" >> $MAIN_LOG
fi

# Создаем лог на USB флешке
USB_LOG="$USB_PATH/es_installation_$(date '+%Y%m%d_%H%M%S').log"
echo "" >> $MAIN_LOG
echo "Лог на USB будет сохранен как: $USB_LOG" >> $MAIN_LOG

# Копируем начальную часть лога на USB
cp "$MAIN_LOG" "$USB_LOG" 2>/dev/null

# 2. АНАЛИЗ СИСТЕМЫ И ВЫБОР МЕСТА УСТАНОВКИ
echo "" >> $MAIN_LOG
echo "=== ШАГ 2: АНАЛИЗ СИСТЕМЫ ===" >> $MAIN_LOG

# Проверяем наличие системных папок
echo "Проверка системных директорий:" >> $MAIN_LOG

if [ -d "/system/priv-app" ]; then
    PRIVAPP_COUNT=$(ls -d /system/priv-app/* 2>/dev/null | wc -l)
    echo "  /system/priv-app: существует, содержит $PRIVAPP_COUNT приложений" >> $MAIN_LOG
else
    echo "  /system/priv-app: не существует" >> $MAIN_LOG
    PRIVAPP_COUNT=0
fi

if [ -d "/system/app" ]; then
    APP_COUNT=$(ls -d /system/app/* 2>/dev/null | wc -l)
    echo "  /system/app: существует, содержит $APP_COUNT приложений" >> $MAIN_LOG
else
    echo "  /system/app: не существует" >> $MAIN_LOG
    APP_COUNT=0
fi

if [ -d "/system/product/app" ]; then
    PRODUCTAPP_COUNT=$(ls -d /system/product/app/* 2>/dev/null | wc -l)
    echo "  /system/product/app: существует, содержит $PRODUCTAPP_COUNT приложений" >> $MAIN_LOG
else
    echo "  /system/product/app: не существует" >> $MAIN_LOG
    PRODUCTAPP_COUNT=0
fi

# Выбор целевой директории
echo "" >> $MAIN_LOG
echo "Выбор места установки:" >> $MAIN_LOG

# Предпочтение priv-app, затем app, затем product/app
if [ -d "/system/priv-app" ]; then
    TARGET_DIR="/system/priv-app/ESFileExplorer"
    echo "  Выбрано: system/priv-app" >> $MAIN_LOG
    echo "  Причина: привилегированные приложения имеют больше прав" >> $MAIN_LOG
elif [ -d "/system/app" ]; then
    TARGET_DIR="/system/app/ESFileExplorer"
    echo "  Выбрано: system/app" >> $MAIN_LOG
    echo "  Причина: стандартное расположение системных приложений" >> $MAIN_LOG
elif [ -d "/system/product/app" ]; then
    TARGET_DIR="/system/product/app/ESFileExplorer"
    echo "  Выбрано: system/product/app" >> $MAIN_LOG
    echo "  Причина: альтернативное расположение" >> $MAIN_LOG
else
    echo "  ✗ КРИТИЧЕСКАЯ ОШИБКА: Нет доступных системных директорий для установки!" >> $MAIN_LOG
    exit 1
fi

echo "  Целевая папка: $TARGET_DIR" >> $MAIN_LOG

# Проверяем, не установлен ли уже ES File Explorer
echo "" >> $MAIN_LOG
echo "Проверка существующей установки:" >> $MAIN_LOG

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
for existing_path in "${EXISTING_PATHS[@]}"; do
    if [ -d "$existing_path" ]; then
        echo "  ⚠ Обнаружена существующая установка: $existing_path" >> $MAIN_LOG
        echo "    Будет выполнена переустановка (замена)" >> $MAIN_LOG
        FOUND_EXISTING=true
        
        # Проверяем, активен ли пакет
        if pm list packages | grep -q "com.estrongs.android.pop"; then
            echo "    Пакет com.estrongs.android.pop активен в системе" >> $MAIN_LOG
        fi
    fi
done

if [ "$FOUND_EXISTING" = false ]; then
    echo "  Существующая установка не обнаружена" >> $MAIN_LOG
fi

# 3. ПРОЦЕСС УСТАНОВКИ
echo "" >> $MAIN_LOG
echo "=== ШАГ 3: УСТАНОВКА ===" >> $MAIN_LOG

# Монтирование системы в режим записи
echo "Монтирование системы в режим записи..." >> $MAIN_LOG

MOUNT_SUCCESS=false
MOUNT_ATTEMPTS=(
    "mount -o remount,rw /system"
    "mount -o rw,remount /system"
    "busybox mount -o remount,rw /system"
    "mount -o remount,rw /"
    "mount -o rw,remount /"
)

for attempt in "${MOUNT_ATTEMPTS[@]}"; do
    echo "  Попытка: $attempt" >> $MAIN_LOG
    $attempt >> $MAIN_LOG 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Система успешно смонтирована в режиме записи" >> $MAIN_LOG
        MOUNT_SUCCESS=true
        break
    else
        echo "  ✗ Не удалось" >> $MAIN_LOG
    fi
done

if [ "$MOUNT_SUCCESS" = false ]; then
    echo "  ✗ КРИТИЧЕСКАЯ ОШИБКА: Не удалось смонтировать систему в режиме записи!" >> $MAIN_LOG
    echo "  System остается в режиме только для чтения." >> $MAIN_LOG
    echo "  Установка невозможна." >> $MAIN_LOG
    
    # Сохраняем лог на USB
    cp "$MAIN_LOG" "$USB_LOG" 2>/dev/null
    sync
    exit 1
fi

# Удаление предыдущей версии (если существует)
echo "" >> $MAIN_LOG
echo "Очистка предыдущей установки..." >> $MAIN_LOG

if [ -d "$TARGET_DIR" ]; then
    echo "  Удаляю существующую папку: $TARGET_DIR" >> $MAIN_LOG
    rm -rf "$TARGET_DIR" >> $MAIN_LOG 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Существующая установка удалена" >> $MAIN_LOG
    else
        echo "  ⚠ Не удалось полностью удалить предыдущую версию" >> $MAIN_LOG
        echo "  Пробую принудительное удаление..." >> $MAIN_LOG
        rm -rf "$TARGET_DIR"/* 2>/dev/null
        rmdir "$TARGET_DIR" 2>/dev/null
    fi
else
    echo "  Предыдущая установка не обнаружена" >> $MAIN_LOG
fi

# Также удаляем из других возможных мест
for path in "${EXISTING_PATHS[@]}"; do
    if [ -d "$path" ] && [ "$path" != "$TARGET_DIR" ]; then
        echo "  Удаляю альтернативную установку: $path" >> $MAIN_LOG
        rm -rf "$path" >> $MAIN_LOG 2>&1
    fi
done

# Создание структуры папок
echo "" >> $MAIN_LOG
echo "Создание структуры папок..." >> $MAIN_LOG

echo "  Создаю основную директорию: $TARGET_DIR" >> $MAIN_LOG
mkdir -p "$TARGET_DIR" >> $MAIN_LOG 2>&1

if [ $? -ne 0 ]; then
    echo "  ✗ Ошибка создания основной директории" >> $MAIN_LOG
    mount -o remount,ro /system >> $MAIN_LOG 2>&1
    cp "$MAIN_LOG" "$USB_LOG" 2>/dev/null
    sync
    exit 1
fi

echo "  ✅ Основная директория создана" >> $MAIN_LOG

# Создаем архитектурные поддиректории для ART
ARCHS=("arm" "arm64" "x86" "x86_64")
for arch in "${ARCHS[@]}"; do
    OAT_DIR="$TARGET_DIR/oat/$arch"
    echo "  Создаю oat директорию для $arch..." >> $MAIN_LOG
    mkdir -p "$OAT_DIR" >> $MAIN_LOG 2>&1
    if [ $? -eq 0 ]; then
        echo "    ✅ Создана: $OAT_DIR" >> $MAIN_LOG
    else
        echo "    ⚠ Не удалось создать: $OAT_DIR" >> $MAIN_LOG
    fi
done

# Копирование APK файла
echo "" >> $MAIN_LOG
echo "Копирование APK файла..." >> $MAIN_LOG

echo "  Копирую: $APK_FILE" >> $MAIN_LOG
echo "  В: $TARGET_DIR/ESFileExplorer.apk" >> $MAIN_LOG

cp "$APK_FILE" "$TARGET_DIR/ESFileExplorer.apk" >> $MAIN_LOG 2>&1
COPY_RESULT=$?

if [ $COPY_RESULT -ne 0 ] || [ ! -f "$TARGET_DIR/ESFileExplorer.apk" ]; then
    echo "  ✗ КРИТИЧЕСКАЯ ОШИБКА: Не удалось скопировать APK файл!" >> $MAIN_LOG
    echo "  Код ошибки: $COPY_RESULT" >> $MAIN_LOG
    
    mount -o remount,ro /system >> $MAIN_LOG 2>&1
    cp "$MAIN_LOG" "$USB_LOG" 2>/dev/null
    sync
    exit 1
fi

# Проверка размера скопированного файла
COPIED_SIZE=$(ls -lh "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null | awk '{print $5}')
COPIED_MD5=$(md5sum "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null | awk '{print $1}')
echo "  ✅ APK успешно скопирован" >> $MAIN_LOG
echo "  Размер скопированного файла: $COPIED_SIZE" >> $MAIN_LOG
echo "  MD5: ${COPIED_MD5:0:16}..." >> $MAIN_LOG

# Установка прав доступа
echo "" >> $MAIN_LOG
echo "Установка прав доступа..." >> $MAIN_LOG

echo "  Устанавливаю права на директорию: 755 (drwxr-xr-x)" >> $MAIN_LOG
chmod 755 "$TARGET_DIR" >> $MAIN_LOG 2>&1

echo "  Устанавливаю права на APK файл: 644 (-rw-r--r--)" >> $MAIN_LOG
chmod 644 "$TARGET_DIR/ESFileExplorer.apk" >> $MAIN_LOG 2>&1

# Устанавливаем права на oat директории
for arch in "${ARCHS[@]}"; do
    OAT_DIR="$TARGET_DIR/oat/$arch"
    if [ -d "$OAT_DIR" ]; then
        chmod 755 "$TARGET_DIR/oat" >> $MAIN_LOG 2>&1
        chmod 755 "$OAT_DIR" >> $MAIN_LOG 2>&1
    fi
done

# Установка владельца файлов
echo "" >> $MAIN_LOG
echo "Установка владельца файлов..." >> $MAIN_LOG

if [[ "$TARGET_DIR" == "/system/priv-app/"* ]]; then
    echo "  Устанавливаю владельца: system:system (для priv-app)" >> $MAIN_LOG
    chown system:system "$TARGET_DIR" >> $MAIN_LOG 2>&1
    chown system:system "$TARGET_DIR/ESFileExplorer.apk" >> $MAIN_LOG 2>&1
    if [ -d "$TARGET_DIR/oat" ]; then
        chown system:system "$TARGET_DIR/oat" >> $MAIN_LOG 2>&1
    fi
    echo "  ✅ Владелец установлен: system:system" >> $MAIN_LOG
else
    echo "  Устанавливаю владельца: root:root (для system/app)" >> $MAIN_LOG
    chown root:root "$TARGET_DIR" >> $MAIN_LOG 2>&1
    chown root:root "$TARGET_DIR/ESFileExplorer.apk" >> $MAIN_LOG 2>&1
    if [ -d "$TARGET_DIR/oat" ]; then
        chown root:root "$TARGET_DIR/oat" >> $MAIN_LOG 2>&1
    fi
    echo "  ✅ Владелец установлен: root:root" >> $MAIN_LOG
fi

# Возвращение системы в режим только для чтения
echo "" >> $MAIN_LOG
echo "Возвращение системы в режим только для чтения..." >> $MAIN_LOG

echo "  Команда: mount -o remount,ro /system" >> $MAIN_LOG
mount -o remount,ro /system >> $MAIN_LOG 2>&1
UNMOUNT_RESULT=$?

if [ $UNMOUNT_RESULT -ne 0 ]; then
    echo "  ⚠ Предупреждение: Не удалось полностью размонтировать в режим чтения" >> $MAIN_LOG
    echo "  Пробую альтернативные методы..." >> $MAIN_LOG
    
    ALT_MOUNTS=(
        "mount -o remount,ro /"
        "busybox mount -o remount,ro /system"
        "sync && mount -o remount,ro /system"
    )
    
    for alt_mount in "${ALT_MOUNTS[@]}"; do
        $alt_mount >> $MAIN_LOG 2>&1
        if [ $? -eq 0 ]; then
            echo "  ✅ Система возвращена в режим только для чтения" >> $MAIN_LOG
            UNMOUNT_RESULT=0
            break
        fi
    done
    
    if [ $UNMOUNT_RESULT -ne 0 ]; then
        echo "  ⚠ Система может остаться в режиме записи" >> $MAIN_LOG
        echo "  Рекомендуется перезагрузка!" >> $MAIN_LOG
    fi
else
    echo "  ✅ Система успешно возвращена в режим только для чтения" >> $MAIN_LOG
fi

# 4. ПРОВЕРКА УСТАНОВКИ
echo "" >> $MAIN_LOG
echo "=== ШАГ 4: ПРОВЕРКА УСТАНОВКИ ===" >> $MAIN_LOG

echo "Проверяю результат установки..." >> $MAIN_LOG

if [ -f "$TARGET_DIR/ESFileExplorer.apk" ]; then
    FINAL_SIZE=$(ls -lh "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null | awk '{print $5}')
    FINAL_PERM=$(ls -la "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null | awk '{print $1}')
    FINAL_OWNER=$(ls -la "$TARGET_DIR/ESFileExplorer.apk" 2>/dev/null | awk '{print $3":"$4}')
    
    echo "  ✅ ФАЙЛ УСПЕШНО УСТАНОВЛЕН!" >> $MAIN_LOG
    echo "" >> $MAIN_LOG
    echo "  📊 РЕЗУЛЬТАТЫ УСТАНОВКИ:" >> $MAIN_LOG
    echo "     Файл: $TARGET_DIR/ESFileExplorer.apk" >> $MAIN_LOG
    echo "     Размер: $FINAL_SIZE" >> $MAIN_LOG
    echo "     Права: $FINAL_PERM" >> $MAIN_LOG
    echo "     Владелец: $FINAL_OWNER" >> $MAIN_LOG
    
    # Проверяем, видит ли система пакет
    echo "" >> $MAIN_LOG
    echo "  Проверка регистрации пакета в системе:" >> $MAIN_LOG
    
    # Ждем немного для регистрации
    sleep 2
    
    # Пробуем установить через pm для регистрации
    echo "  Регистрирую пакет через pm install..." >> $MAIN_LOG
    pm install -r "$TARGET_DIR/ESFileExplorer.apk" >> $MAIN_LOG 2>&1
    PM_RESULT=$?
    
    if [ $PM_RESULT -eq 0 ]; then
        echo "  ✅ Пакет успешно зарегистрирован через pm" >> $MAIN_LOG
    else
        echo "  ⚠ Не удалось зарегистрировать через pm (код: $PM_RESULT)" >> $MAIN_LOG
        echo "  Пробую альтернативный метод..." >> $MAIN_LOG
        
        # Альтернативный метод регистрации
        CLASSPATH=$(pm path com.estrongs.android.pop 2>/dev/null)
        if [ -n "$CLASSPATH" ]; then
            echo "  ✅ Пакет уже зарегистрирован в системе" >> $MAIN_LOG
        else
            echo "  ⚠ Пакет не зарегистрирован, может потребоваться перезагрузка" >> $MAIN_LOG
        fi
    fi
    
    INSTALL_SUCCESS=true
else
    echo "  ✗ ОШИБКА: Файл не найден в целевой директории!" >> $MAIN_LOG
    echo "  Установка, возможно, не удалась." >> $MAIN_LOG
    INSTALL_SUCCESS=false
fi

# 5. ФИНАЛЬНЫЕ ДЕЙСТВИЯ И ПЕРЕЗАГРУЗКА
echo "" >> $MAIN_LOG
echo "=== ШАГ 5: ЗАВЕРШЕНИЕ ===" >> $MAIN_LOG

if [ "$INSTALL_SUCCESS" = true ]; then
    echo "🎉 УСТАНОВКА ES FILE EXPLORER ВЫПОЛНЕНА УСПЕШНО!" >> $MAIN_LOG
else
    echo "⚠ УСТАНОВКА ЗАВЕРШИЛАСЬ С ПРЕДУПРЕЖДЕНИЯМИ" >> $MAIN_LOG
fi

echo "" >> $MAIN_LOG
echo "📋 СВОДНАЯ ИНФОРМАЦИЯ:" >> $MAIN_LOG
echo "  • Время установки: $(date '+%Y-%m-%d %H:%M:%S')" >> $MAIN_LOG
echo "  • USB флешка: $USB_PATH" >> $MAIN_LOG
echo "  • Исходный APK: $(basename "$APK_FILE")" >> $MAIN_LOG
echo "  • Установлен в: $TARGET_DIR" >> $MAIN_LOG
echo "  • Статус: $(if [ "$INSTALL_SUCCESS" = true ]; then echo "УСПЕХ"; else echo "ПРОБЛЕМЫ"; fi)" >> $MAIN_LOG

# Создаем скрипт для быстрого запуска ES после перезагрузки
STARTUP_SCRIPT="/data/local/tmp/start_es.sh"
cat > "$STARTUP_SCRIPT" << 'STARTUP'
#!/system/bin/sh
# Скрипт для запуска ES File Explorer после перезагрузки

echo "Запуск ES File Explorer..."
sleep 10  # Ждем загрузки системы

# Пробуем разные варианты запуска
am start -n com.estrongs.android.pop/.view.FileExplorerActivity 2>/dev/null
sleep 2
am start -n com.estrongs.android.pop/.MainActivity 2>/dev/null
sleep 2
am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n com.estrongs.android.pop/.view.FileExplorerActivity 2>/dev/null

# Если не сработало, ждем и пробуем снова
sleep 15
am start -n com.estrongs.android.pop/.view.FileExplorerActivity 2>/dev/null

echo "ES File Explorer должен быть запущен"
STARTUP

chmod 755 "$STARTUP_SCRIPT"
echo "  Создан скрипт автозапуска: $STARTUP_SCRIPT" >> $MAIN_LOG

echo "" >> $MAIN_LOG
echo "🔄 ДАЛЬНЕЙШИЕ ДЕЙСТВИЯ:" >> $MAIN_LOG
echo "  1. Магнитола перезагрузится через 5 секунд" >> $MAIN_LOG
echo "  2. После перезагрузки ES File Explorer появится в меню приложений" >> $MAIN_LOG
echo "  3. Приложение будет доступно как системное" >> $MAIN_LOG
echo "  4. Если не появится автоматически, запустите скрипт:" >> $MAIN_LOG
echo "     sh $STARTUP_SCRIPT" >> $MAIN_LOG
echo "" >> $MAIN_LOG
echo "⚠ ВАЖНОЕ ПРЕДУПРЕЖДЕНИЕ:" >> $MAIN_LOG
echo "  Если флешка останется в USB порте после перезагрузки," >> $MAIN_LOG
echo "  этот скрипт запустится снова и попытается переустановить приложение." >> $MAIN_LOG
echo "  Рекомендуется ВЫТАЩИТЬ ФЛЕШКУ во время перезагрузки!" >> $MAIN_LOG
echo "" >> $MAIN_LOG
echo "📄 ЛОГИ УСТАНОВКИ:" >> $MAIN_LOG
echo "  • Системный лог: $MAIN_LOG" >> $MAIN_LOG
echo "  • Лог на USB: $USB_LOG" >> $MAIN_LOG
echo "  • Скрипт запуска: $STARTUP_SCRIPT" >> $MAIN_LOG

# Копируем полный лог на USB флешку
echo "" >> $MAIN_LOG
echo "Сохранение лога на USB флешку..." >> $MAIN_LOG
cp "$MAIN_LOG" "$USB_LOG" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Лог успешно сохранен на USB" >> $MAIN_LOG
else
    echo "⚠ Не удалось сохранить лог на USB" >> $MAIN_LOG
    # Пробуем альтернативное расположение
    cp "$MAIN_LOG" "$USB_PATH/es_install.log" 2>/dev/null
fi

# Синхронизация файловых систем
echo "Синхронизация файловых систем..." >> $MAIN_LOG
sync

echo "" >> $MAIN_LOG
echo "⏱️  ПОДГОТОВКА К ПЕРЕЗАГРУЗКЕ..." >> $MAIN_LOG
echo "Перезагрузка через 5 секунд..." >> $MAIN_LOG

# Обратный отсчет
for i in {5..1}; do
    echo "  $i..." >> $MAIN_LOG
    sleep 1
done

echo "" >> $MAIN_LOG
echo "🚀 ВЫПОЛНЯЮ ПЕРЕЗАГРУЗКУ СИСТЕМЫ..." >> $MAIN_LOG
echo "Время перезагрузки: $(date '+%Y-%m-%d %H:%M:%S')" >> $MAIN_LOG
echo "==================================================" >> $MAIN_LOG

# Финальная синхронизация
sync

# Запускаем скрипт автозапуска после перезагрузки (через init.d или другое)
if [ -d "/system/etc/init.d" ]; then
    cp "$STARTUP_SCRIPT" "/system/etc/init.d/99startes"
    chmod 755 "/system/etc/init.d/99startes"
    echo "Скрипт автозапуска добавлен в init.d" >> "$USB_LOG"
fi

# Выполняем перезагрузку
reboot