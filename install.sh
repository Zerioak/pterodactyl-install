#!/bin/bash
set -e

# =====================================================
# 🚀 PTERODACTYL PANEL + 🪽 WINGS AUTO INSTALLER
# 👑 Zerioak x GPT | ALL-IN-ONE Edition
# =====================================================

# ---------------- Colors ----------------
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BASE_DIR="/opt/pterodactyl"
PANEL_DIR="$BASE_DIR/panel"

clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║   🚀 PTERODACTYL PANEL + 🪽 WINGS INSTALLER         ║"
echo "║          👑 Zerioak x GPT | Full Auto               ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ---------------- Spinner ----------------
spinner() {
    local pid=$1
    local delay=0.1
    local spin='|/-\'
    while kill -0 $pid 2>/dev/null; do
        for i in {0..3}; do
            printf "\r${YELLOW}[~] %c${NC}" "${spin:$i:1}"
            sleep $delay
        done
    done
    printf "\r"
}

run_cmd() {
    echo -ne "${YELLOW}[~] $1...${NC}"
    bash -c "$2" >/dev/null 2>&1 &
    spinner $!
    echo -e "${GREEN} [OK]${NC}"
}

# ---------------- Root Check ----------------
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Run as root!${NC}"
    exit 1
fi

# ---------------- Detect IP ----------------
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo -e "${CYAN}[+] Server IP: $SERVER_IP${NC}"

# ---------------- Admin Setup ----------------
read -p "📧 Admin Email: " ADMIN_EMAIL
read -p "👤 Username: " ADMIN_USERNAME
read -p "🧑 First Name: " ADMIN_FIRSTNAME
read -p "🧑 Last Name: " ADMIN_LASTNAME
read -s -p "🔑 Password: " ADMIN_PASSWORD
echo

# ---------------- Auto Passwords ----------------
DB_PASS=$(openssl rand -base64 24)
DB_ROOT_PASS=$(openssl rand -base64 32)

# ---------------- Dependencies ----------------
run_cmd "System update" "apt update -y && apt upgrade -y"
run_cmd "Installing dependencies" "apt install -y ca-certificates curl gnupg lsb-release nano git unzip ufw"

# ---------------- Docker ----------------
if ! command -v docker &>/dev/null; then
    run_cmd "Installing Docker" "apt install -y docker.io"
    systemctl enable docker
    systemctl start docker
fi

if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
    run_cmd "Installing Docker Compose" "apt install -y docker-compose"
fi

# ---------------- Firewall ----------------
ufw allow 22
ufw allow 8030
ufw allow 8080
ufw allow 2022
ufw --force enable

# ---------------- Panel Directories ----------------
run_cmd "Creating directories" "mkdir -p $PANEL_DIR/data/{database,var,nginx,certs,logs}"
cd $PANEL_DIR

# ---------------- Docker Compose ----------------
cat > docker-compose.yml << EOF
version: '3.8'

services:
  database:
    image: mariadb:10.11
    restart: always
    environment:
      MYSQL_DATABASE: panel
      MYSQL_USER: pterodactyl
      MYSQL_PASSWORD: ${DB_PASS}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASS}
    volumes:
      - ./data/database:/var/lib/mysql

  cache:
    image: redis:7-alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    ports:
      - "8030:80"
    depends_on:
      - database
      - cache
    volumes:
      - ./data/var:/app/var
      - ./data/nginx:/etc/nginx/http.d
      - ./data/certs:/etc/letsencrypt
      - ./data/logs:/app/storage/logs
    environment:
      APP_ENV: production
      APP_URL: http://${SERVER_IP}:8030
      APP_TIMEZONE: Asia/Kolkata
      TRUSTED_PROXIES: "*"
      DB_HOST: database
      DB_PORT: 3306
      DB_DATABASE: panel
      DB_USERNAME: pterodactyl
      DB_PASSWORD: ${DB_PASS}
      CACHE_DRIVER: redis
      SESSION_DRIVER: redis
      QUEUE_DRIVER: redis
      REDIS_HOST: cache
EOF

# ---------------- Start Panel ----------------
run_cmd "Starting Panel" "docker compose up -d"
sleep 15

run_cmd "Panel migrate" "docker compose run --rm panel php artisan migrate --force"
run_cmd "Panel seed" "docker compose run --rm panel php artisan db:seed --force"

docker compose run --rm panel php artisan p:user:make \
  --email="$ADMIN_EMAIL" \
  --username="$ADMIN_USERNAME" \
  --name-first="$ADMIN_FIRSTNAME" \
  --name-last="$ADMIN_LASTNAME" \
  --password="$ADMIN_PASSWORD" \
  --admin

# =====================================================
# 🪽 WINGS AUTO SETUP
# =====================================================

echo -e "${CYAN}[+] Installing Wings...${NC}"

mkdir -p /etc/pterodactyl /var/lib/pterodactyl /var/log/pterodactyl /tmp/pterodactyl

curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod +x /usr/local/bin/wings

cat > /etc/systemd/system/wings.service << EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
ExecStart=/usr/local/bin/wings
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wings

# ---------------- Finish ----------------
echo -e "${GREEN}"
echo "===================================================="
echo "🎉 PANEL + WINGS INSTALLED SUCCESSFULLY!"
echo ""
echo "🌐 Panel URL : http://${SERVER_IP}:8030"
echo "📧 Email     : $ADMIN_EMAIL"
echo "👤 Username  : $ADMIN_USERNAME"
echo "🔐 Password  : (hidden)"
echo ""
echo "🪽 Wings:"
echo "📂 Config Path: /etc/pterodactyl/config.yml"
echo "➡️ Panel → Nodes → Create Node → Copy config.yml"
echo "➡️ Paste in: /etc/pterodactyl/config.yml"
echo "➡️ Run: systemctl start wings"
echo ""
echo "🔥 FULL AUTO STACK READY"
echo "===================================================="
echo -e "${NC}"
