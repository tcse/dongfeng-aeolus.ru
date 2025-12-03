#!/system/bin/sh
# ============================================================================
# ОПТИМАЛЬНЫЙ СКРИПТ АВТОЗАПУСКА ES FILE EXPLORER
# Для второй флешки: /update/custom_rep.sh
# ============================================================================
# Проект: Автоматическая установка приложений на магнитолы Dongfeng Aeolus
# Форум: https://dongfeng-aeolus.ru/community/topicid/422/
# Телеграм: https://t.me/aeolusshinegs
# Репозиторий: https://github.com/tcse/dongfeng-aeolus.ru
# Авторы: Vitaly V. Chuyakov <vitaly@chuyakov.ru>, Deepseek AI
# Лицензия: GNU GPLv3
# Версия: 1.0.0
# Дата: 2025-12-03
# Назначение: Запуск ES File Explorer после установки
# ============================================================================

LOG="/data/local/tmp/es_launch_$(date +%H%M%S).log"
echo "Запуск ES с флешки: $(date)" > $LOG

# 1. ПРОВЕРКА УСТАНОВКИ
echo "Проверяю установлен ли ES..." >> $LOG
if ! pm list packages | grep -q "com.estrongs.android.pop"; then
    echo "ERROR: ES не установлен!" >> $LOG
    echo "Сначала установите ES через первую флешку" >> $LOG
    
    # Показываем ошибку пользователю
    am start -a android.intent.action.VIEW \
        -t text/plain \
        -d "data:text/plain,ERROR: ES File Explorer не установлен!\n\n1. Вставьте первую флешку с установщиком\n2. После установки перезагрузите\n3. Затем вставьте эту флешку" \
        >> $LOG 2>&1
    
    exit 1
fi

echo "✅ ES установлен" >> $LOG

# 2. ПОДГОТОВКА
echo "Останавливаю ES если запущен..." >> $LOG
am force-stop com.estrongs.android.pop 2>/dev/null
pkill -f estrongs 2>/dev/null
sleep 1

# 3. ЗАПУСК (4 способа)
echo "Запускаю ES..." >> $LOG

# Способ 1: Основной
echo "Способ 1: MainActivity..." >> $LOG
am start -n "com.estrongs.android.pop/.MainActivity" \
    -a android.intent.action.MAIN \
    -c android.intent.category.LAUNCHER \
    --activity-brought-to-front \
    >> $LOG 2>&1
sleep 2

# Проверяем
if ps | grep -q "estrongs"; then
    echo "✅ ES запущен (способ 1)" >> $LOG
else
    # Способ 2: Альтернативный
    echo "Способ 2: FileExplorerActivity..." >> $LOG
    am start -n "com.estrongs.android.pop/.view.FileExplorerActivity" \
        -a android.intent.action.MAIN \
        -c android.intent.category.LAUNCHER \
        >> $LOG 2>&1
    sleep 2
fi

# 4. ПРОВЕРКА РЕЗУЛЬТАТА
sleep 3
if ps | grep -q "estrongs"; then
    echo "🎉 ES УСПЕШНО ЗАПУЩЕН!" >> $LOG
    
    # Показываем успех
    am start -a android.intent.action.VIEW \
        -t text/plain \
        -d "data:text/plain,SUCCESS: ES File Explorer запущен!\n\nТеперь можете пользоваться файловым менеджером." \
        >> $LOG 2>&1
else
    echo "⚠ ES не запустился автоматически" >> $LOG
    
    # Показываем инструкцию
    am start -a android.intent.action.VIEW \
        -t text/plain \
        -d "data:text/plain,ES не запустился автоматически.\n\nЗапустите вручную:\n1. Откройте меню приложений\n2. Найдите ES File Explorer\n3. Нажмите для запуска" \
        >> $LOG 2>&1
fi

# 5. СОХРАНЕНИЕ ЛОГА
echo "Сохраняю лог на флешку..." >> $LOG
cp "$LOG" "/update/es_launch_result.log" 2>/dev/null
sync

echo "Готово! Лог: $LOG" >> $LOG

# Краткий вывод в консоль
echo ""
if ps | grep -q "estrongs"; then
    echo "✅ ES File Explorer запущен!"
else
    echo "⚠ Запустите ES вручную из меню приложений"
fi
echo "📄 Лог: $LOG"
echo ""