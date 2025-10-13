#!/bin/bash
# =====================================================
# 🚀 PTERODACTYL PANEL CLEAN INSTALLER - FULL AUTO FLOW
# 🛠️ Fully automated, clean DB, user creation continues
# =====================================================

info() { echo -e "\e[34m[INFO]\e[0m $1"; }
success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

if [[ $EUID -ne 0 ]]; then
    error "Run this script as root!"
    exit 1
fi

# Update packages
info "Updating system..."
apt update -y && apt upgrade -y
success "System updated!"

# Install Docker
info "Installing Docker & dependencies..."
apt install -y docker.io docker-compose curl nano git
systemctl enable docker
systemctl start docker
success "Docker ready!"

# Prepare directories
info "Setting up directories..."
mkdir -p ~/pterodactyl/panel/data/{database,var,nginx,certs,logs}
cd ~/pterodactyl/panel || exit
success "Directories created!"

# Stop old containers
info "Stopping any existing panel containers..."
docker-compose down >/dev/null 2>&1

# Clean database to avoid migration errors
info "Cleaning old data to prevent duplicate column issues..."
rm -rf ./data/database ./data/var ./data/logs
mkdir -p ./data/database ./data/var ./data/logs
success "Old DB and logs cleared!"

# Create docker-compose.yml
info "Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

x-common:
  database:
    &db-environment
    MYSQL_PASSWORD: &db-password "CHANGE_ME"
    MYSQL_ROOT_PASSWORD: "CHANGE_ME_TOO"
  panel:
    &panel-environment
    APP_URL: "http://localhost"
    APP_TIMEZONE: "Asia/Kolkata"
    TRUSTED_PROXIES: "*"
  mail:
    &mail-environment
    MAIL_FROM: "noreply@example.com"
    MAIL_DRIVER: "smtp"
    MAIL_HOST: "mail"
    MAIL_PORT: "1025"
    MAIL_USERNAME: ""
    MAIL_PASSWORD: ""
    MAIL_ENCRYPTION: "true"

services:
  database:
    image: mariadb:10.5
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - "./data/database:/var/lib/mysql"
    environment:
      <<: *db-environment
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    ports:
      - "8030:80"
    links:
      - database
      - cache
    volumes:
      - "./data/var:/app/var"
      - "./data/nginx:/etc/nginx/http.d"
      - "./data/certs:/etc/letsencrypt"
      - "./data/logs:/app/storage/logs"
    environment:
      <<: [*panel-environment, *mail-environment]
      DB_PASSWORD: *db-password
      APP_ENV: "production"
      CACHE_DRIVER: "redis"
      SESSION_DRIVER: "redis"
      QUEUE_DRIVER: "redis"
      REDIS_HOST: "cache"
      DB_HOST: "database"
      DB_PORT: "3306"
EOF

success "docker-compose.yml ready!"

# Start containers
info "Launching Docker containers..."
docker-compose up -d
sleep 15
success "Containers started!"

# Run migrations
info "Running migrations..."
docker-compose run --rm panel php artisan migrate --force
docker-compose run --rm panel php artisan db:seed --force
success "Migrations complete!"

# Auto user creation prompt without stopping
info "Now creating admin user. Fill email, username, password, and type YES when asked for admin."
docker-compose run --rm panel php artisan p:user:make

# Final message
echo "==============================================="
echo "🎉 Setup Complete!"
echo "🌍 Visit: http://<YOUR-IP>:8030"
echo "⚠️ If behind Cloudflare Tunnel, run:"
echo "   cloudflared tunnel --url http://localhost:8030"
echo "==============================================="
