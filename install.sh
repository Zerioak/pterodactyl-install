#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# 🚀 PTERODACTYL PANEL INSTALLER
# 🛠️ Developed by Zerioak
# 🌐 GitHub: https://github.com/Zerioak/pterodactyl-install
# (Credit hidden from Termux output)
# =====================================================

# Colored output functions
info() { echo -e "\e[34m[INFO]\e[0m $1"; }
success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

# 0️⃣ Ensure running in Termux
if [ -z "$PREFIX" ]; then
    error "This script is optimized for Termux only!"
    exit 1
fi

# 1️⃣ Update packages
info "Updating Termux packages..."
pkg update -y && pkg upgrade -y
success "System updated!"

# 2️⃣ Install dependencies
info "Installing dependencies..."
pkg install -y root-repo x11-repo curl git nano wget proot-distro
success "Dependencies installed!"

# 3️⃣ Install Docker (Termux requires proot-distro Ubuntu)
info "Setting up Docker in Ubuntu proot-distro..."
proot-distro install ubuntu-22.04
proot-distro login ubuntu-22.04 -- bash << 'EOL'
apt update -y && apt upgrade -y
apt install -y docker.io docker-compose nano git curl
EOL
success "Docker installed in Ubuntu distro!"

# 4️⃣ Create directories
info "Creating Pterodactyl directories..."
mkdir -p ~/pterodactyl/panel/data
cd ~/pterodactyl/panel || exit
success "Directories created!"

# 5️⃣ Create docker-compose.yml
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
    APP_SERVICE_AUTHOR: "noreply@gmail.com"
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

# 6️⃣ Create subfolders
info "Creating data subfolders..."
mkdir -p ./data/{database,var,nginx,certs,logs}
success "Subfolders created!"

# 7️⃣ Start containers
info "Starting Docker containers..."
proot-distro login ubuntu-22.04 -- docker-compose up -d
success "Containers started successfully!"

# 8️⃣ Run migrations
info "Running database migrations..."
proot-distro login ubuntu-22.04 -- docker-compose run --rm panel php artisan migrate --seed
success "✅ Migrations completed!"

# 9️⃣ Manual admin creation
echo "==============================================="
echo "⚠️ Manual Step Required:"
echo "Run the following to create admin user manually:"
echo "  proot-distro login ubuntu-22.04 -- docker-compose run --rm panel php artisan p:user:make"
echo "Enter 'yes' for admin, provide email, username, password."
read -p "Press ENTER after creating your admin user..."

# 🔟 Final instructions
echo "==============================================="
echo "🌐 Access your Pterodactyl panel:"
echo "   Local: http://localhost:8030"
echo "   Expose via Cloudflared tunnel:"
echo "   cloudflared tunnel --url http://localhost:8030"
echo ""
echo "📥 After panel setup, download Wings daemon from:"
echo "   https://pterodactyl.io/wings/installing.html"
echo "==============================================="
