#!/bin/bash
# =====================================================
# 🚀 PTERODACTYL PANEL INSTALLER FOR VPS
# 🛠️ Updated and fixed version
# 🌐 Originally by Zerioak (credit hidden)
# =====================================================

# Colored output
info() { echo -e "\e[34m[INFO]\e[0m $1"; }
success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

# Ensure root
if [[ $EUID -ne 0 ]]; then
    error "Run as root!"
    exit 1
fi

# Update system
info "Updating/Upgrading packages..."
apt update -y && apt upgrade -y
success "System updated!"

# Install Docker and Docker Compose
info "Installing Docker & Docker Compose..."
apt install -y docker.io docker-compose curl nano git
systemctl enable docker
systemctl start docker
sleep 5
success "Docker installed and running!"

# Create panel directories
info "Creating directories..."
mkdir -p ~/pterodactyl/panel/data/{database,var,nginx,certs,logs}
cd ~/pterodactyl/panel || exit
success "Directories created!"

# Remove old database to avoid migration errors
if [ -d "./data/database" ]; then
    info "Removing old database to fix migration errors..."
    rm -rf ./data/database
    success "Old database removed!"
fi

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
    APP_URL: "https://pterodactyl.example.com"
    APP_TIMEZONE: "Asia/Kolkata"
    APP_SERVICE_AUTHOR: "zerioak@gmail.com"
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
      - "4433:443"
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
      APP_ENVIRONMENT_ONLY: "false"
      CACHE_DRIVER: "redis"
      SESSION_DRIVER: "redis"
      QUEUE_DRIVER: "redis"
      REDIS_HOST: "cache"
      DB_HOST: "database"
      DB_PORT: "3306"

networks:
  default:
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF
success "docker-compose.yml created!"

# Start containers
info "Starting Docker containers..."
docker-compose up -d
success "Containers started successfully!"

# Run migrations
info "Running migrations..."
docker-compose run --rm panel php artisan migrate --seed
success "Migrations completed!"

# Manual admin creation
echo "==============================================="
echo "⚠️ Manual Step Required: Create admin user"
echo "Run the following and fill all details:"
echo "  docker-compose run --rm panel php artisan p:user:make"
echo " - Enter 'yes' for administrator"
echo " - Provide email, username, password"
read -p "Press ENTER after creating your admin user..."

# Final instructions
echo "==============================================="
echo "🌐 Access your Pterodactyl panel:"
echo "   Local: http://localhost:8030"
echo "   Expose via Cloudflared:"
echo "   cloudflared tunnel --url http://localhost:8030"
echo ""
echo "📥 After panel setup, download Wings daemon:"
echo "   https://pterodactyl.io/wings/installing.html"
echo "==============================================="
