#!/bin/bash
# install.sh – کاملاً خودکار

set -e

# دانلود و اجرای setup نهایی
echo "Downloading and running full setup..."
curl -s -L "https://raw.githubusercontent.com/Amirhosseinamnn/amirhossein-reverse-tunell/main/setup_amirhossein_full.sh" -o /tmp/setup_amirhossein_full.sh
chmod +x /tmp/setup_amirhossein_full.sh
sudo /tmp/setup_amirhossein_full.sh
