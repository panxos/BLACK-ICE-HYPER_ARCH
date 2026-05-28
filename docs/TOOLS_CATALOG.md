# BLACK-ICE ARCH - Security Tools Catalog

## 📋 Table of Contents

- [Reconnaissance](#reconnaissance)
- [Web Application Security](#web-application-security)
- [Networking & Sniffing](#networking--sniffing)
- [Wireless Security](#wireless-security)
- [Exploitation & C2 Frameworks](#exploitation--c2-frameworks)
- [Active Directory & Windows](#active-directory--windows)
- [Forensics & Analysis](#forensics--analysis)
- [Cracking & Secrets](#cracking--secrets)
- [Reverse Engineering](#reverse-engineering)

---

## 🔍 Reconnaissance

- **nmap** - Network mapper and security scanner.
- **masscan** - Fast TCP port scanner (scans entire internet in minutes).
- **rustscan** - Modern port scanner written in Rust, extremely fast.
- **netdiscover** - Active/passive ARP reconnaissance tool.
- **theHarvester** - E-mail, subdomain, and name harvester (OSINT).
- **sherlock** - Hunt down social media accounts by username.

---

## 🌐 Web Application Security

- **Burp Suite Community** - The classic web proxy and vulnerability scanner.
- **OWASP ZAP** - Open-source web application security scanner.
- **sqlmap** - Automatic SQL injection and database takeover tool.
- **nuclei** - Rapid vulnerability scanner based on customizable templates.
- **ffuf** - Fast web fuzzer for directory and parameter discovery.
- **gobuster** - URI and DNS subdomain busting tool.

---

## 📡 Networking & Sniffing

### Cisco & Interactive

- **minicom** - Serial terminal for Cisco consoles and serial hardware.
- **expect** - Automation of interactive sessions (Telnet/SSH/FTP).
- **cisco-torch** - Advanced Cisco scanner and fingerprinting tool.
- **snmpcheck** - Tool for enumerating SNMP information from agents.
- **onesixtyone** - High-speed SNMP community string scanner.

### Analysis & Traffic

- **wireshark-qt** - GUI-based network protocol analyzer.
- **tcpdump** - Powerful CLI packet sniffer and analyzer.
- **macchanger** - Utility for viewing/manipulating MAC addresses.
- **bettercap** - The Swiss Army knife for 802.11, BLE and Ethernet networks.
- **ettercap** - MITM framework for ARP poisoning and sniffing.

---

## 💥 Exploitation & C2 Frameworks

- **metasploit** - Industry-standard exploit framework.
- **sliver** - Modern, cross-platform C2 framework (Go) replacing MSF in many ops.
- **villain** - Advanced reverse shell manager and multi-session handler.
- **searchsploit** - Command-line interface for Exploit-DB (offline search).
- **routersploit** - Framework for exploiting embedded devices/routers.
- **beef** - Browser Exploitation Framework (XSS focused).
- **set** - Social Engineering Toolkit for phishing.

---

## 🏗️ Active Directory & Windows

- **netexec (nxc)** - The successor to CrackMapExec; the "Swiss Army Knife" for AD pentesting.
- **certipy** - Specialized tool for auditing and exploiting AD Certificate Services (AD CS).
- **impacket** - Collection of Python classes for working with network protocols (SMB, MSRPC).
- **bloodhound.py** - Python ingestor for BloodHound (collects AD data from Linux).
- **evil-winrm** - Ultimate shell for WinRM (Windows Remote Management).
- **coercer** - Automatic coercion of Windows authentication (MS-RPC).
- **kerbrute** - Fast Kerberos pre-authenticator for user enumeration and bruteforce.
- **responder** - Poisoner for LLMNR, NBT-NS and MDNS.

> ⚠️ **BloodHound (bloodhound)**: Requiere `neo4j-community` como dependencia AUR. Este paquete es un proyecto Maven/Scala de **165 módulos** que se compila desde fuente. La instalación puede tardar entre **20 y 60 minutos** dependiendo del hardware. El script avisa antes de comenzar — **no canceles el proceso**, es completamente normal.

---

## 🔐 Cracking & Secrets

- **hashcat** - World's fastest password recovery tool (GPU accelerated).
- **john** - John the Ripper, versatile password cracker.
- **trufflehog** - Scans repositories, S3 buckets, and filesystems for secrets/keys.
- **gitleaks** - Highly effective tool for detecting secrets in Git history.
- **pcredz** - Extracts credit card numbers and credentials from PCAP/Live traffic.
- **hydra** - Parallel network login brute-forcing tool.
- **cewl** - Custom wordlist generator based on target website content.
- **seclists** - Massive collection of lists for payloads, passwords, and discovery.

---

## 🔬 Forensics & Analysis

- **autopsy** - Digital forensics platform and GUI.
- **volatility3** - Advanced memory forensics framework.
- **binwalk** - Firmware analysis and file extraction tool.
- **exiftool** - Read and write meta information in files.

---

## 🛠️ Reverse Engineering

- **ghidra** - NSA's software reverse engineering suite.
- **radare2** - Complete framework for reverse engineering and analysis.
- **gdb** - The GNU Debugger for Linux binary analysis.
- **apktool** - Tool for reverse engineering Android APK files.

---

---

## 🖥️ Scripts BLACK-ICE (`~/.config/bin/`)

Utilidades del entorno instaladas automáticamente por `src/deploy/99_finalization.sh`:

| Script | Keybind | Descripción |
|--------|---------|-------------|
| `cheatsheet` | `Win+I` | Overlay GTK3 fullscreen con todos los keybinds |
| `app_switcher` | `Win+Tab` | Selector de ventanas abiertas via wofi + hyprctl |
| `pass_menu` | `Win+Shift+X` | KeePassXC CLI + Wofi. Copia pass/user/TOTP |
| `terminal_manager` | `Win+Ctrl+Enter` | Sesiones Kitty multi-tab (Pentesting/Dev/SOC) |
| `theme_selector` | `Win+Alt+T` | Cambia tema Waybar + wallpaper + colores Kitty (pywal) |
| `theme_visual` | — | Preview visual de temas con capturas de pantalla |
| `wallpaper_switcher` | `Win+Alt+W` | Selector de wallpaper con preview |
| `wallpaper_visual` | — | Browser visual de wallpapers |
| `wofi_style_selector` | `Win+Alt+R` | Cambia estilo Wofi (4 opciones) |
| `wifi_toggle` | `Win+Alt+F` | Toggle WiFi via nmcli + notificación |
| `music_player` | `Win+Shift+M` | Lanzador ncmpcpp con MPD auto-start |
| `power_profile_menu.sh` | `Win+Shift+P` | Selector perfil de energía (TLP) |
| `power_menu.sh` | Waybar btn | Lock/Sleep/Reboot/Shutdown/Logout |
| `vpn_status` | Waybar | Status VPN activa con iconos BMP Nerd Font (U+F023/F09C) |
| `megasync-watcher.sh` | systemd --user | Fix XWayland MEGAsync: convierte POPUP_MENU→NORMAL, centra ventana |
| `target_status` | Waybar | Target IP para HTB/CTF |
| `updates_status` | Waybar | Paquetes disponibles para actualizar |
| `kvm_menu` | — | Gestión de VMs KVM via wofi |
| `docker_menu` | — | Gestión de contenedores Docker via wofi |
| `htb-connect.sh` | — | Conectar VPN HackTheBox |
| `tryhackme-connect.sh` | — | Conectar VPN TryHackMe |
| `settarget` | — | Fijar target IP para HTB/CTF |
| `tech_quotes.sh` | Waybar | Cita técnica aleatoria en la barra |

---

**Ubicación seguridad**: Todas las herramientas se gestionan desde `src/deploy/02_security_tools.sh`  
**Actualización**: Ejecuta `paru -Syu` para mantener todo el arsenal al día.
