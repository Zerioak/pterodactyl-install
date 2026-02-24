#!/bin/bash
set -e

# =====================================================
# 🚀 PTERODACTYL PANEL INSTALLER (UPGRADED)
# 🧠 Smart • Secure • Stable • Interactive
# 👑 Credits: Zerioak + GPT (Upgraded Edition)
# =====================================================

# -----------------------------
# Colors
# -----------------------------
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BASE_DIR="/opt/pterodactyl"
PANEL_DIR="$BASE_DIR/panel"

# -----------------------------
# Header
# -----------------------------
clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║        🚀 PTERODACTYL PANEL INSTALLER             ║"
echo "║        👑 Zerioak x GPT | Upgraded Edition         ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
sleep 1

# -----------------------------
# Spinner
# -----------------------------
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

# -----------------------------
# Root Check
# -----------------------------
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Run as root!${NC}"
    exit 1
fi

# -----------------------------
# Detect IP
# -----------------------------
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# -----------------------------
# Admin Setup
# -----------------------------
read -p "📧 Admin Email: " ADMIN_EMAIL
read -p "👤 Username: " ADMIN_USERNAME
read -p "🧑 First Name: " ADMIN_FIRSTNAME
read -p "🧑 Last Name: " ADMIN_LASTNAME
read -s -p "🔑 Password: " ADMIN_PASSWORD
echo

# -----------------------------
# Auto Secure Passwords
# -----------------------------
DB_PASS=$(openssl rand -base64 24)
DB_ROOT_PASS=$(openssl rand -base64 32)

# -----------------------------
# Install Dependencies
# -----------------------------
run_cmd "System update" "apt update -y && apt upgrade -y"
run_cmd "Installing dependencies" "apt install -y ca-certificates curl gnupg lsb-release nano git unzip"

# -----------------------------
# Docker Install Check
# -----------------------------
if ! command -v docker &> /dev/null; then
    run_cmd "Installing Docker" "apt install -y docker.io"
    systemctl enable docker
    systemctl start docker
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    run_cmd "Installing Docker Compose" "apt install -y docker-compose"
fi

# -----------------------------
# Directories
# -----------------------------
run_cmd "Creating directories" "mkdir -p $PANEL_DIR/data/{database,var,nginx,certs,logs}"
cd $PANEL_DIR

# -----------------------------
# Cleanup old
# -----------------------------
docker compose down >/dev/null 2>&1 || true
rm -rf ./data/database ./data/var ./data/logs
mkdir -p ./data/database ./data/var ./data/logs

# -----------------------------
# docker-compose.yml
# -----------------------------
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

# -----------------------------
# Start Containers
# -----------------------------
run_cmd "Starting containers" "docker compose up -d"
sleep 15

# -----------------------------
# Setup Panel
# -----------------------------
run_cmd "Running migrations" "docker compose run --rm panel php artisan migrate --force"
run_cmd "Seeding database" "docker compose run --rm panel php artisan db:seed --force"

# -----------------------------
# Create Admin
# -----------------------------
docker compose run --rm panel php artisan p:user:make \
  --email="$ADMIN_EMAIL" \
  --username="$ADMIN_USERNAME" \
  --name-first="$ADMIN_FIRSTNAME" \
  --name-last="$ADMIN_LASTNAME" \
  --password="$ADMIN_PASSWORD" \
  --admin

# -----------------------------
# Finish
# -----------------------------
echo -e "${GREEN}"
echo "===================================================="
echo "🎉 PTERODACTYL PANEL INSTALLED SUCCESSFULLY!"
echo "🌐 Panel URL : http://${SERVER_IP}:8030"
echo "📧 Email     : $ADMIN_EMAIL"
echo "👤 Username  : $ADMIN_USERNAME"
echo "🔐 Password  : (hidden for security)"
echo "🛡️ DB Pass   : $DB_PASS"
echo "===================================================="
echo -e "${NC}"
