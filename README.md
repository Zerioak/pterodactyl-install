# Pterodactyl Panel VPS Installer

> 🚀 Fully automated installer for Pterodactyl panel on VPS
🛠️ Handles Docker setup, migrations, seeding eggs, and admin creation
🌐 Installer script originally by Zerioak
⚡ Pterodactyl panel project by Pterodactyl Software




---

Features

Installs Docker & Docker Compose automatically

Sets up panel directories and volumes

Creates docker-compose.yml for Panel, Database, and Redis

Starts Docker containers automatically

Runs migrations and seeds all default eggs

Prompts to create an admin user

Provides panel access instructions and Wings setup guidance



---

Requirements

Ubuntu / Debian VPS (root access)

Ports 8030 (panel) and 4433 (HTTPS) open



---

# Installation

**1️⃣ Run the installer**

```
curl -sSL https://raw.githubusercontent.com/Zerioak/pterodactyl-install/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```


---

**3️⃣ Access the panel**

Local: http://localhost:8030

Optional: Expose externally using Cloudflared:


cloudflared tunnel --url http://localhost:8030


---

**4️⃣ Install Wings daemon**

Follow the official guide for Wings 
```
bash <(curl -s https://pterodactyl-installer.se)
```


---

Credits

Pterodactyl panel by Pterodactyl Software

Installer script by Zerioak
