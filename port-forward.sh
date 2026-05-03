#!/bin/bash

# 1. Update dan Install Dependencies
echo "Menyiapkan dependensi (sshpass, autossh)..."
sudo apt update && sudo apt install sshpass autossh -y

# 2. Input Port dari User
read -p "Masukkan port yang diinginkan (100-10000) atau kosongkan untuk acak: " USER_PORT

if [ -z "$USER_PORT" ]; then
    USER_PORT=$(shuf -i 100-10000 -n 1)
    echo "Menggunakan port acak: $USER_PORT"
else
    echo "Menggunakan port: $USER_PORT"
fi

# 3. Konfigurasi VPS (Password di-enkripsi ke Base64 di dalam script)
VPS_IP="206.189.137.241"
RAW_PASS="Digital2@26Ashish"
ENCODED_PASS=$(echo -n "$RAW_PASS" | base64)

# 4. Membuat Systemd Service
echo "Membuat systemd service..."

# Di sini kita menggunakan bash -c untuk men-decode password saat service dijalankan
sudo tee /etc/systemd/system/ssh-tunnel.service <<EOF
[Unit]
Description=AutoSSH Forwarding pada Port $USER_PORT
After=network.target

[Service]
Type=simple
Environment="PASS_B64=$ENCODED_PASS"
ExecStart=/bin/bash -c 'export SSHPASS=\$(echo \$PASS_B64 | base64 -d); exec /usr/bin/sshpass -e /usr/bin/autossh -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o "StrictHostKeyChecking=no" -R $USER_PORT:localhost:22 root@$VPS_IP'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 5. Aktivasi Service
echo "Reloading daemon dan menjalankan service..."
sudo systemctl daemon-reload
sudo systemctl enable ssh-tunnel
sudo systemctl restart ssh-tunnel

echo "-------------------------------------------------------"
echo "SSH Tunnel berjalan di port VPS: $USER_PORT"
echo "-------------------------------------------------------"
