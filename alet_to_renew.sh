#!/bin/bash

# Nama file yang berisi data
domains="/root/cekdomain/result_main.txt"
# Ganti dengan token bot dan chat ID Anda
BOT_TOKEN="7141406407:AAGS79uDhIjYr1JktIG9nr8ncczuztl2wzs"
CHAT_ID="6422320269"

# Mengolah data dari file
while read -r line; do
    # Skip header dan separator
    if [[ "$line" == *"Domain"* || "$line" == *"---"* ]]; then
        continue
    fi

    # Cek jika baris kosong
    if [[ -z "$line" ]]; then
        continue
    fi

    # Ambil nilai Days Left dan hapus spasi
    days_left=$(echo "$line" | awk '{print $NF}' | xargs)

    # Debugging: Tampilkan baris yang sedang diproses
    echo "Processing line: $line"
    echo "Extracted Days Left: '$days_left'"

    # Pastikan days_left adalah integer
    if [[ "$days_left" =~ ^[0-9]+$ ]]; then
        # Cek jika days_left kurang dari 3, atau sama dengan 7 atau 30
        if [ "$days_left" -lt 4 ]; then
            domain=$(echo "$line" | awk '{print $1}')
            message="Domain $domain ⚠️%0AWill be expired in $days_left days❗"
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                -d "chat_id=$CHAT_ID" \
                -d "text=$message"
        elif [ "$days_left" -eq 7 ]; then
            domain=$(echo "$line" | awk '{print $1}')
            message="Domain $domain ⚠️%0AWill be expired in $days_left days❗"
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                -d "chat_id=$CHAT_ID" \
                -d "text=$message"
        elif [ "$days_left" -eq 30 ]; then
            domain=$(echo "$line" | awk '{print $1}')
            message="Domain $domain ⚠️%0AWill be expired in $days_left days❗"
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                -d "chat_id=$CHAT_ID" \
                -d "text=$message"
        fi
    else
        # Debugging: Tampilkan error
        echo "Nilai 'Days Left' untuk domain $domain tidak valid: '$days_left'"
    fi
done < "$domains"
