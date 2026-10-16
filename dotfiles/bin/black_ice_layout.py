"""Composición compartida del catálogo y los temas personales."""

BACKEND = "~/.local/bin/black-ice-waybar"


def status(name: str, interval: int, length: int = 24) -> dict:
    item = {"exec":BACKEND + " " + name, "return-type":"json", "interval":interval,
            "format":"{}", "escape":True, "tooltip":True, "max-length":length}
    if name in {"local", "public", "vpn", "target"}:
        item["on-click-right"] = BACKEND + " copy " + name
    if name in {"docker", "kvm"}:
        item["exec-if"] = "command -v " + ("docker" if name == "docker" else "virsh") + " >/dev/null 2>&1"
        item["hide-empty-text"] = True
    return item


def configuration(layout: str = "dual-top") -> list:
    desktop = {
        "name":"desktop", "layer":"top", "position":"top", "height":36, "spacing":0,
        "modules-left":["custom/launcher", "hyprland/workspaces"],
        "modules-center":["custom/player", "custom/weather"],
        "modules-right":["network", "bluetooth", "pulseaudio", "battery", "clock", "custom/control", "custom/power", "tray"],
        "custom/launcher":{"format":"󰣇", "tooltip":False, "on-click":"wofi --show drun --allow-images"},
        "hyprland/workspaces":{"format":"{name}", "on-click":"activate", "persistent-workspaces":{"*":5}},
        "network":{"format-wifi":"󰤨", "format-ethernet":"󰈀", "format-disconnected":"󰤭", "tooltip-format":"{ifname} · {essid}", "on-click":"~/.local/bin/black-ice-control network"},
        "bluetooth":{"format":"󰂯", "format-disabled":"󰂲", "format-connected":"󰂱", "tooltip-format":"{status}", "on-click":"~/.local/bin/black-ice-control bluetooth"},
        "pulseaudio":{"format":"󰕾 {volume}%", "format-muted":"󰝟", "on-click":"~/.local/bin/black-ice-control", "on-click-right":"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"},
        "battery":{"format":"{capacity}%", "format-charging":"󰂄 {capacity}%", "states":{"warning":25,"critical":10}},
        "clock":{"format":"{:%H:%M}", "tooltip-format":"{:L%A, %d de %B}"},
        "custom/control":{"format":"\uf013", "tooltip-format":"Ajustes · clic derecho: notificaciones", "on-click":"~/.local/bin/black-ice-control", "on-click-right":"swaync-client -t -sw"},
        "custom/power":{"format":"󰐥", "tooltip":False, "on-click":"~/.local/bin/black-ice-control session"},
        "tray":{"icon-size":14,"spacing":8},
        "custom/player":status("player",5,24),
        "custom/weather":status("weather",1800,18),
        "group/connectivity":{"orientation":"inherit", "drawer":{"transition-duration":150}, "modules":["network","bluetooth"]},
        "group/media":{"orientation":"inherit", "drawer":{"transition-duration":150}, "modules":["clock","custom/player","custom/weather"]}
    }
    desktop["custom/player"]["on-click"] = "playerctl play-pause"
    operations = {
        "name":"operations", "layer":"top", "position":"bottom", "height":30, "spacing":0,
        "modules-left":["custom/docker","custom/kvm","custom/updates"],
        "modules-center":["custom/local_ip","custom/public_ip","custom/vpn", "custom/privacy"],
        "modules-right":["custom/settarget"],
        "custom/docker":status("docker",15,12), "custom/kvm":status("kvm",15,12),
        "custom/updates":status("updates",1800,12), "custom/local_ip":status("local",10),
        "custom/public_ip":status("public",60), "custom/vpn":status("vpn",5),
        "custom/settarget":status("target",3,28),
        "custom/privacy":{"exec":"~/.local/bin/black-ice-privacy status --waybar", "return-type":"json", "interval":3,
                          "format":"{}", "escape":True, "on-click":"~/.local/bin/black-ice-privacy toggle",
                          "on-click-right":"~/.local/bin/black-ice-privacy menu", "tooltip":True},
        "group/lab":{"orientation":"inherit", "modules":["custom/docker","custom/kvm","custom/updates"]},
        "group/addresses":{"orientation":"inherit", "drawer":{"transition-duration":150}, "modules":["custom/local_ip","custom/public_ip"]},
        "group/operations":{"orientation":"inherit", "drawer":{"transition-duration":150}, "modules":["custom/local_ip","custom/public_ip","custom/settarget","group/lab"]},
        "group/system":{"orientation":"inherit", "drawer":{"transition-duration":150}, "modules":["custom/control","network","bluetooth","pulseaudio","battery","custom/power"]}
    }
    operations["custom/docker"]["on-click"] = "~/.config/bin/docker_menu"
    operations["custom/kvm"]["on-click"] = "~/.config/bin/kvm_menu"
    operations["custom/settarget"]["on-click"] = BACKEND + " choose-target"
    controls = desktop["modules-right"]
    player = ["custom/player", "custom/weather"]
    addresses = operations["modules-center"]
    definitions = {key:value for bar in (desktop, operations) for key,value in bar.items() if "/" in key or key in {"network","bluetooth","pulseaudio","battery","clock","tray"}}
    for bar in (desktop, operations):
        bar.update(definitions)
        bar["fixed-center"] = True
    desktop["modules-left"] = ["custom/launcher", *player]
    desktop["modules-center"] = ["hyprland/workspaces"]
    if layout == "dual-bottom":
        desktop.update({"modules-center":addresses, "modules-right":["custom/settarget"]})
        operations.update({"modules-center":["hyprland/workspaces"], "modules-right":controls})
    elif layout in {"single-top", "single-bottom"}:
        desktop.update({"position":"top" if layout == "single-top" else "bottom",
                        "modules-left":["custom/launcher", "group/lab", "group/addresses", "custom/vpn", "custom/privacy", "custom/settarget"],
                        "modules-right":["group/connectivity", "pulseaudio", "battery", "group/media", "custom/control", "custom/power", "tray"]})
        return [desktop]
    elif layout != "dual-top":
        raise ValueError("Distribución desconocida: " + layout)
    return [desktop, operations]


