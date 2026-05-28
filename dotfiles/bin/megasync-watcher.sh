#!/bin/bash
# megasync-watcher.sh — Fix MEGAsync XWayland popup/dialog windows en Hyprland
# Convierte _NET_WM_WINDOW_TYPE_POPUP_MENU -> NORMAL para que no se cierre solo
# Requiere: socat, xdotool, xprop, hyprctl

fix_mega_windows() {
    DISPLAY=:1 xdotool search --class MEGAsync 2>/dev/null | while read -r wid; do
        wtype=$(DISPLAY=:1 xprop -id "$wid" _NET_WM_WINDOW_TYPE 2>/dev/null)
        case "$wtype" in
            *POPUP_MENU*|*DIALOG*)
                DISPLAY=:1 xprop -id "$wid" -format _NET_WM_WINDOW_TYPE 32a \
                    -set _NET_WM_WINDOW_TYPE "_NET_WM_WINDOW_TYPE_NORMAL" 2>/dev/null
                DISPLAY=:1 xdotool windowstate --remove ABOVE "$wid" 2>/dev/null
                ;;
        esac
    done
    sleep 0.3
    hyprctl dispatch focuswindow class:MEGAsync 2>/dev/null
    sleep 0.1
    hyprctl dispatch centerwindow 2>/dev/null
}

while true; do
    SIG="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls "${XDG_RUNTIME_DIR}/hypr/" 2>/dev/null | head -1)}"
    SOCK="${XDG_RUNTIME_DIR}/hypr/${SIG}/.socket2.sock"
    [ -S "$SOCK" ] && socat -U - "UNIX-CONNECT:$SOCK" 2>/dev/null | while IFS= read -r event; do
        case "$event" in
            openwindow*MEGAsync*) fix_mega_windows & ;;
        esac
    done
    sleep 3
done
