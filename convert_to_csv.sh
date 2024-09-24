#!/bin/bash

# Nama file input dan output
input_file="/root/cekdomain/result_main.txt"
output_file="/root/cekdomain/domain_valid.csv"

# Ganti dengan token bot dan chat ID Anda
BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

# Menghapus file CSV output jika sudah ada
rm -f "$output_file"

# Menulis header ke file CSV
echo "Domain,Registrar,Status,Expires,Days Left" > "$output_file"

# Mengabaikan baris pemisah dan header, serta baris ketiga
sed '3d' "$input_file" | tail -n +3 | sed 's/^[ \t]*//;s/[ \t]*$//' | awk -F ' *' '{
    # Gabungkan field dari $2 sampai kolom sebelum kolom terakhir
    registrar=""
    for (i=2; i<=NF-3; i++) {
        registrar = registrar $i " "
    }
    # Trim whitespace di awal dan akhir dan tambahkan tanda kutip
    registrar = "\"" substr(registrar, 1, length(registrar)-1) "\""

    # Ambil kolom terakhir yang sesuai
    status = $(NF-2)
    expires = $(NF-1)
    days_left = $NF

    OFS=","; print $1, registrar, status, expires, days_left
}' >> "$output_file"

echo "Data telah disimpan dalam $output_file"


# Pesan yang ingin dikirim
message="Here is the file containing domain validation. I will return in one month again🤗"

# Kirim file ke bot Telegram
curl -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
    -F "chat_id=$CHAT_ID" \
    -F "document=@$output_file" \
    -F "caption=$message"

echo "File telah dikirim ke Telegram."
