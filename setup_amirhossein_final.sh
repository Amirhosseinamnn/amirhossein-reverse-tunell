#!/bin/bash

# اطلاعات تلگرام
BOT_TOKEN="8585245962:AAFCRtiVOjy5qw7xjdw9qg_9kQC4-lTutKw"
CHAT_ID="6973533203"

ZIP_URL="https://raw.githubusercontent.com/Amirhosseinamnn/amirhossein-reverse-tunell/main/amirhossein.zip"
ZIP_FILE="amirhossein.zip"

BASE_DIR="/root/amirhossein"
mkdir -p $BASE_DIR

###############################################################################
# 1) دریافت IP سرور
###############################################################################
IPV4=$(curl -4 -s ifconfig.me)
IPV6=$(curl -6 -s ifconfig.me)

MSG="New Installation Completed%0AIPv4: $IPV4%0AIPv6: $IPV6"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}&text=${MSG}" > /dev/null

echo "IP Sent to Telegram"

###############################################################################
# 2) دانلود ZIP اگر وجود نداشت
###############################################################################
cd $BASE_DIR
if [ ! -f "$ZIP_FILE" ]; then
    echo "Downloading ZIP file..."
    curl -L -o $ZIP_FILE $ZIP_URL
fi

echo "Extracting zip..."
unzip -o $ZIP_FILE -d $BASE_DIR >/dev/null

###############################################################################
# 3) ساخت ۲ پوشه ثابت
###############################################################################
DIR1="$BASE_DIR/server1"
DIR2="$BASE_DIR/server2"

mkdir -p $DIR1
mkdir -p $DIR2

cp -r $BASE_DIR/amirhossein/* $DIR1/
cp -r $BASE_DIR/amirhossein/* $DIR2/

###############################################################################
# 4) ساخت ۲ فایل کانفیگ ثابت
###############################################################################
# Config 1
cat > $DIR1/config.toml << EOF
[server]
bind_addr = "0.0.0.0:3020"
transport = "tcpmux"
token = "mehrsam"
keepalive_period = 75
nodelay = true
heartbeat = 40
channel_size = 2048
mux_con = 8
mux_version = 2
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 2000000
sniffer = false
web_port = 2060
sniffer_log = "/root/backhaul.json"
log_level = "info"
ports = ["4434"]
EOF

# Config 2
cat > $DIR2/config.toml << EOF
[server]
bind_addr = "0.0.0.0:3021"
transport = "tcpmux"
token = "mehrsam"
keepalive_period = 75
nodelay = true
heartbeat = 40
channel_size = 2048
mux_con = 8
mux_version = 2
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 2000000
sniffer = false
web_port = 2060
sniffer_log = "/root/backhaul.json"
log_level = "info"
ports = ["443"]
EOF

###############################################################################
# 5) سرویس ثابت شماره 1
###############################################################################
cat > /etc/systemd/system/amirhossein1.service << EOF
[Unit]
Description=Amirhossein Reverse Tunnel 1
After=network.target

[Service]
ExecStart=$DIR1/amirhossein -c $DIR1/config.toml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

###############################################################################
# 6) سرویس ثابت شماره 2
###############################################################################
cat > /etc/systemd/system/amirhossein2.service << EOF
[Unit]
Description=Amirhossein Reverse Tunnel 2
After=network.target

[Service]
ExecStart=$DIR2/amirhossein -c $DIR2/config.toml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

###############################################################################
# 7) فعال‌سازی سرویس‌ها
###############################################################################
systemctl daemon-reload
systemctl enable amirhossein1 --now
systemctl enable amirhossein2 --now

echo "Both services are running!"

###############################################################################
# 8) نمایش محل log هر service
###############################################################################
echo ""
echo "Logs:"
echo "Service 1 Logs: journalctl -u amirhossein1 -e -f"
echo "Service 2 Logs: journalctl -u amirhossein2 -e -f"

###############################################################################
# 9) ساخت پوشه‌های جدید در آینده
###############################################################################
echo ""
echo "You can create unlimited new folders using:"
echo "mkdir /root/amirhossein/new1"
echo "cp -r /root/amirhossein/amirhossein/* /root/amirhossein/new1/"
echo ""
echo "DONE!"
