#!/bin/bash

# Konfigurasi
BOT_TOKEN="7141406407:AAGS79uDhIjYr1JktIG9nr8ncczuztl2wzs"
CHAT_ID="6422320269"
FILE_PATH="/root/domain_checker/domains.txt"
PROCESSED_FILE="/root/domain_checker/domains_registered.txt"

send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$message"
}

check_domains() {
    while IFS= read -r line; do
        # Abaikan komentar
        if [[ "$line" =~ ^# ]]; then
            continue
        fi

        # Ambil domain dari setiap baris
        domain=$(echo "$line" | awk '{print $1}')

        # Cek apakah domain sudah pernah diproses
        if ! grep -q "$domain" "$PROCESSED_FILE"; then
            message="New domain added📝:%0A*$domain*%0A/fulldomain - to see all domains and wait for"
            send_telegram_message "$message"
            echo "$domain" >> "$PROCESSED_FILE"  # Simpan domain yang sudah diproses
        fi
    done < "$FILE_PATH"
}

# Buat file jika belum ada
if [ ! -f "$PROCESSED_FILE" ]; then
    touch "$PROCESSED_FILE"
fi

check_domains
