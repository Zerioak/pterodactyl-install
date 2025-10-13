#!/bin/bash
set -e

# =====================================================
# 🚀 PTERODACTYL PANEL INSTALLER - INTERACTIVE & FIXED
# 🛠️ Terminal header, spinner, and credits added
# 💡 Original install method by Zerioak
# =====================================================

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Clear terminal and show header
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════╗"
echo "║      PTERODACTYL PANEL INSTALLER 🚀      ║"
echo "║      Script by GPT & Zerioak       ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"
sleep 2

# -----------------------------
# Spinner function
# -----------------------------
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

run_cmd() {
    echo -ne "${YELLOW}[~] $1...${NC}"
    bash -c "$2" >/dev/null 2>&1 &
    spinner $!
    echo -e "${GREEN} [OK]${NC}"
}

# -----------------------------
# Ensure script is run as root
# -----------------------------
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Run this script as root!${NC}"
    exit 1
fi

# -----------------------------
# Interactive admin setup
# -----------------------------
while [[ -z "$ADMIN_EMAIL" ]]; do
    echo -e "${CYAN}[?] Enter admin email:${NC}"
    read ADMIN_EMAIL
done

while [[ -z "$ADMIN_USERNAME" ]]; do
    echo -e "${CYAN}[?] Enter admin username:${NC}"
    read ADMIN_USERNAME
done

while [[ -z "$ADMIN_FIRSTNAME" ]]; do
    echo -e "${CYAN}[?] Enter admin first name:${NC}"
    read ADMIN_FIRSTNAME
done

while [[ -z "$ADMIN_LASTNAME" ]]; do
    echo -e "${CYAN}[?] Enter admin last name:${NC}"
    read ADMIN_LASTNAME
done

while [[ -z "$ADMIN_PASSWORD" ]]; do
    echo -e "${CYAN}[?] Enter admin password:${NC}"
    read -s ADMIN_PASSWORD
    echo
done

# -----------------------------
# System update & Docker install
# -----------------------------
run_cmd "Updating system" "apt update -y && apt upgrade -y"
run_cmd "Installing Docker" "apt install -y docker.io && systemctl enable docker && systemctl start docker"
run_cmd "Installing Docker-Compose" "apt install -y docker-compose"
run_cmd "Installing Nano" "apt install -y nano"
run_cmd "Installing other dependencies" "apt install -y curl git"

# -----------------------------
# Setup panel directories
# -----------------------------
run_cmd "Creating panel directories" "mkdir -p ~/pterodactyl/panel/data/{database,var,nginx,certs,logs} && cd ~/pterodactyl/panel"

# Stop old containers and clean old data
run_cmd "Stopping old containers and cleaning old data" "docker-compose down >/dev/null 2>&1; rm -rf ./data/database ./data/var ./data/logs; mkdir -p ./data/database ./data/var ./data/logs"

# -----------------------------
# Create docker-compose.yml
# -----------------------------
run_cmd "Creating docker-compose.yml" "cat > docker-compose.yml << 'EOF'
version: '3.8'

x-common:
  database:
    &db-environment
    MYSQL_PASSWORD: &db-password \"CHANGE_ME\"
    MYSQL_ROOT_PASSWORD: \"CHANGE_ME_TOO\"
  panel:
    &panel-environment
    APP_URL: \"http://localhost\"
    APP_TIMEZONE: \"Asia/Kolkata\"
    TRUSTED_PROXIES: \"*\"
  mail:
    &mail-environment
    MAIL_FROM: \"noreply@example.com\"
    MAIL_DRIVER: \"smtp\"
    MAIL_HOST: \"mail\"
    MAIL_PORT: \"1025\"
    MAIL_USERNAME: \"\"
    MAIL_PASSWORD: \"\"
    MAIL_ENCRYPTION: \"true\"

services:
  database:
    image: mariadb:10.5
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - \"./data/database:/var/lib/mysql\"
    environment:
      <<: *db-environment
      MYSQL_DATABASE: \"panel\"
      MYSQL_USER: \"pterodactyl\"

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    ports:
      - \"8030:80\"
    links:
      - database
      - cache
    volumes:
      - \"./data/var:/app/var\"
      - \"./data/nginx:/etc/nginx/http.d\"
      - \"./data/certs:/etc/letsencrypt\"
      - \"./data/logs:/app/storage/logs\"
    environment:
      <<: [*panel-environment, *mail-environment]
      DB_PASSWORD: *db-password
      APP_ENV: \"production\"
      CACHE_DRIVER: \"redis\"
      SESSION_DRIVER: \"redis\"
      QUEUE_DRIVER: \"redis\"
      REDIS_HOST: \"cache\"
      DB_HOST: \"database\"
      DB_PORT: \"3306\"

networks:
  default:
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF"

# -----------------------------
# Start Docker containers
# -----------------------------
run_cmd "Starting Docker containers" "docker-compose up -d; sleep 15"

# -----------------------------
# Run migrations & seed
# -----------------------------
run_cmd "Running migrations & seed" "docker-compose run --rm panel php artisan migrate --force; docker-compose run --rm panel php artisan db:seed --force"

# -----------------------------
# Create admin user
# -----------------------------
run_cmd "Creating admin user" "docker-compose run --rm panel php artisan p:user:make \
    --email=\"$ADMIN_EMAIL\" \
    --username=\"$ADMIN_USERNAME\" \
    --name-first=\"$ADMIN_FIRSTNAME\" \
    --name-last=\"$ADMIN_LASTNAME\" \
    --password=\"$ADMIN_PASSWORD\" \
    --admin"

# -----------------------------
# Finish
# -----------------------------
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}🎉 Pterodactyl Panel Installed Successfully!${NC}"
echo -e "${CYAN}🔗 Panel URL: cloudflared tunnel --url http://localhost:8030 or http://<YOUR_SERVER_IP>:8030${NC}"
echo -e "${CYAN}📧 Admin Email: $ADMIN_EMAIL${NC}"
echo -e "${CYAN}🔑 Admin Password: $ADMIN_PASSWORD${NC}"
echo -e "${YELLOW}💡 Script Credit: Zerioak & GPT${NC}"
echo -e "${GREEN}===============================================${NC}"
