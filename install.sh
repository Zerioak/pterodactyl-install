#!/bin/bash
# =====================================================
# 🚀 PTERODACTYL PANEL INSTALLER - INTERACTIVE
# 🛠️ Fully automated after user inputs
# =====================================================

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

info() { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Ensure root
if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root!"
    exit 1
fi

# -----------------------------
# Interactive admin setup
# -----------------------------
echo -e "${CYAN}[?] Enter admin email:${NC}"
read ADMIN_EMAIL

echo -e "${CYAN}[?] Enter admin username:${NC}"
read ADMIN_USERNAME

echo -e "${CYAN}[?] Enter admin first name:${NC}"
read ADMIN_FIRSTNAME

echo -e "${CYAN}[?] Enter admin last name:${NC}"
read ADMIN_LASTNAME

echo -e "${CYAN}[?] Enter admin password:${NC}"
read -s ADMIN_PASSWORD
echo

# -----------------------------
# System update & Docker install
# -----------------------------
info "Updating system..."
apt update -y && apt upgrade -y
success "System updated!"

info "Installing Docker & dependencies..."
apt install -y docker.io docker-compose curl git nano
systemctl enable docker
systemctl start docker
success "Docker ready!"

# -----------------------------
# Setup panel directories
# -----------------------------
info "Creating panel directories..."
mkdir -p ~/pterodactyl/panel/data/{database,var,nginx,certs,logs}
cd ~/pterodactyl/panel || exit
success "Directories ready!"

# Stop old containers and clean old data
info "Stopping old containers and cleaning old DB/logs..."
docker-compose down >/dev/null 2>&1
rm -rf ./data/database ./data/var ./data/logs
mkdir -p ./data/database ./data/var ./data/logs
success "Old data cleaned!"

# -----------------------------
# Create docker-compose.yml
# -----------------------------
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

networks:
  default:
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

success "docker-compose.yml created!"

# -----------------------------
# Start Docker containers
# -----------------------------
info "Starting Docker containers..."
docker-compose up -d
sleep 15
success "Containers started!"

# -----------------------------
# Run migrations & seed
# -----------------------------
info "Running migrations & seed..."
docker-compose run --rm panel php artisan migrate --force
docker-compose run --rm panel php artisan db:seed --force
success "Migrations & seeds completed!"

# -----------------------------
# Create admin user interactively
# -----------------------------
info "Creating admin user..."
docker-compose run --rm panel php artisan tinker <<EOT
\$user = new \App\Models\User();
\$user->email = "$ADMIN_EMAIL";
\$user->username = "$ADMIN_USERNAME";
\$user->name_first = "$ADMIN_FIRSTNAME";
\$user->name_last = "$ADMIN_LASTNAME";
\$user->root_admin = true;
\$user->password = bcrypt("$ADMIN_PASSWORD");
\$user->save();
EOT

success "Admin user created!"

# -----------------------------
# Finish
# -----------------------------
echo "==============================================="
echo "🎉 Pterodactyl Panel Installed Successfully!"
echo "🔗 Panel URL: http://<YOUR_SERVER_IP>:8030"
echo "📧 Admin Email: $ADMIN_EMAIL"
echo "🔑 Admin Password: $ADMIN_PASSWORD"
echo "==============================================="
