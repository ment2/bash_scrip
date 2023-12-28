#!/bin/bash

lock_file="/media/sf_DZ/bash/apache_log_script.lock"

# Проверка наличия блокировки
if [ -f "$lock_file" ]; then
    echo "Script is already running. Exiting."
    exit 1
else
    # Создание блокировки
    touch "$lock_file"
fi

# Функция для удаления блокировки
function cleanup {
    rm -f "$lock_file"
    exit
}

trap cleanup EXIT

log_file="/media/sf_DZ/bash/apache.log"
output_file="/media/sf_DZ/bash/output.log"

# Проверка наличия файла логов
if [ ! -f "$log_file" ]; then
    echo "Log file not found. Exiting."
    exit 1
fi

# Проверка наличия записей в файле логов
log_lines=$(wc -l < "$log_file")
if [ "$log_lines" -eq 0 ]; then
    echo "Log file does not contain any entries. Exiting."
    exit 1
fi

# Вывод списка IP адресов с наибольшим количеством запросов
echo "Top IP addresses with the most requests:" >> "$output_file"
echo "---------------------------------------" >> "$output_file"
awk '{print $1}' "$log_file" | sort | uniq -c | sort -nr | head -n 10 >> "$output_file"
echo >> "$output_file"

# Вывод списка запрашиваемых URL с наибольшим количеством запросов
echo "Top requested URLs:" >> "$output_file"
echo "-------------------" >> "$output_file"
awk '{print $11}' "$log_file" | sort | uniq -c | sort -nr | head -n 10 >> "$output_file"
echo >> "$output_file"

# Вывод ошибок веб-сервера/приложения
echo "Server/application errors:" >> "$output_file"
echo "--------------------------" >> "$output_file"
awk '$9 != 200 {print}' "$log_file" >> "$output_file"
echo >> "$output_file"

# Вывод списка всех кодов HTTP ответа с указанием их количества
echo "HTTP response status codes:" >> "$output_file"
echo "---------------------------" >> "$output_file"
awk '{print $9}' "$log_file" | sort | uniq -c >> "$output_file"
echo >> "$output_file"

# Вывод диапазона времени
echo "Logs time:" >> "$output_file"
echo "---------------------------" >> "$output_file"
# Получение 4-ого поля первой строки
first_line=$(head -n 1 "$log_file" | awk '{print $4}')
# Получение 4-ого поля последней строки
last_line=$(tail -n 1 "$log_file" | awk '{print $4}')
# Вывод результата
echo "log start time: $first_line" >> "$output_file"
echo "log end time: $last_line" >> "$output_file"

# Отправка содержимого файла на почту
recipient="example@example.com"
subject="Log Analysis Report ($(date +"%d/%b/%Y %H:%M"))"
mail -s "$subject" "$recipient" < "$output_file"

echo "Log analysis completed. Results written to $output_file."
