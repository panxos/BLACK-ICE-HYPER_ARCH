# Catálogo de aplicaciones

140 aplicaciones opcionales en 20 grupos. La fuente canónica es `config/apps.json`; la disponibilidad y las dependencias se comprueban al instalar. Esta lista no significa que todas estén instaladas ni autoriza uso contra terceros.

Abre **Control → Sistema → Centro de software** para instalar y reintentar. El selector de planes permite marcar aplicaciones, grupos o perfiles `minimal`, `desktop`, `pentest` y `full`. Cancelar omite software opcional. AUR requiere revisión separada.

[Instalación](INSTALLER_V4.md) · [Gestor de software](SYSTEM_MANAGER.md).

## Navegadores

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Firefox | `firefox` | — |
| Brave | `brave-bin` | — |

## Desarrollo y laboratorios

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Podman (contenedores sin root) | `podman` | — |
| Docker Engine | `docker` | — |
| Docker Compose | `docker-compose` | — |
| QEMU/KVM completo | `qemu-full` | Sí |
| libvirt | `libvirt` | — |
| Gestor de máquinas virtuales | `virt-manager` | — |
| dnsmasq | `dnsmasq` | — |
| kate | `kate` | — |
| Neovim + NvChad | `neovim` | — |

## Seguridad de escritorio

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Caido Desktop | `caido-desktop` | — |
| ipscan | `ipscan` | — |

## Asistentes opcionales

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Claude Desktop · cliente de la comunidad | `claude-desktop` | — |
| Claude Code CLI | `claude-code-cli` | — |

## Productividad

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| obsidian | `obsidian` | — |
| betterbird-bin | `betterbird-bin` | — |
| KeePassXC | `keepassxc` | — |

## Multimedia

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| vlc | `vlc` | — |
| imv | `imv` | — |
| mpv | `mpv` | — |
| yt-dlp | `yt-dlp` | — |
| gimp | `gimp` | — |
| spectacle | `spectacle` | — |
| mpd | `mpd` | — |
| ncmpcpp | `ncmpcpp` | — |
| mpc | `mpc` | — |
| playerctl | `playerctl` | — |
| mpd-mpris | `mpd-mpris` | — |

## Acceso remoto

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| anydesk-bin | `anydesk-bin` | — |
| rustdesk-bin | `rustdesk-bin` | — |
| remmina | `remmina` | — |
| freerdp | `freerdp` | — |

## Archivos y nube

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| filezilla | `filezilla` | — |
| MEGAsync | `megasync-bin` | — |

## Oficina

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| OnlyOffice | `onlyoffice-bin` | — |
| okular | `okular` | — |

## Utilidades

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| gparted | `gparted` | — |
| bleachbit | `bleachbit` | — |
| 7zip | `7zip` | — |
| ktorrent | `ktorrent` | — |
| speedtest-cli | `speedtest-cli` | — |

## Seguridad · Recon

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Nmap - Network Scanner | `nmap` | — |
| Masscan - Fast Port Scanner | `masscan` | — |
| RustScan - Modern Port Scanner | `rustscan` | — |
| Netdiscover - ARP Scanner | `netdiscover` | — |
| ARP-Scan - Network Discovery | `arp-scan` | — |
| Recon-ng - Recon Framework | `recon-ng` | — |
| TheHarvester - OSINT Tool | `theharvester-git` | — |
| SpiderFoot - OSINT Automation | `spiderfoot` | — |
| Amass - Subdomain Enumeration | `amass` | — |
| Sherlock - Username Hunter | `sherlock` | — |
| DNSenum - DNS Enumeration | `dnsenum2` | — |
| DNSrecon - DNS Recon | `python-dnsrecon` | — |
| Enum4Linux - SMB Enumeration | `enum4linux` | — |

## Seguridad · Web

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Burp Suite - Web Proxy | `burpsuite` | — |
| OWASP ZAP - Web Scanner | `zaproxy` | — |
| SQLMap - SQL Injection | `sqlmap` | — |
| Nikto - Web Server Scanner | `nikto` | — |
| WPScan - WordPress Scanner | `wpscan` | — |
| WhatWeb - Web Fingerprinting | `whatweb` | — |
| Gobuster - Directory Fuzzer | `gobuster` | — |
| FFUF - Fast Web Fuzzer | `ffuf` | — |
| Feroxbuster - Content Discovery | `feroxbuster` | — |
| Nuclei - Vulnerability Scanner | `nuclei` | — |
| HTTPx - HTTP Toolkit | `httpx` | — |
| Commix - Command Injection | `commix` | — |
| XSSer - XSS Scanner | `xsser` | — |

## Seguridad · Wireless

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Aircrack-ng - WiFi Security | `aircrack-ng` | — |
| Kismet - Wireless Detector | `kismet` | — |
| Wifite - Automated WiFi Attack | `wifite` | — |
| Reaver - WPS Attack | `reaver` | — |
| Bully - WPS Bruteforce | `bully` | — |
| PixieWPS - WPS Pixie Dust | `pixiewps` | — |

## Seguridad · AD

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Impacket - Python SMB/MSRPC | `impacket` | — |
| NetExec - Modern CME (nxc) | `netexec` | — |
| Evil-WinRM - WinRM Shell | `ruby-evil-winrm` | — |
| BloodHound - AD Mapper [~60min] | `bloodhound` | Sí |
| Certipy - AD CS Attack | `python-certipy-ad-git` | — |
| Coercer - Forced Auth | `coercer` | — |
| Kerbrute - Kerberos Bruteforce | `kerbrute-bin` | — |
| Responder - LLMNR Poisoner | `responder` | — |
| SMBMap - SMB Enumeration | `smbmap` | — |
| Chntpw - Windows Password Reset | `chntpw` | — |

## Seguridad · Crack

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| John the Ripper - Password Cracker | `john` | — |
| Hashcat - GPU Cracker | `hashcat` | — |
| Hydra - Network Bruteforcer | `hydra` | — |
| Medusa - Parallel Bruteforcer | `medusa` | — |
| TruffleHog - Secret Scanner | `trufflehog-bin` | — |
| Gitleaks - Git Secret Scanner | `gitleaks` | — |
| CeWL - Wordlist Generator | `cewl` | — |
| Crunch - Wordlist Creator | `crunch` | — |
| HashID - Hash Identifier | `hashid` | — |
| SecLists - Security Wordlists | `seclists` | — |
| Wordlists - RockYou & More | `wordlists` | — |

## Seguridad · Exploit

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Metasploit Framework | `metasploit` | — |
| Sliver - C2 Framework (Go) [~15min] | `sliver` | Sí |
| Villain - Reverse Shell Manager | `villain-c2-git` | — |
| ExploitDB - Exploit Archive | `exploitdb` | — |
| Social Engineer Toolkit | `social-engineer-toolkit` | — |
| RouterSploit - Router Exploit | `routersploit` | — |

## Seguridad · Sniff

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Wireshark - Network Analyzer | `wireshark-qt` | — |
| TCPDump - Packet Sniffer | `tcpdump` | — |
| Ettercap - MITM Framework | `ettercap` | — |
| Bettercap - Network Attack | `bettercap` | — |
| MITMProxy - HTTP(S) Proxy | `mitmproxy` | — |
| MACchanger - MAC Spoofer | `macchanger` | — |
| Scapy - Packet Manipulation | `scapy` | — |

## Seguridad · RE

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| GDB - GNU Debugger | `gdb` | — |
| Radare2 - Reverse Framework | `radare2` | — |
| Ghidra - NSA RE Tool [~20min] | `ghidra` | Sí |
| NASM - Assembler | `nasm` | — |
| APKTool - Android Decompiler | `android-apktool` | — |
| JADX - Android Decompiler | `jadx` | — |
| EDB - Qt Debugger | `edb-debugger` | — |

## Seguridad · Forense

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Autopsy - Digital Forensics [~20min] | `autopsy` | Sí |
| SleuthKit - Forensic Toolkit | `sleuthkit` | — |
| Volatility3 - Memory Forensics | `volatility3` | — |
| Binwalk - Firmware Analysis | `binwalk` | — |
| Foremost - File Recovery | `foremost` | — |
| ExifTool - Metadata Reader | `perl-image-exiftool` | — |
| Steghide - Steganography Tool | `steghide` | — |
| Stegseek - Steg Cracker | `stegseek` | — |
| HexEdit - Hex Editor | `hexedit` | — |

## Seguridad · Net

| Aplicación | ID del catálogo | Descarga pesada |
|---|---|---|
| Netcat - Network Swiss Army | `openbsd-netcat` | — |
| Socat - Data Relay | `socat` | — |
| Proxychains - Proxy Forcer | `proxychains-ng` | — |
| SSHuttle - VPN over SSH | `sshuttle` | — |
| Chisel - TCP/UDP Tunnel | `chisel` | — |
| Traceroute - Path Trace | `traceroute` | — |
| Wireshark CLI | `wireshark-cli` | — |
| Bind-tools - dig/nslookup | `bind` | — |
| Whois - Domain Lookup | `whois` | — |
| MTR - Ping+Traceroute | `mtr` | — |
| IPerf3 - Bandwidth Test | `iperf3` | — |
| Nethogs - Bandwidth/Process | `nethogs` | — |
| Iftop - Bandwidth/Host | `iftop` | — |
| IPTraf-ng - Net Monitor | `iptraf-ng` | — |
| Minicom - Serial Terminal | `minicom` | — |
| Onesixtyone - SNMP Scanner | `onesixtyone` | — |
