#!/bin/bash

echo "Downloading main setup script..."
curl -L -o setup_amirhossein_final.sh https://raw.githubusercontent.com/Amirhosseinamnn/amirhossein-reverse-tunell/main/setup_amirhossein_final.sh

chmod +x setup_amirhossein_final.sh

echo "Running installer..."
sudo ./setup_amirhossein_final.sh
