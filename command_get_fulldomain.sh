#!/bin/bash

# install js

TOKEN="7141406407:AAGS79uDhIjYr1JktIG9nr8ncczuztl2wzs"
DOMAIN_FILE="/root/cekdomain/domains_registered.txt"
LAST_UPDATE_FILE="/root/cekdomain/last_updateid.txt"

# Fungsi untuk mengirim pesan ke Telegram
send_message() {
    local chat_id="$1"
    local message="$2"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$chat_id" -d "text=$message"
}

# Fungsi untuk membaca domain dari file dan menambahkan nomor
read_domains() {
    if [[ -f "$DOMAIN_FILE" ]]; then
        local domains=""
        local index=1
        while IFS= read -r line; do
            domains+="[$index] $line\n"
            ((index++))
        done < "$DOMAIN_FILE"
        echo -e "$domains"
    else
        echo "File tidak ditemukan."
    fi
}

# Mendapatkan update dari Telegram
get_updates() {
    curl -s "https://api.telegram.org/bot$TOKEN/getUpdates"
}

# Menangani webhook
handle_update() {
    local update="$1"
    local message=$(echo "$update" | jq -r '.message.text')
    local chat_id=$(echo "$update" | jq -r '.message.chat.id')
    local update_id=$(echo "$update" | jq -r '.update_id')

    # Hanya proses jika update_id lebih besar dari yang terakhir
    if [[ "$update_id" -gt "$LAST_UPDATE_ID" ]]; then
        if [[ "$message" == "/fulldomain" ]]; then
            domains=$(read_domains)
            send_message "$chat_id" "$domains"
        fi
        echo "$update_id" > "$LAST_UPDATE_FILE"  # Simpan update_id terakhir
    fi
}

# Membaca update_id terakhir dari file
if [[ -f "$LAST_UPDATE_FILE" ]]; then
    LAST_UPDATE_ID=$(<"$LAST_UPDATE_FILE")
else
    LAST_UPDATE_ID=0  # Jika file tidak ada, mulai dari 0
fi

# Mendapatkan update terbaru
updates=$(get_updates)

# Memproses semua update
echo "$updates" | jq -c '.result[]' | while read -r update; do
    handle_update "$update"
done
