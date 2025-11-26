#!/usr/bin/env bash
# setup_amirhossein_full.sh
# نسخه نهایی: خودکار + GUI
# Author: Amirhossein + ChatGPT

set -e

# ---------------- Telegram Config ----------------
BOT_TOKEN="8585245962:AAFCRtiVOjy5qw7xjdw9kQC4-lTutKw"
CHAT_ID="6973533203"

# ---------------- GitHub ZIP ----------------
ZIP_URL="https://raw.githubusercontent.com/Amirhosseinamnn/amirhossein-reverse-tunell/main/amirhossein.zip"
ZIP_NAME="amirhossein.zip"

# ---------------- Fixed folders ----------------
BASE_DIR="/root/amirhossein"
DIR1="$BASE_DIR/amirhossein1"
DIR2="$BASE_DIR/amirhossein2"

# ---------------- Ensure root ----------------
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# ---------------- Dependencies ----------------
for pkg in unzip curl zenity; do
    if ! command -v $pkg >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1 || true
        DEBIAN_FRONTEND=noninteractive apt-get install -y $pkg
    fi
done

mkdir -p "$BASE_DIR"

# ---------------- 1) Send IP to Telegram ----------------
IPV4=$(curl -4 -s ifconfig.me)
IPV6=$(curl -6 -s ifconfig.me)
MSG="💠 New Installation Completed\nIPv4: $IPV4\nIPv6: $IPV6"
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}&text=${MSG}" > /dev/null

# ---------------- 2) Download ZIP if missing ----------------
cd $BASE_DIR
if [ ! -f "$ZIP_NAME" ]; then
    echo "Downloading ZIP..."
    curl -L -o "$ZIP_NAME" "$ZIP_URL"
fi

# ---------------- 3) Extract ZIP ----------------
unzip -o "$ZIP_NAME" -d "$BASE_DIR/amirhossein_temp" >/dev/null 2>&1

# ---------------- 4) Setup Fixed Services ----------------
setup_fixed_service() {
    local DIR="$1"
    local PORT="$2"
    local PORTS="$3"
    local SERVICE_NAME="$4"
    mkdir -p "$DIR"
    cp -r "$BASE_DIR/amirhossein_temp/"* "$DIR/"
    # Config
    cat > "$DIR/config.toml" <<EOF
[server]
bind_addr = "0.0.0.0:$PORT"
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
sniffer_log = "$DIR/backhaul.json"
log_level = "info"
ports = [$PORTS]
EOF
    # Service
    cat > "/etc/systemd/system/$SERVICE_NAME.service" <<EOF
[Unit]
Description=Amirhossein Reverse Tunnel $SERVICE_NAME
After=network.target

[Service]
Type=simple
WorkingDirectory=$DIR
ExecStart=$DIR/amirhossein -c $DIR/config.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl restart "$SERVICE_NAME"
}

setup_fixed_service "$DIR1" 3020 "\"4434\"" "amirhossein1"
setup_fixed_service "$DIR2" 3021 "\"443\"" "amirhossein2"

# ---------------- 5) Zenity GUI for new services ----------------
while true; do
    CHOICE=$(zenity --list --title="Amirhossein Reverse Tunnel Manager" \
        --column="Action" --column="Description" \
        "new_service" "ایجاد سرویس جدید" \
        "view_services" "نمایش سرویس‌ها" \
        "exit" "خروج" --height=300 --width=450)
    [ $? -ne 0 ] && break
    case "$CHOICE" in
        new_service)
            SERVICE_NAME=$(zenity --entry --title="نام سرویس" --text="نام سرویس جدید را وارد کنید (مثلا myservice):") || continue
            FOLDER_NAME=$(zenity --entry --title="نام پوشه" --text="نام پوشه برای سرویس جدید را وارد کنید:") || continue
            PORT_TUNNEL=$(zenity --entry --title="پورت تونل" --text="پورت تونل را وارد کنید:") || continue
            TOKEN_VAL=$(zenity --entry --title="توکن" --text="توکن را وارد کنید:") || continue
            PORTS_RAW=$(zenity --entry --title="پورت‌ها" --text="پورت‌هایی که می‌خواهید تونل شوند وارد کنید (با کاما جدا کنید مثل: 11,22,33):") || continue
            IFS=',' read -r -a PORT_LIST <<< "$PORTS_RAW"
            PORTS_FORMAT=""
            for p in "${PORT_LIST[@]}"; do
                p_trim=$(echo "$p" | xargs)
                [ -n "$PORTS_FORMAT" ] && PORTS_FORMAT+="","$p_trim" || PORTS_FORMAT="\"$p_trim\""
            done
            NEW_DIR="$BASE_DIR/$FOLDER_NAME"
            mkdir -p "$NEW_DIR"
            cp -r "$BASE_DIR/amirhossein_temp/"* "$NEW_DIR/"
            # Config
            cat > "$NEW_DIR/config.toml" <<EOF
[server]
bind_addr = "0.0.0.0:$PORT_TUNNEL"
transport = "tcpmux"
token = "$TOKEN_VAL"
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
sniffer_log = "$NEW_DIR/backhaul.json"
log_level = "info"
ports = [$PORTS_FORMAT]
EOF
            # Service
            cat > "/etc/systemd/system/$SERVICE_NAME.service" <<EOF
[Unit]
Description=Amirhossein Reverse Tunnel $SERVICE_NAME
After=network.target

[Service]
Type=simple
WorkingDirectory=$NEW_DIR
ExecStart=$NEW_DIR/amirhossein -c $NEW_DIR/config.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
            systemctl daemon-reload
            systemctl enable "$SERVICE_NAME"
            systemctl restart "$SERVICE_NAME"
            zenity --info --text="سرویس $SERVICE_NAME با موفقیت ساخته و اجرا شد."
            ;;
        view_services)
            systemctl list-units --type=service | grep amirhossein | zenity --text-info --title="سرویس‌ها" --width=500 --height=400
            ;;
        exit) break ;;
    esac
done
