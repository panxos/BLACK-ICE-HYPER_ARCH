# Power Management Guide (BLACK-ICE ARCH)

BLACK-ICE ARCH includes intelligent power management that automatically adapts to your hardware type.

## 🔋 Automatic Hardware Detection

The installer detects your system type and configures optimal power settings:

| Hardware Type | Power Tool | Default Profile | Adaptive |
|:---|:---:|:---:|:---:|
| **Laptop** | TLP | AC/Battery | ✅ Yes |
| **Desktop** | cpupower | Performance | ❌ Fixed |
| **Virtual Machine** | cpupower | Performance | ❌ Fixed |

---

## 💻 Laptop Power Management (TLP)

### Automatic Profiles

**AC Connected (Charger):**
- CPU Governor: `performance`
- Turbo Boost: **Enabled**
- WiFi Power Save: **Disabled**
- Maximum performance for intensive tasks

**On Battery:**
- CPU Governor: `powersave`
- Turbo Boost: **Disabled**
- CPU Max Performance: **50%**
- WiFi Power Save: **Enabled**
- Optimized for battery life

### Configuration File

TLP settings are stored in `/etc/tlp.d/01-black-ice.conf`. You can edit this file to customize behavior.

**Example customizations:**
```bash
# Allow more CPU performance on battery
CPU_MAX_PERF_ON_BAT=75  # Default: 50

# Keep Turbo Boost on battery
CPU_BOOST_ON_BAT=1  # Default: 0
```

After editing, restart TLP:
```bash
sudo systemctl restart tlp.service
```

---

## 🖥️ Desktop Power Management (cpupower)

Desktops use a fixed `performance` governor for maximum responsiveness.

**Configuration:** `/etc/default/cpupower`

**Change governor manually:**
```bash
# Performance (default)
sudo cpupower frequency-set -g performance

# Balanced
sudo cpupower frequency-set -g schedutil

# Power Save
sudo cpupower frequency-set -g powersave
```

---

## ⚡ Interactive Power Switcher

BLACK-ICE includes a user-friendly power profile switcher accessible via:

**Keyboard Shortcut:** `Super + P` (default)

**CLI Usage:**
```bash
# Show interactive menu
~/.config/hypr/scripts/power_manager.sh

# Direct profile change
~/.config/hypr/scripts/power_manager.sh performance
~/.config/hypr/scripts/power_manager.sh balanced
~/.config/hypr/scripts/power_manager.sh powersave

# Show current status
~/.config/hypr/scripts/power_manager.sh status
```

### Profiles Explained

**🚀 Performance:**
- Maximum CPU frequency
- Turbo Boost enabled
- Best for gaming, rendering, compilation

**⚡ Balanced (Recommended):**
- Automatic scaling based on load
- Good balance of performance and efficiency
- Ideal for daily use

**🔋 Power Saver:**
- Minimum CPU frequency
- Turbo Boost disabled
- Maximum battery life (laptops only)

---

## 🔧 Advanced Optimizations

### Zram (Memory Compression)

All systems include zram for improved memory efficiency:
- **Size:** 50% of RAM
- **Algorithm:** zstd (fast compression)
- **Priority:** 100 (higher than swap)

**Check zram status:**
```bash
zramctl
```

### Battery Notifications (Laptops)

The system will notify you when battery reaches:
- **20%** - Low battery warning
- **10%** - Critical battery alert

### Troubleshooting

**TLP not working:**
```bash
# Check TLP status
sudo tlp-stat -s

# Restart TLP
sudo systemctl restart tlp.service
```

**cpupower not changing frequency:**
```bash
# Check available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

# Verify current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

**High power consumption on laptop:**
1. Ensure you're on battery (not AC)
2. Check `tlp-stat -b` for battery status
3. Verify power-hungry processes with `powertop`

---

## 📊 Monitoring Tools

**Check CPU frequency:**
```bash
watch -n 1 "grep MHz /proc/cpuinfo"
```

**Monitor power consumption (laptops):**
```bash
sudo powertop
```

**Battery statistics:**
```bash
tlp-stat -b
```

---

## 🎯 Recommendations

**For Laptops:**
- Keep TLP enabled for automatic management
- Use `Balanced` mode for daily tasks
- Switch to `Performance` only when needed
- Monitor battery health with `tlp-stat -b`

**For Desktops:**
- Keep `performance` governor for gaming/workstation use
- Use `schedutil` for general-purpose machines
- Consider `powersave` for always-on servers

**For VMs:**
- Performance governor is optimal
- No power management needed (handled by host)
