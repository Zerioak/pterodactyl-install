<div align="center">

# 🎮 **Pterodactyl Panel VPS Installer**

![Docker](https://img.shields.io/badge/Docker-Automated-blue)
![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Panel-green)
![Auto Install](https://img.shields.io/badge/Installer-Fully%20Automated-orange)
![Made with ❤️](https://img.shields.io/badge/Made%20with-❤️-ff69b4)

</div>

> A **fully automated VPS installer** for the **Pterodactyl Game Panel** — designed for **speed**, **simplicity**, and **zero manual configuration**.

---

## ✨ **Features**

✅ **Installs Docker & Docker Compose automatically**  
✅ **Sets up all directories and volumes automatically**  
✅ **Generates docker-compose.yml for Panel, MariaDB & Redis**  
✅ **Starts all required Docker containers instantly**  
✅ **Runs database migrations and seeds default eggs automatically**  
✅ **Prompts you to create an admin user upon setup completion**  
✅ **Provides panel access link and Wings installation guidance**

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

### **1️⃣ Run the installer script**

```bash
curl -sSL https://raw.githubusercontent.com/Zerioak/pterodactyl-install/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

---

## 🌍 **Access the Panel**

| Access Method | Command / URL |
|--------------|--------------|
| 🖥️ **Local Access** | **http://localhost:8030** |
| 🌐 **Public via Cloudflared** |  
```bash
cloudflared tunnel --url http://localhost:8030
``` |

---

## 🛠️ **Optional: Install Wings Daemon**

```bash
bash <(curl -s https://pterodactyl-installer.se)
```

---

## 🎖️ **Credits**

| Component | Author |
|-----------|--------|
| 🐉 **Pterodactyl Panel** | **Pterodactyl Software** |
| ⚙️ **Installer Script** | **Zerioak** |

---

<div align="center">

✨ _Professional README generated with style_ ✨

</di
