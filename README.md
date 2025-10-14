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

### **1️⃣ Run the installer script**

```bash
curl -sSL https://raw.githubusercontent.com/Zerioak/pterodactyl-install/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

---

## 🌐 **Optional: Install Cloudflared**

### **1️⃣ Download & Install**

```bash
curl -LO https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
cloudflared --version
```

### **2️⃣ Authenticate Cloudflare (Not Important if have or not have domain)**

```bash
cloudflared tunnel login
```

### **3️⃣ Run a Quick Tunnel**

```bash
cloudflared tunnel --url http://localhost:8030
```

- You’ll get a public URL like:  
  `https://random-subdomain.trycloudflare.com`

### **4️⃣ Run as a Background Service (SKIPPED THIS)**

```bash
cloudflared tunnel create ptero-panel
cloudflared tunnel route dns ptero-panel panel.example.com
sudo cloudflared service install
```

> Now your panel is publicly accessible via Cloudflare.

---

## 🌍 **Access the Panel**

| Access Method | Command / URL |
|--------------|--------------|
| 🖥️ **Local Access** | **http://localhost:8030** |
| 🌐 **Public via Cloudflared** | **Use the Cloudflared URL** |

---

## 🛠️ **Install Wings Daemon**

Run the official Wings installer to set up the Pterodactyl daemon, Docker, and dependencies.

### **Installer Menu Example**

```text
* [0] Install the panel
* [1] Install Wings
* [2] Install both [0] and [1] on the same machine (wings script runs after panel)
* [3] Install panel with canary version of the script (the versions that lives in master, may be broken!)
* [4] Install Wings with canary version of the script (the versions that lives in master, may be broken!)
* [5] Install both [3] and [4] on the same machine (wings script runs after panel)
* [6] Uninstall panel or wings with canary version of the script (the versions that lives in master, may be broken!)
* Input 0-6: 1
* Retrieving release information...
######################################################################
* Pterodactyl panel installation script @ v1.2.0
* Copyright (C) 2018 - 2025, Vilhelm Prytz, <vilhelm@prytznet.se>
* https://github.com/pterodactyl-installer/pterodactyl-installer
*
* This script is not associated with the official Pterodactyl Project.
* Running ubuntu version 22.04.
* Latest pterodactyl/wings is v1.11.13
##########################################
* Do you want to automatically configure UFW (firewall)? (y/N): n
* Do you want to automatically configure a user for database hosts? (y/N): n
* WARNING: You cannot use Let's Encrypt with your hostname as an IP address! It must be a FQDN (e.g. node.example.org).
* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): n
* Proceed with installation? (y/N): y
```

---

## 🎖️ **Credits**

| Component | Author |
|-----------|--------|
| 🐉 **Pterodactyl Panel** | **Pterodactyl Software** |
| ⚙️ **Installer Script** | **Zerioak** |

---

<div align="center">

✨ _Professional Code with style_ ✨

</div>
