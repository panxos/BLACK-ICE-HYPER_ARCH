# Energía automática en BLACK-ICE

## Comportamiento

En portátiles con TLP 1.10+, Automático selecciona **Equilibrado con corriente** y **Ahorro con batería**. TLP recibe eventos de alimentación; no se agrega un sondeo constante. Los perfiles manuales siguen disponibles y `power_profile auto` restablece las reglas automáticas.

El menú `Super+Shift+P` usa `power_profile_menu.sh`. Prioriza TLP activo, después power-profiles-daemon activo y finalmente CPUpower. Un binario instalado con servicio inactivo no basta para elegir ese backend. El menú muestra errores reales y no usa `eval`.

Con corriente, hypridle conserva bloqueo a los ocho minutos y no ejecuta reducción de brillo, apagado de pantalla ni suspensión. Con batería confirmada, reduce brillo a los cuatro minutos, bloquea a los ocho, apaga pantalla a los diez y suspende a los treinta. Las VM y estados de alimentación desconocidos no suspenden por este guard.

Logind ignora cerrar la tapa con corriente; con batería conserva suspensión. Con una pantalla externa que logind considere acoplada se conserva su política de ignorar la tapa. Esto controla acciones automáticas y el menú; no impide una suspensión forzada por un administrador.

## Instalaciones existentes

La configuración adicional se guarda en `/etc/tlp.d/90-black-ice-auto.conf`. No reemplaza los ajustes personales de USB, discos o umbrales de carga. TLP procesa `/etc/tlp.conf` después de los drop-ins: revisa sus parámetros activos si contradicen este perfil.

Desde la raíz del repositorio, instala scripts y reglas explícitamente:

```bash
mkdir -p "$HOME/.cache/tmp/work"
power_work=$(mktemp -d "$HOME/.cache/tmp/work/power-XXXXXX")
bash dotfiles/bin/power_profile --print-config > "$power_work/tlp-auto.conf"
sudo install -Dm644 "$power_work/tlp-auto.conf" /etc/tlp.d/90-black-ice-auto.conf
sudo install -Dm644 config/power/90-black-ice-laptop.conf /etc/systemd/logind.conf.d/90-black-ice-laptop.conf
install -Dm755 dotfiles/bin/power_profile "$HOME/.local/bin/power_profile"
install -Dm755 dotfiles/bin/power_profile "$HOME/.config/bin/power_profile"
install -Dm755 dotfiles/bin/power_profile_menu.sh "$HOME/.config/bin/power_profile_menu.sh"
install -Dm755 dotfiles/bin/power_menu.sh "$HOME/.config/bin/power_menu.sh"
install -Dm755 dotfiles/hypr/scripts/ac_guard.sh "$HOME/.config/hypr/scripts/ac_guard.sh"
"$HOME/.local/bin/power_profile" auto
sudo systemctl reload systemd-logind
rm "$power_work/tlp-auto.conf"
rmdir "$power_work"
```

Revisa y conserva las versiones personales de esos scripts antes de sustituirlas si las personalizaste. No ejecutes estas reglas de portátil en un desktop con KDE como una migración genérica. `dotfiles-update` conserva configuraciones y no instala estos ajustes de sistema automáticamente.

## Verificación y reversión

```bash
sudo tlp-stat -s
sudo tlp-stat -c
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
"$HOME/.config/hypr/scripts/ac_guard.sh" status
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitchExternalPower
python3 -m unittest discover -s tests -p test_power_management.py
```

Con corriente puede aparecer `balanced/BAT` en TLP: BAT identifica los parámetros del perfil Equilibrado, aunque la fuente sea AC. En `intel_pstate`, `powersave` permite frecuencia adaptativa; no equivale al gobernador del mismo nombre en todos los controladores.

Para revertir estas reglas, retira únicamente los dos drop-ins nuevos, restaura tus scripts anteriores, ejecuta `sudo tlp start` y recarga logind. No borres otros archivos de configuración. En s3th se conservaron las versiones previas de los tres scripts sustituidos en `~/.local/state/black-ice/power-changes/20261009-180910/`.

Aplicación en s3th verificada con corriente: TLP Automático/Equilibrado, gobernador `powersave`, preferencia `balance_performance`, plataforma `balanced` y tapa con corriente en `ignore`. La desconexión física, suspensión real y comparación térmica sostenida no están verificadas; los casos de batería y error se comprueban con fixtures.

Fuentes: [TLP: operación](https://linrunner.de/tlp/settings/operation.html), [TLP: procesador](https://linrunner.de/tlp/settings/processor.html), [logind.conf](https://www.freedesktop.org/software/systemd/man/latest/logind.conf.html).
