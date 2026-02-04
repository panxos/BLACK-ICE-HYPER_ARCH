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

**Ubicación**: Todas las herramientas se gestionan desde `src/deploy/02_security_tools.sh`  
**Actualización**: Ejecuta `yay -Syu` para mantener todo el arsenal al día.
