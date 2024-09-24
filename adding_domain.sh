#!/bin/bash

# Konfigurasi
BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
FILE_PATH="/root/cekdomain/domains.txt"
PROCESSED_FILE="/root/cekdomain/domains_registered.txt"

send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$m>}

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
