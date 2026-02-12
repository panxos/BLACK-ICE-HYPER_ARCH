# Virtualization Optimization Guide (BLACK-ICE ARCH)

This guide provides technical steps to ensure maximum performance and visual fluidity when running BLACK-ICE ARCH (Hyprland environment) in virtualized environments.

## 🚀 KVM / QEMU (Recommended)

Hyprland requires 3D acceleration to avoid high CPU usage from software rendering.

### 🛠️ Hardware Acceleration (VirtIO-GPU)

Modify your VM XML configuration (via `virsh edit VM_NAME` or Virt-Manager) to include the following:

**1. Graphics (Spice):**
Enable OpenGL and specify your host's render node.

```xml
<graphics type='spice' autoport='yes'>
  <listen type='none'/>
  <gl enable='yes' rendernode='/dev/dri/renderD128'/>
</graphics>
```

**2. Video Device:**
Change model to `virtio` with `accel3d` enabled.

```xml
<video>
  <model type='virtio' heads='1' primary='yes'>
    <acceleration accel3d='yes'/>
  </model>
</video>
```

### ⚡ Performance Enlightenments (Hyper-V for Linux)

Adding these features improves time-sync and reduces interrupt overhead:

```xml
<features>
  <hyperv mode='custom'>
    <relaxed state='on'/>
    <vapic state='on'/>
    <spinlocks state='on' retries='8191'/>
  </hyperv>
</features>
<clock offset='utc'>
  <timer name='hypervclock' present='yes'/>
</clock>
```

---

## 🟦 VMware (Workstation / ESXi)

For VMware, the installer automatically includes `open-vm-tools`.

**Manual Settings:**

1. In VM Settings -> Display -> Enable **Accelerate 3D graphics**.
2. Set Graphics memory to at least **256MB** (512MB recommended for 4K).
3. If the cursor is invisible, ensure `WLR_NO_HARDWARE_CURSORS=1` is set in your environment (the installer does this automatically if it detects VMware).

---

## 🟧 Microsoft Hyper-V

Hyper-V guest support is improved by adding specific kernel parameters.

**1. Kernel Parameters:**
Ensure `video=hyperv_fb:1920x1080` (or your resolution) is added to your GRUB_CMDLINE_LINUX_DEFAULT.

**2. Guest Services (hv_utils):**
The installer will attempt to install the `hyperv` package. Ensure the services are enabled:

```bash
sudo systemctl enable --now hv_fcopy_daemon.service hv_kvp_daemon.service hv_vss_daemon.service
```

---

## 🛠️ Global Troubleshooting

**Invisible Cursor:**
If you see the desktop but no cursor, add this to your `~/.zprofile` or `/etc/environment`:

```bash
export WLR_NO_HARDWARE_CURSORS=1
```

**Software Rendering Check:**
Run `glxinfo | grep renderer` inside the VM.

- **Good**: `Mesa VirtIO-GPU V3D` (or similar)
- **Bad**: `llvmpipe (LLVM ...)` (This means CPU rendering)
