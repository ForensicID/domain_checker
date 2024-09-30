#!/bin/bash

DOMAIN_FILE="domain_list.txt"
LOG_FILE="domain_check.log"
PREV_LOG_FILE="domain_check_prev.log"
NOTIFICATION_FILE="notification_timestamps.txt"

# Konfigurasi Bot Telegram
TELEGRAM_BOT_TOKEN="7804811037:AAHnBbz2FtZIdqhGjnezM20FGe2ZaT9fC8I"
TELEGRAM_CHAT_ID="6422320269"

# Fungsi untuk mengirim pesan ke Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
         -d "chat_id=$TELEGRAM_CHAT_ID" \
         -d "text=$message" \
         -d "parse_mode=Markdown"
}

# Fungsi untuk memeriksa status domain dan menyimpannya ke log
check_domains() {
    > "$LOG_FILE"  # Kosongkan file log baru

    while IFS= read -r DOMAIN; do
        WHOIS_OUTPUT=$(whois "$DOMAIN")
        if echo "$WHOIS_OUTPUT" | grep -q "No match for"; then
            STATUS="Tersedia"
            REGISTRAR="N/A"
            REGISTRATION_URL="N/A"
            EXPIRATION_DATE="N/A"
            DAYS_UNTIL_EXPIRATION="N/A"
        else
            STATUS="Aktif"
            REGISTRAR=$(echo "$WHOIS_OUTPUT" | grep -i "Registrar:" | awk -F': ' '{print $2}' | xargs)
            REGISTRATION_URL=$(echo "$WHOIS_OUTPUT" | grep -i "Registrar URL:" | awk -F': ' '{print $2}' | xargs)
            EXPIRATION_DATE=$(echo "$WHOIS_OUTPUT" | grep -i "Registry Expiry Date:" | awk -F': ' '{print $2}' | xargs | cut -d'T' -f1)

            if [ -n "$EXPIRATION_DATE" ]; then
                EXPIRATION_TIMESTAMP=$(date -d "$EXPIRATION_DATE" +%s 2>/dev/null)
                CURRENT_TIMESTAMP=$(date +%s)
                DAYS_UNTIL_EXPIRATION=$(( (EXPIRATION_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
            else
                EXPIRATION_DATE="N/A"
                DAYS_UNTIL_EXPIRATION="N/A"
            fi
        fi

        # Menyimpan hasil ke file log
        {
            echo "Nama Domain: $DOMAIN"
            echo "Status: $STATUS"
            echo "Registrasi: $REGISTRAR"
            echo "URL: $REGISTRATION_URL"
            echo "Tanggal Expired: $EXPIRATION_DATE"
            echo "Sisa Hari hingga Expired: $DAYS_UNTIL_EXPIRATION"
            echo "-------------------------------"
        } >> "$LOG_FILE"

        # Kirim notifikasi jika sisa hari hingga kadaluarsa
        notify_expiration "$DOMAIN" "$DAYS_UNTIL_EXPIRATION"

    done < "$DOMAIN_FILE"
}

notify_expiration() {
    local DOMAIN="$1"
    local DAYS="$2"
    local TODAY=$(date +%Y-%m-%d)

    # Cek apakah notifikasi sudah dikirim hari ini
    if [[ "$DAYS" =~ ^[0-9]+$ ]]; then
        LAST_NOTIFICATION_DATE=$(grep -E "^$DOMAIN " "$NOTIFICATION_FILE" | awk '{print $2}')

        # Hanya kirim notifikasi jika belum pernah dikirim hari ini
        if [[ "$LAST_NOTIFICATION_DATE" != "$TODAY" ]]; then
            if [ "$DAYS" -lt 4 ]; then
                send_telegram_message "⚠️ Domain *$DOMAIN* akan kedaluwarsa dalam *$DAYS hari*! "
            elif [ "$DAYS" -eq 7 ]; then
                send_telegram_message "⚠️ Domain *$DOMAIN* akan kedaluwarsa dalam *$DAYS hari*! "
            elif [ "$DAYS" -eq 30 ]; then
                send_telegram_message "⚠️ Domain *$DOMAIN* akan kedaluwarsa dalam *$DAYS hari*! "
            fi
            
            # Update timestamp notifikasi
            sed -i "/^$DOMAIN /d" "$NOTIFICATION_FILE"  # Hapus entri lama
            echo "$DOMAIN $TODAY" >> "$NOTIFICATION_FILE"  # Tambah entri baru
        fi
    fi
}

notify_day_increase() {
    local DOMAIN="$1"
    local OLD_DAYS="$2"
    local NEW_DAYS="$3"
    
    if [[ "$OLD_DAYS" =~ ^[0-9]+$ ]] && [[ "$NEW_DAYS" =~ ^[0-9]+$ ]]; then
        local DIFF=$(( NEW_DAYS - OLD_DAYS ))
        
        if [ "$DIFF" -gt 0 ]; then
            local TOTAL_DAYS=$(( OLD_DAYS + DIFF ))
            send_telegram_message "✅ *$DOMAIN* mengalami perpanjangan *$DIFF hari* dan total sisa hari hingga kadaluarsa adalah *$TOTAL_DAYS hari*!"
        fi
    fi
}

# Fungsi untuk membandingkan log dan mengirim notifikasi jika ada perubahan
compare_logs() {
    if [ -f "$PREV_LOG_FILE" ]; then
        ADDED_DOMAINS=$(grep -F -x -v -f "$PREV_LOG_FILE" "$LOG_FILE" | grep "Nama Domain:" | awk -F': ' '{print $2}')
        REMOVED_DOMAINS=$(grep -F -x -v -f "$LOG_FILE" "$PREV_LOG_FILE" | grep "Nama Domain:" | awk -F': ' '{print $2}')

        # Kirim pesan jika ada penambahan domain
        if [ -n "$ADDED_DOMAINS" ]; then
            send_telegram_message "Domain yang ditambahkan:%0A*$ADDED_DOMAINS*"
        fi

        # Kirim pesan jika ada pengurangan domain
        if [ -n "$REMOVED_DOMAINS" ]; then
            send_telegram_message "Domain yang dihapus:%0A*$REMOVED_DOMAINS*"
        fi

        # Periksa penambahan hari untuk domain yang ada
        while IFS= read -r DOMAIN; do
            OLD_DAYS=$(grep -A 5 "$DOMAIN" "$PREV_LOG_FILE" | grep "Sisa Hari hingga Expired:" | cut -d':' -f2 | xargs)
            NEW_DAYS=$(grep -A 5 "$DOMAIN" "$LOG_FILE" | grep "Sisa Hari hingga Expired:" | cut -d':' -f2 | xargs)
            
            notify_day_increase "$DOMAIN" "$OLD_DAYS" "$NEW_DAYS"
        done < <(grep "Nama Domain:" "$LOG_FILE")
    else
        echo "Tidak ada log sebelumnya untuk dibandingkan."
    fi
}

create_and_send_csv() {
    local TODAY=$(date +%Y-%m-%d)
    local LAST_CSV_MONTH=$(grep -E "^csv_sent " "$NOTIFICATION_FILE" | awk '{print $2}')
    
    if [[ -z "$LAST_CSV_MONTH" ]] || [[ "$(date -d "$TODAY" +%m)" != "$(date -d "$LAST_CSV_MONTH" +%m)" ]] || [[ "$(date -d "$TODAY" +%Y)" != "$(date -d "$LAST_CSV_MONTH" +%Y)" ]]; then
        local CSV_FILE="domain_report_$TODAY.csv"
        echo "Nama Domain,Status,Registrasi,URL Registrasi,Tanggal Expired,Sisa Hari hingga Expired" > "$CSV_FILE"

        while IFS= read -r DOMAIN; do
            DOMAIN_INFO=$(grep -A 5 "$DOMAIN" "$LOG_FILE")

            # Ambil masing-masing informasi dengan benar
            local STATUS=$(echo "$DOMAIN_INFO" | grep "Status:" | cut -d':' -f2- | xargs)
            local REGISTRASI=$(echo "$DOMAIN_INFO" | grep "Registrasi:" | cut -d':' -f2 | xargs)
            local URL=$(echo "$DOMAIN_INFO" | grep "URL:" | cut -d':' -f2- | xargs)
            local TANGGAL_EXPIRED=$(echo "$DOMAIN_INFO" | grep "Tanggal Expired:" | cut -d':' -f2- | xargs)
            local SISA_HARI=$(echo "$DOMAIN_INFO" | grep "Sisa Hari hingga Expired:" | cut -d':' -f2- | xargs)

            # Tulis ke file CSV
            echo "$DOMAIN,$STATUS,\"$REGISTRASI\",$URL,$TANGGAL_EXPIRED,$SISA_HARI" >> "$CSV_FILE"
        done < "$DOMAIN_FILE"

        send_telegram_message "📊 Laporan domain terbaru telah dibuat dan dilampirkan."
        curl -F document=@"$CSV_FILE" "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" -F chat_id="$TELEGRAM_CHAT_ID"

        sed -i "/^csv_sent /d" "$NOTIFICATION_FILE"
        echo "csv_sent $TODAY" >> "$NOTIFICATION_FILE"
    fi
}

# Salin file log sebelumnya jika ada
if [ -f "$LOG_FILE" ]; then
    cp "$LOG_FILE" "$PREV_LOG_FILE"
else
    touch "$PREV_LOG_FILE"  # Buat file kosong jika tidak ada
fi

# Memeriksa domain
check_domains

# Bandingkan log dan kirim notifikasi
compare_logs

# Panggil fungsi untuk membuat dan mengirim CSV
create_and_send_csv

echo "Hasil pemeriksaan domain telah disimpan di $LOG_FILE."
