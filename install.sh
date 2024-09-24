#!/bin/bash

BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
MAIN_DIR="/root/cekdomain" # folder cekdomain check it with pwd
CSV_NAME="domain_valid.csv"

echo "Mengupdate daftar paket..."
sudo apt update

echo "Menginstal paket <nama-paket>..."
if sudo apt install whois  jq -y; then
    echo "Instalasi berhasil!"
else
    echo "Instalasi gagal. Menghentikan eksekusi."
    exit 1
fi

CRON_FILE=$(mktemp)

# Mengganti BOT_TOKEN di baris ke-4
echo "Mengganti BOT_TOKEN di $MAIN_DIR/adding_domain.sh"
sed -i "4s/.*/BOT_TOKEN=\"$BOT_TOKEN\"/" "$MAIN_DIR/adding_domain.sh"
sleep 1s
# Mengganti CHAT_ID di baris ke-5
echo "Mengganti CHAT_ID di $MAIN_DIR/adding_domain.sh"
sed -i "5s/.*/CHAT_ID=\"$CHAT_ID\"/" "$MAIN_DIR/adding_domain.sh"
sleep 1s
# Mengganti FILE_PATH dengan domains.txt
echo "Mengganti FILE_PATH dengan $MAIN_DIR/domains.txt di $MAIN_DIR/adding_domain.sh"
sed -i "s|FILE_PATH=\".*\"|FILE_PATH=\"$MAIN_DIR/domains.txt\"|" "$MAIN_DIR/adding_domain.sh"
sleep 1s
# Mengganti PROCESSED_FILE dengan domains_registered.txt
echo "Mengganti PROCESSED_FILE dengan $MAIN_DIR/domains_registered.txt di $MAIN_DIR/adding_domain.sh"
sed -i "s|PROCESSED_FILE=\".*\"|PROCESSED_FILE=\"$MAIN_DIR/domains_registered.txt\"|" "$MAIN_DIR/adding_domain.sh"
sleep 1s
# Mengganti domains di alert_to_renew.sh
echo "Mengganti domains di $MAIN_DIR/alert_to_renew.sh"
sed -i "s|domains=\".*\"|domains=\"$MAIN_DIR/result_main.txt\"|" "$MAIN_DIR/alert_to_renew.sh"
sleep 1s
# Mengganti BOT_TOKEN di baris ke-6 di alert_to_renew.sh
echo "Mengganti BOT_TOKEN di baris ke-6 $MAIN_DIR/alert_to_renew.sh"
sed -i "6s/.*/BOT_TOKEN=\"$BOT_TOKEN\"/" "$MAIN_DIR/alert_to_renew.sh"
sleep 1s
# Mengganti CHAT_ID di baris ke-7 di alert_to_renew.sh
echo "Mengganti CHAT_ID di baris ke-7 $MAIN_DIR/alert_to_renew.sh"
sed -i "7s/.*/CHAT_ID=\"$CHAT_ID\"/" "$MAIN_DIR/alert_to_renew.sh"
sleep 1s
# Mengganti TOKEN di command.sh
echo "Mengganti TOKEN di baris ke-3 $MAIN_DIR/command.sh"
sed -i "3s/.*/TOKEN=\"$BOT_TOKEN\"/" "$MAIN_DIR/command.sh"
sleep 1s
# Mengganti DOMAIN_FILE di command.sh
echo "Mengganti DOMAIN_FILE dengan $MAIN_DIR/domains_registered.txt di $MAIN_DIR/command.sh"
sed -i "s|DOMAIN_FILE=\".*\"|DOMAIN_FILE=\"$MAIN_DIR/domains_registered.txt\"|" "$MAIN_DIR/command.sh"
sleep 1s
# Mengganti LAST_UPDATE_FILE di command.sh
echo "Mengganti LAST_UPDATE_FILE dengan $MAIN_DIR/last_updateid.txt di $MAIN_DIR/command.sh"
sed -i "s|UPDATE_FILE=\".*\"|UPDATE_FILE=\"$MAIN_DIR/last_updateid.txt\"|" "$MAIN_DIR/command.sh"
sleep 1s
# Mengganti CHAT_ID di baris ke-9 di convert_to_csv.sh
echo "Mengganti CHAT_ID di baris ke-9 $MAIN_DIR/convert_to_csv.sh"
sed -i "9s/.*/CHAT_ID=\"$CHAT_ID\"/" "$MAIN_DIR/convert_to_csv.sh"
sleep 1s
# Mengganti BOT_TOKEN di baris ke-8 di convert_to_csv.sh
echo "Mengganti BOT_TOKEN di baris ke-8 $MAIN_DIR/convert_to_csv.sh"
sed -i "8s/.*/BOT_TOKEN=\"$BOT_TOKEN\"/" "$MAIN_DIR/convert_to_csv.sh"
sleep 1s
# Mengganti input_file di convert_to_csv.sh
echo "Mengganti input_file dengan $MAIN_DIR/result_main.txt di $MAIN_DIR/convert_to_csv.sh"
sed -i "s|input_file=\".*\"|input_file=\"$MAIN_DIR/result_main.txt\"|" "$MAIN_DIR/convert_to_csv.sh"
sleep 1s
# Mengganti output_file di convert_to_csv.sh
echo "Mengganti output_file dengan $MAIN_DIR/domain_valid.csv di $MAIN_DIR/convert_to_csv.sh"
sed -i "s|output_file=\".*\"|output_file=\"$MAIN_DIR/domain_valid.csv\"|" "$MAIN_DIR/convert_to_csv.sh"
sleep 1s
# Menambah permission di dalam folder
echo "Menambah permission untuk mengeksekusi program"
sudo chmod +x $MAIN_DIR/*
sleep 1s

echo "Memulai pemeriksaan domain..."
bash $MAIN_DIR/domain_checker.sh -f $MAIN_DIR/domains.txt > $MAIN_DIR/result_main.txt && sed -i '/^$/d' $MAIN_DIR/result_main.txt
sleep 10s
echo "Menambahkan domain baru..."
bash $MAIN_DIR/adding_domain.sh
sleep 1s
echo "Mengirimkan peringatan untuk perpanjangan..."
bash $MAIN_DIR/alert_to_renew.sh
sleep 1s
echo "Mengambil domain lengkap..."
bash $MAIN_DIR/command.sh
echo "Mengonversi hasil ke format CSV..."
bash $MAIN_DIR/convert_to_csv.sh
sleep 1s
echo "Proses selesai."
# Menambahkan entri cron baru
echo "0 9 * * * bash $MAIN_DIR/domain_checker.sh -f $MAIN_DIR/domains.txt > $MAIN_DIR/result_main.txt && sed -i '/^$/d' $MAIN_DIR/result_main.txt" >> "$CRON_FILE"
echo "* * * * * bash $MAIN_DIR/adding_domain.sh" >> "$CRON_FILE"
echo "1 9 * * * bash $MAIN_DIR/alert_to_renew.sh" >> "$CRON_FILE"
echo "* * * * * bash $MAIN_DIR/command.sh" >> "$CRON_FILE"
echo "0 0 30 * * bash $MAIN_DIR/convert_to_csv.sh" >> "$CRON_FILE"

# Mengambil entri cron yang sudah ada
crontab -l >> "$CRON_FILE"

# Mengupdate crontab dengan entri baru
crontab "$CRON_FILE"

# Menghapus file sementara
rm "$CRON_FILE"

echo "Entri cron telah ditambahkan."
