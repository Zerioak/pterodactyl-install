<div align="center">

# 🎮 **Pterodactyl Panel VPS Installer – IdkNodes VPS**

![Docker](https://img.shields.io/badge/Docker-Automated-blue)
![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Panel-green)
![Auto Install](https://img.shields.io/badge/Installer-Fully%20Automated-orange)
![Made with ❤️](https://img.shields.io/badge/Made%20with-❤️-ff69b4)

</div>

> A **fully automated VPS installer** for the **Pterodactyl Game Panel** on ExtremeNodes VPS — designed for **speed**, **simplicity**, and **zero manual configuration**.

---

## ✨ **Features**

✅ **Installs Docker & Docker Compose automatically**  
✅ **Sets up all directories and volumes automatically**  
✅ **Generates docker-compose.yml for Panel, MariaDB & Redis**  
✅ **Starts all required Docker containers instantly**  
✅ **Runs database migrations and seeds default eggs automatically**  
✅ **Prompts you to create an admin user upon setup completion**  
✅ **Provides panel access link, Wings setup guidance, and optional Cloudflared tunnel**

> 💡 **Installer script by:** **Zerioak**  
> 🐉 **Pterodactyl Panel by:** **Pterodactyl Software**

---

## 📦 **Requirements**

| Component | Requirement |
|-----------|------------|
| 🖥️ **Operating System** | **Ubuntu / Debian VPS** (root access required) |
| 🔌 **Required Ports** | **8030** (Panel) & **443** (HTTPS - Optional) |
| 🌐 **Optional Public Access** | **Cloudflared** tunnel recommended |

---

## 🚀 **Installation**

### **1️⃣ Run the Pterodactyl Installer**

```
curl -sSL https://raw.githubusercontent.com/Zerioak/pterodactyl-install/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```
## ⚠️ **If User doesn't Create and Not Have administrator Access so run**
```
docker-compose run --rm panel php artisan p:user:make
```

---

## 🌐 **Optional: Install Cloudflared**

```bash
curl -LO https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
cloudflared --version
```

- Authenticate (SKIPPED):

```bash
cloudflared tunnel login
```

- Run a quick tunnel:

```bash
cloudflared tunnel --url http://localhost:8030
```

- Public URL example: `https://random-subdomain.trycloudflare.com`

- Run as background service (SKIPPED):

```bash
cloudflared tunnel create ptero-panel
cloudflared tunnel route dns ptero-panel panel.example.com
sudo cloudflared service install
```

---

## 🛠️ **Install Wings Daemon**

Run the Wings installer to set up the daemon, Docker, and dependencies.
```
bash <(curl -s https://pterodactyl-installer.se)
```
**After You Run This You will be see**

### **Installer Menu Example**

```text
* [0] Install the panel
* [1] Install Wings
* [2] Install both [0] and [1] on the same machine (wings script runs after panel)
* [3] Install panel with canary version of the script (may be unstable)
* [4] Install Wings with canary version of the script (may be unstable)
* [5] Install both [3] and [4] on the same machine (wings script runs after panel)
* [6] Uninstall panel or wings with canary version (may be unstable)
* Input 0-6: 1
* Retrieving release information...
* Pterodactyl panel installation script @ v1.2.0
* Latest pterodactyl/wings is v1.11.13
* Proceed with installation? (y/N): y
```

---

## 🔐 **Certificates for Wings**

```bash
mkdir -p /etc/certs
cd /etc/certs
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" -keyout privkey.pem -out fullchain.pem
```

---

## ⚙️ **Wings Configuration Example**

Edit `/etc/pterodactyl/config.yml`:

```yaml
debug: false
app_name: Pterodactyl
uuid: SEE_YOUR_OWN
token_id: SEE_YOUR_OWN
token: SEE_YOUR_OWN

api:
  host: 0.0.0.0
  port: 443
  ssl:
    enabled: true
    cert: /etc/certs/fullchain.pem
    key: /etc/certs/privkey.pem
  disable_remote_download: false
  upload_limit: 100
  trusted_proxies: []
```

---

## 🖥️ **Start Wings**

```bash
systemctl start wings
```

- If Wings overlaps with Docker networks:

```bash
docker network create --driver bridge --subnet 172.30.0.0/16 pterodactyl_nw
systemctl start wings
```

---

## ⚡ **Manage Wings with systemctl**

```bash
sudo systemctl start wings
sudo systemctl stop wings
sudo systemctl restart wings
sudo systemctl enable wings
sudo systemctl status wings
journalctl -u wings -f
```

---

## 🎖️ **Credits**

| Component | Author |
|-----------|--------|
| 🐉 **Pterodactyl Panel** | **Pterodactyl Software** |
| ⚙️ **Installer Script** | **Zerioak** |

---

## ⚖️ **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

✨ _Professional README generated for ExtremeNodes VPS_ ✨

</div>
