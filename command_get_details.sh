#!/bin/bash

TOKEN="YOUR_BOT_TOKEN"
API_URL="https://api.telegram.org/bot$TOKEN"
ANSWERED_FILE="/root/cekdomain/last_updateid.txt"

send_message() {
    local chat_id="$1"
    local message="$2"
    curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id" -d "text=$message" -d "parse_mode=Markdown"
}

# Mengambil update dari Telegram
get_updates() {
    curl -s -X GET "$API_URL/getUpdates"
}

# Membaca ID yang sudah dijawab
if [[ ! -f $ANSWERED_FILE ]]; then
    touch $ANSWERED_FILE
fi

UPDATES=$(get_updates)

# Ambil satu pembaruan terbaru
for (( i=0; i<$(echo "$UPDATES" | jq '.result | length'); i++ )); do
    UPDATE_ID=$(echo "$UPDATES" | jq -r ".result[$i].update_id")
    CHAT_ID=$(echo "$UPDATES" | jq -r ".result[$i].message.chat.id")
    COMMAND=$(echo "$UPDATES" | jq -r ".result[$i].message.text")

    # Cek apakah ID sudah dijawab
    if grep -q "$UPDATE_ID" "$ANSWERED_FILE"; then
        continue
    fi

    if [[ "$COMMAND" == "/details_domain "* ]]; then
        DOMAIN=$(echo "$COMMAND" | sed 's/^\/details_domain //')

        if [[ "$DOMAIN" != "" ]]; then
            WHOIS_INFO=$(whois "$DOMAIN")

            # Ekstrak informasi penting
            NAME=$(echo "$WHOIS_INFO" | grep -i 'Domain Name' | awk '{print tolower($3)}' | head -n 1)
            REGISTRAR=$(echo "$WHOIS_INFO" | grep -i 'Registrar URL' | awk -F ': ' '{print $2}' | sed 's| whois.*||; s|http[s]*://||;')
            EXPIRATION_DATE=$(echo "$WHOIS_INFO" | grep -i 'Expiry Date\|Expiration Date' | head -n 1 | cut -d ':' -f2 | xargs)

            # Tentukan status berdasarkan informasi yang ada
            if echo "$WHOIS_INFO" | grep -qi 'status: active'; then
                STATUS="Active"
            elif echo "$WHOIS_INFO" | grep -qi 'status: clientTransferProhibited'; then
                STATUS="Active"
            else
                STATUS="Expired"
            fi

            # Memperbaiki format tanggal
            if [[ "$EXPIRATION_DATE" =~ "T" ]]; then
                EXPIRATION_DATE=$(echo "$EXPIRATION_DATE" | cut -d 'T' -f1)
            fi

            # Hitung sisa hari
            if [[ -n "$EXPIRATION_DATE" ]]; then
                REMAINING_DAYS=$(( ( $(date -d "$EXPIRATION_DATE" +%s) - $(date +%s) ) / 86400 ))
            else
                REMAINING_DAYS="N/A"
            fi

            # Format pesan agar lebih rapi
            MESSAGE="*Domain:* $NAME%0A*Registrar:* $REGISTRAR%0A*Expiration Date:* $EXPIRATION_DATE%0A*Status:* $STATUS%0A*Remaining Days:* $REMAINING_DAYS"
            send_message "$CHAT_ID" "$MESSAGE"

            # Simpan ID yang sudah dijawab
            echo "$UPDATE_ID" >> "$ANSWERED_FILE"
        else
            send_message "$CHAT_ID" "Silakan kirim nama domain yang valid."
        fi
    fi
done
