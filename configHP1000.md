

## Permitir que Xsession se ejecute como root
`sudo vim /etc/pam.d/other`
``` bash
session         optional        pam_xauth.so
```
[links](https://wiki.archlinux.org/title/Privilege_elevation_for_graphical_applications#Alternate_methods)
# CONFIGURACIÓN ARCH LINUX + HYPRLAND (HP1000)

Notas personales de configuración completa para Arch Linux con Hyprland en HP Probook 1000. Incluye instalación de paquetes, configuración de temas, servicios, Hyprland y solución de problemas.

---

## 1. Desactivar pantalla LVDS-1 en GRUB

Ubicación: `/etc/default/grub`

La pantalla integrada (LVDS-1) se mantiene encendida. Desactivarla ahorra energía y evita problemas de parpadeo.

- `loglevel=3`: Reduce el ruido durante el arranque (útil con dual boot).
- `video=LVDS-1:d`: Desactiva la pantalla LVDS-1 desde el arranque del kernel.

```grub
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 video=LVDS-1:d"
GRUB_DISABLE_OS_PROBER=false
```

Después de editar, actualizar GRUB:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 2. Configuración unificada de temas (GTK + Qt)

Referencias:

- [Aspecto uniforme Qt y GTK](https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications)
- [Tema GTK](https://wiki.archlinux.org/title/GTK#Theme_not_applied_to_root_applications)
- [Tema Qt](https://wiki.archlinux.org/title/Qt#Theme_not_applied_to_root_applications)
- [Variables de entorno](https://wiki.archlinux.org/title/Environment_variables#Defining_variables)

### Paquetes necesarios

```bash
sudo pacman -S qt5ct qt6ct gtk3 gtk4 breeze breeze-gtk nwg-look nwg-drawer
```

### Configurar Qt

1. **Crear el directorio para esquemas de color de Qt** (si no existe):

```bash
mkdir -p ~/.local/share/color-schemes
```

2. **Crear enlace simbólico** del esquema generado por pywal:

```bash
ln -sf ~/.cache/wal/BreezeDarkPywal.colors ~/.local/share/color-schemes/BreezeDarkPywal.colors
```

3. **Aplicar tema con nwg-look** o editar directamente `~/.config/qt5ct/qt5ct.conf`:

```ini
[Appearance]
color_scheme_path=~/.local/share/color-schemes/BreezeDarkPywal.colors
```

### Configurar GTK

Usar `nwg-look` para una interfaz gráfica o editar:

- **GTK 2**: `~/.gtkrc-2.0`
- **GTK 3**: `~/.config/gtk-3.0/settings.ini`
- **GTK 4**: `~/.config/gtk-4.0/settings.ini`

Ejemplo (`~/.config/gtk-4.0/settings.ini`):

```ini
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=Breeze-Dark
gtk-font-name=Hack 10
```

### Asegurar que se aplique en aplicaciones root

```bash
sudo nano ~/.gtkrc-2.0
sudo nano ~/.config/gtk-3.0/settings.ini
sudo nano ~/.config/gtk-4.0/settings.ini
```

---

## 3. Instalación de paquetes

### Actualizar el sistema

```bash
sudo pacman -Syu
```

### Paquetes base y sistema

```bash
sudo pacman -S grub os-prober base base-devel bash-completion networkmanager \
  intel-speed-select intel-ucode alsa-firmware alsa-plugins alsa-utils lib32-mesa \
  linux-firmware linux-zen linux-zen-headers pavucontrol pipewire pipewire-alsa \
  pipewire-audio pipewire-jack pipewire-pulse reflector sddm sddm-kcm sudo ufw \
  gufw fish ntfs-3g timeshift usbguard x86_energy_perf_policy
```

### Interfaz y Hyprland

```bash
sudo pacman -S xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs \
  xorg-xhost flameshot python-pywal hypridle hyprland hyprlock hyprpolkitagent \
  waybar network-manager-applet seahorse swaync wl-clipboard wofi breeze \
  breeze-gtk gtk3-demos gtk4-demos noto-fonts noto-fonts-cjk noto-fonts-emoji \
  noto-fonts-extra ttf-hack ttf-inconsolata ttf-nerd-fonts-symbols \
  ttf-nerd-fonts-symbols-mono ttf-recursive-nerd ttf-roboto-mono-nerd \
  otf-firamono-nerd otf-font-awesome gnu-free-fonts
```

### Utilidades

```bash
sudo pacman -S cdrtools gnome-disk-utility gnome-keyring cmake dolphin firefox \
  p7zip gparted kcalc kitty man-db mpv nano neovim nwg-drawer nwg-look udftools \
  unzip vlc wget xterm zip
```

### Aplicaciones extras

```bash
sudo pacman -S obs-studio obsidian fastfetch nodejs npm virtualbox lazygit \
  luarocks htop github-cli codeblocks cool-retro-term gcc gdb git
```

### Con AUR (yay)

Actualizar:

```bash
yay -Syu
```

Paquetes AUR:

```bash
yay -S wlogout wlogout-debug brave-bin visual-studio-code-bin vt-cli vt-cli-debug
```

### Paquetes opcionales

- `xdg-utils`: Abrir archivos con aplicaciones asociadas.
- `ark`: Gestor de archivos comprimidos (.zip, etc.).
- `fbset`: Cambiar resolución/orientación en TTY.
- `grim`: Captura de pantalla ligera.

---

## 4. Habilitar servicios

```bash
# NetworkManager
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# SDDM (login manager)
sudo systemctl enable sddm

# UFW (firewall)
sudo systemctl enable ufw
sudo systemctl start ufw

# USBGuard
sudo systemctl enable usbguard
sudo systemctl start usbguard

# xdg-desktop-portal (para Hyprland)
systemctl --user enable xdg-desktop-portal-hyprland.service
systemctl --user start xdg-desktop-portal-hyprland.service

# PipeWire (audio)
systemctl --user enable pipewire pipewire-pulse
systemctl --user start pipewire pipewire-pulse
```

---

## 5. Configuración de Hyprland y componentes

### Hyprland base (`~/.config/hypr/hyprland.conf`)

```hyprland
# Monitor
monitor=,preferred,auto,1

# Variables
$mod = SUPER
$term = kitty

# Input
input {
    kb_layout = es
    follow_mouse = 1
    sensitivity = 0
}

# Decoración
decoration {
    rounding = 10
    active_opacity = 0.95
    inactive_opacity = 0.85
    blur = yes
    blur_size = 3
}

# Animaciones
animations {
    enabled = yes
    animation = windows, 1, 5, default
    animation = workspaces, 1, 3, default
}

# Binds
bind = $mod, Return, exec, $term
bind = $mod, Q, killactive,
bind = $mod, E, exec, dolphin
bind = $mod, V, togglefloating,
bind = $mod, D, exec, wofi --show drun
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5

# Window rules
windowrule = float, nm-connection-editor
windowrule = float, pavucontrol

# Exec al inicio (ver hypridle.conf y hyprlock.conf)
exec-once = ~/.config/hypr/start.sh
exec-once = waybar
exec-once = swaync
```

**Script de inicio** (`~/.config/hypr/start.sh`):

```bash
#!/bin/bash

# Generar tema con pywal
wal -i ~/Imágenes/wallpaper.jpg -n

# Cargar colores en Hyprland
source ~/.cache/wal/colors-hyprland.conf

# Iniciar dbus
dbus-launch --exit-with-session

# Opcional: nwg-drawer en background
nwg-drawer -c 7 -r &
```

Hacer ejecutable:

```bash
chmod +x ~/.config/hypr/start.sh
```

### Hyprlock (`~/.config/hypr/hyprlock.conf`)

```ini
[general]
auth-fail-text = Contraseña incorrecta
ignore_empty_password = false
hide_input = false

# Fondo de pantalla
[background]
monitor =
path = ~/.cache/wal/wallpaper.jpg
blur_passes = 3
blur_size = 8

# Campo de entrada de contraseña
[input-field]
monitor =
size = 200, 50
outline_thickness = 3
dots_size = 0.33
dots_spacing = 0.15
outer_color = rgb(238, 238, 238)
inner_color = rgb(50, 50, 50)
font_color = rgb(255, 255, 255)
fade_on_empty = false
```

### Hypridle (`~/.config/hypr/hypridle.conf`)

```ini
general {
    lock_cmd = hyprlock
    unlock_cmd = pkill -SIGUSR1 hyprlock
    before_sleep_cmd = hyprlock
    after_sleep_cmd =
}

listener {
    timeout = 300
    on-timeout = hyprlock
}

listener {
    timeout = 330
    on-timeout = systemctl suspend
    on-resume = systemctl suspend-cancel
}
```

### Waybar (`~/.config/waybar/config.jsonc`)

```jsonc
{
  "layer": "top",
  "height": 30,
  "modules-left": ["hyprland/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["tray", "network", "battery"],

  "hyprland/workspaces": {
    "format": "{id}",
    "on-click": "activate",
  },

  "clock": {
    "format": "{:%H:%M}",
    "tooltip-format": "{:%Y-%m-%d}",
  },

  "network": {
    "format": "⚡ {ifname}",
    "format-wifi": "📡 {essid}",
    "format-disconnected": "❌",
  },

  "battery": {
    "format": "🔋 {capacity}%",
  },

  "tray": {
    "icon-size": 20,
  },
}
```

**Estilo** (`~/.config/waybar/style.css`):

```css
* {
  font-family: "Hack", monospace;
  font-size: 13px;
  color: #ffffff;
}

window {
  background: #1e1e2e;
  border-bottom: 1px solid #45475a;
}

#workspaces button {
  padding: 0 5px;
  margin: 0 2px;
}

#workspaces button.active {
  background: #a6e3a1;
  color: #000000;
  border-radius: 5px;
}

#clock,
#network,
#battery,
#tray {
  padding: 0 10px;
}
```

### Wofi (`~/.config/wofi/config`)

```ini
width=500
height=400
always_on_top=true
show=drun
allow_images=true
allow_markup=true
```

**Estilo** (`~/.config/wofi/style.css`):

```css
window {
  background-color: #1e1e2e;
  border: 1px solid #45475a;
  border-radius: 8px;
}

#input {
  background-color: #313244;
  color: #cdd6f4;
  padding: 10px;
  border-radius: 8px;
}

#entry:selected {
  background-color: #a6e3a1;
  color: #000000;
}
```

### Swaync (`~/.config/swaync/config.json`)

```json
{
  "notification-window-width": 500,
  "notification-body-image-height": 100,
  "notification-body-image-width": 200,
  "positionX": "right",
  "positionY": "top",
  "layer": "overlay",
  "control-center-margin-top": 0,
  "control-center-margin-bottom": 0,
  "control-center-margin-right": 0,
  "control-center-margin-left": 0,
  "notification-2fa-action": true,
  "notification-inline-replies": false,
  "notification-icon-size": 64,
  "notification-body-image-clip": true,
  "notification-urgency-colors": {
    "low": "#1e1e2e",
    "normal": "#313244",
    "critical": "#f38ba8"
  }
}
```

---

## 6. Variables de entorno y enlaces simbólicos

### Variables de entorno (`~/.profile` o `~/.config/environment.d/50-qt.conf`)

Para que Qt y GTK usen el tema correcto:

```bash
# ~/.profile
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_SCALE_FACTOR=1
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XCURSOR_THEME=Breeze_cursors
export XCURSOR_SIZE=24
```

O en `~/.config/environment.d/50-qt.conf`:

```ini
QT_QPA_PLATFORMTHEME=qt5ct
QT_SCALE_FACTOR=1
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
```

### Enlaces simbólicos para color-schemes

```bash
# Crear directorio si no existe
mkdir -p ~/.local/share/color-schemes

# Enlace del esquema de pywal (se crearán después de generar tema)
ln -sf ~/.cache/wal/BreezeDarkPywal.colors ~/.local/share/color-schemes/BreezeDarkPywal.colors
```

---

## 7. Post-instalación y configuración inicial

### Generar tema inicial con Pywal

```bash
# Instalar si no está ya
sudo pacman -S python-pywal

# Generar colores desde una imagen
wal -i ~/Imágenes/wallpaper.jpg -n

# Generar colores para Hyprland
wal -c  # Limpiar caché si es necesario
wal -i ~/Imágenes/wallpaper.jpg -n
```

Pywal creará automáticamente:

- `~/.cache/wal/colors-hyprland.conf` (para Hyprland)
- `~/.cache/wal/colors.wal` (archivo de colores)
- `~/.cache/wal/wallpaper.jpg` (fondo de pantalla)

**Integración con Hyprland**: Agregar al final de `~/.config/hypr/hyprland.conf`:

```hyprland
source = ~/.cache/wal/colors-hyprland.conf
```

### Configurar Fish como shell predeterminado

```bash
# Ver ruta exacta
which fish

# Cambiar shell (requiere contraseña)
chsh -s /usr/bin/fish

# Copiar configuración básica de shell
mkdir -p ~/.config/fish
cp backsource/config/fish/config.fish ~/.config/fish/
```

### Configurar SDDM (pantalla de login)

Opción 1: Usar un tema elegante

```bash
# Instalar tema Breeze
sudo pacman -S sddm-breeze-theme

# O desde AUR:
yay -S sddm-sugar-candy
```

Editar `/etc/sddm.conf.d/kde_settings.conf`:

```ini
[General]
Session=plasmawayland
Theme=breeze
```

Opción 2: Aplicar tema GTK a SDDM

```bash
sudo mkdir -p /usr/share/sddm/themes/my-theme
sudo cp -r ~/.config/gtk-4.0 /usr/share/sddm/themes/my-theme/
```

### Configurar permisos de nwg-look

Si `nwg-look` no guarda cambios:

```bash
# Asegurar permisos en GTK
mkdir -p ~/.config/gtk-{3.0,4.0}
chmod 755 ~/.config/gtk-{3.0,4.0}

# Resetear configuración si es necesario
rm ~/.config/gtk-4.0/settings.ini
rm ~/.config/gtk-3.0/settings.ini
```

---

## 8. Problemas comunes y soluciones

### 8.1 Pantalla LVDS-1 no se apaga completamente

**Síntomas**: La pantalla integrada sigue consumiendo energía o se ve distorsionada.

**Soluciones**:

```bash
# Verificar pantallas conectadas
wlr-randr

# Desactivar en tiempo real
wlr-randr --output LVDS-1 --off

# O agregar a hyprland.conf
monitor = LVDS-1, disabled

# Crear script en ~/.config/hypr/start.sh
#!/bin/bash
sleep 1
wlr-randr --output LVDS-1 --off
```

### 8.2 SDDM no aplica tema GTK/Qt

**Síntomas**: SDDM muestra tema por defecto, ignorando configuración de GTK.

**Soluciones**:

1. Instalar tema para SDDM:

```bash
sudo pacman -S sddm-breeze-theme
# o
yay -S sddm-sugar-candy
```

2. Configurar SDDM explícitamente:

```bash
sudo nano /etc/sddm.conf.d/kde_settings.conf
```

3. Copiar variables a raíz:

```bash
sudo cp ~/.config/gtk-4.0/settings.ini /root/.config/gtk-4.0/settings.ini
sudo cp ~/.gtkrc-2.0 /root/.gtkrc-2.0
```

### 8.3 Sin salida de audio

**Síntomas**: No hay sonido en altavoces o auriculares.

**Soluciones**:

```bash
# Verificar estado de PipeWire
systemctl --user status pipewire

# Reiniciar PipeWire
systemctl --user restart pipewire pipewire-pulse

# Abrir mezclador de audio
pavucontrol

# En pavucontrol, verificar:
# - Pestaña "Output Devices": debe haber dispositivo seleccionado
# - Pestaña "Playback": debe haber volumen en las aplicaciones
# - Pestaña "Configuration": seleccionar perfil de audio

# Si aún no funciona, revisar dmesg
dmesg | grep -i audio
dmesg | grep -i sound
```

### 8.4 VirtualBox sin puertos USB

**Síntomas**: Los puertos USB no se reconocen en VirtualBox.

**Soluciones**:

```bash
# Cargar módulo vboxdrv
sudo modprobe vboxdrv

# Hacerlo permanente
echo "vboxdrv" | sudo tee /etc/modules-load.d/vboxdrv.conf

# Agregar usuario al grupo vboxusers
sudo usermod -aG vboxusers $USER

# Reiniciar sesión o:
newgrp vboxusers
```

### 8.5 nwg-look no guarda configuración de GTK

**Síntomas**: Los cambios en nwg-look no persisten.

**Soluciones**:

```bash
# Verificar permisos
ls -la ~/.config/gtk-3.0/
ls -la ~/.config/gtk-4.0/

# Corregir permisos si es necesario
chmod 755 ~/.config/gtk-{3.0,4.0}
chmod 644 ~/.config/gtk-{3.0,4.0}/settings.ini

# Recrear archivos si están corruptos
rm ~/.config/gtk-4.0/settings.ini
rm ~/.config/gtk-3.0/settings.ini

# Abrir nwg-look de nuevo y aplicar tema
nwg-look
```

### 8.6 Hyprland no carga variables de pywal

**Síntomas**: Los colores de pywal no aparecen en Hyprland.

**Soluciones**:

```bash
# Verificar que el archivo existe
cat ~/.cache/wal/colors-hyprland.conf

# Agregar al final de hyprland.conf
source = ~/.cache/wal/colors-hyprland.conf

# O en ~/.config/hypr/start.sh
wal -i ~/Imágenes/wallpaper.jpg -n
sleep 0.5
source ~/.cache/wal/colors-hyprland.conf

# Recargar Hyprland
hyprctl reload
```

### 8.7 Waybar no se inicia

**Síntomas**: Waybar no aparece o se cierra inmediatamente.

**Soluciones**:

```bash
# Revisar logs
waybar -l debug

# Verificar sintaxis JSON de config
jq empty ~/.config/waybar/config.jsonc

# Restaurar configuración por defecto
cp /etc/xdg/waybar/config ~/.config/waybar/config.backup
rm ~/.config/waybar/config*

# Reiniciar Hyprland
hyprctl dispatch exec waybar
```

### 8.8 Wofi no ejecuta aplicaciones

**Síntomas**: Wofi abre pero las aplicaciones no se lanzan.

**Soluciones**:

```bash
# Verificar configuración
cat ~/.config/wofi/config

# Asegurar que show=drun está correcto
nano ~/.config/wofi/config

# Probar modo de búsqueda diferente
wofi --show run  # En lugar de drun

# Revisar archivos .desktop
ls /usr/share/applications/*.desktop | head -5
```

### 8.9 xdg-desktop-portal no funciona en Hyprland

**Síntomas**: Diálogos de archivos/selección no funcionan en aplicaciones.

**Soluciones**:

```bash
# Habilitar e iniciar xdg-desktop-portal
systemctl --user enable xdg-desktop-portal-hyprland
systemctl --user start xdg-desktop-portal-hyprland

# Verificar estado
systemctl --user status xdg-desktop-portal-hyprland

# Probar con una aplicación
kitty -e firefox  # Abrir Firefox desde terminal para ver errores

# Si no funciona, revisar logs
journalctl --user -u xdg-desktop-portal-hyprland -f
```

### 8.10 Parpadeo o tearing en Hyprland

**Síntomas**: La pantalla parpadea o se ve despedazada.

**Soluciones**:

```bash
# Agregar a hyprland.conf
render {
    explicit_sync = 1
    explicit_sync_kms = 0
}

monitor = <nombre>, vsync:1

# O deshabilitar por defecto y usar en gráficos intensivos
env = LIBVA_DRIVER_NAME,iHD
env = VDPAU_DRIVER,va_gl
```

---

## 9. Copiar configuración de usuario

Una vez que todo esté configurado, guardar la configuración personal:

```bash
# Copiar configuración desde respaldo o desde directorio local
cp -r backsource/config/* ~/.config

# O copiar selectivamente según se necesite
cp -r backsource/config/hypr ~/.config/
cp -r backsource/config/waybar ~/.config/
cp -r backsource/config/wofi ~/.config/
cp -r backsource/config/swaync ~/.config/
cp -r backsource/config/kitty ~/.config/
cp -r backsource/config/nvim ~/.config/
cp -r backsource/config/fish ~/.config/
```

Para actualizar el respaldo después de cambios:

```bash
cp -r ~/.config/hypr backsource/config/
cp -r ~/.config/waybar backsource/config/
# ... etc
```

---

## Notas finales

- **Seguridad**: Revisar reglas de UFW según necesidad. USBGuard puede bloquear dispositivos USB inesperados.
- **Rendimiento**: En laptops, considerar usar `powertop` para optimizar consumo de energía.
- **Respaldos**: Mantener `backsource/config` sincronizado con cambios de configuración.
- **Actualizaciones**: Ejecutar `sudo pacman -Syu` regularmente. AUR requiere `yay -Syu`.

¡Buena suerte con la configuración!
