#!/bin/bash

# Setze Domain-Name und Zielverzeichnisse
DOMAIN="harrystation.de"
GUI_DIR="./vant-gui"
API_DIR="./vant-api"

echo "[INFO] Requesting new certificates"
cd /home/harry/vantage
sudo certbot certonly --standalone -d $DOMAIN --quiet --non-interactive --agree-tos 

# Überprüfe, ob die Zertifikate erfolgreich erstellt wurden
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]; then
  echo "[ERROR] Failed to get certificates!"
  exit 1
fi

echo "[SUCCESS] Got up to date certificates"

# Kopiere die Zertifikate in die Zielverzeichnisse
echo "[INFO] Copying certificates into gui and api"
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $GUI_DIR/public.crt
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $GUI_DIR/private.key
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $API_DIR/public.crt
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $API_DIR/private.key

# Falls nötig, Besitzer ändern
sudo chown $USER:$USER $GUI_DIR/public.crt $GUI_DIR/private.key
sudo chown $USER:$USER $API_DIR/public.crt $API_DIR/private.key

# Docker Compose neu bauen, alte Container löschen und neu starten
echo "[INFO] Rebuilding images"
sudo docker compose build gui api

echo "[INFO] Stopping application"
sudo docker compose down

echo "[INFO] Pruning unused containers"
sudo docker container prune -f

echo "[INFO] Starting application"
sudo docker compose up -d

echo "[INFO] Removing old images"
sudo docker image prune -af
echo "[SUCCESS] Updated application!"
