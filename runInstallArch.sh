#!/bin/bash
# Script post-instalación para Arch Linux
# Ejecutar después de la instalación mínima de ArchWiki
# como usuario normal (no root)

set -euo pipefail # Detiene el script ante errores, variables no definidas o fallos en pipes

# --------------------------------------------
# Verificar que NO se ejecuta como root
# --------------------------------------------
if [ "$(whoami)" = "root" ]; then
  cat <<EOF
Antes de ejecutar este script, crea un usuario normal:
  # useradd -m -G wheel -s /usr/bin/bash tu_usuario
  # passwd tu_usuario
Luego inicia sesión con ese usuario y ejecuta:
  $ xdg-user-dirs-update --force
EOF
  exit 1
fi

# Directorio base donde se encuentra el script (para las copias de config)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKSOURCE="$SCRIPT_DIR/backsource"

# --------------------------------------------
# Actualizar sistema primero
# --------------------------------------------
sudo pacman -Syu --noconfirm

# --------------------------------------------
# Paquetes base y sistema
# --------------------------------------------
sudo pacman -S --needed --noconfirm \
  base-devel bash-completion networkmanager ntfs-3g \
  os-prober reflector sddm sddm-kcm sudo ufw gufw \
  fish timeshift x86_energy_perf_policy \
  pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse \
  alsa-firmware alsa-plugins alsa-utils pavucontrol \
  lib32-mesa plasma # Plasma completo (si deseas Hyprland únicamente, elimina 'plasma')

# --------------------------------------------
# Drivers Intel (si aplica)
# --------------------------------------------
sudo pacman -S --needed --noconfirm intel-ucode intel-speed-select

# --------------------------------------------
# Hyprland, wayland, temas y fuentes
# --------------------------------------------
sudo pacman -S --needed --noconfirm \
  hyprland hypridle hyprlock hyprpolkitagent uwsm \
  waybar wofi wl-clipboard swaync \
  xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs \
  python-pywal \
  gtk3 gtk4 gtk3-demos gtk4-demos breeze breeze-gtk nwg-look nwg-drawer \
  noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra \
  ttf-hack ttf-inconsolata ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono \
  ttf-recursive-nerd ttf-roboto-mono-nerd otf-firamono-nerd otf-font-awesome \
  gnu-free-fonts

# --------------------------------------------
# Utilidades
# --------------------------------------------
sudo pacman -S --needed --noconfirm \
  firefox kitty neovim dolphin gparted kcalc gnome-disk-utility \
  mpv vlc htop fastfetch cmake p7zip unzip zip wget \
  qt6-imageformat qt5ct qt6ct pam xorg-xhost \
  virtualbox virtualbox-host-modules-arch \
  obs-studio obsidian grim cdrtools udftools \
  gnome-keyring seahorse man-db nano xterm

# --------------------------------------------
# Neovim (LazyVim) y configuraciones
# --------------------------------------------
if [ -d "$BACKSOURCE/config" ]; then
  cp -r "$BACKSOURCE/config/"* ~/.config/
else
  echo "Advertencia: No se encontró $BACKSOURCE/config. Saltando copia de configuraciones."
fi
sudo pacman -S --needed --noconfirm luarocks nodejs npm lazygit

# --------------------------------------------
# Temas GTK y QT
# --------------------------------------------
mkdir -p ~/.themes/
THEME_SRC="$HOME/Descargas/config-arch/backsource/themes/gtk/Breeze-Dark-Simple-wall"
if [ -d "$THEME_SRC" ]; then
  cp -r "$THEME_SRC" ~/.themes/
else
  echo "Advertencia: Tema GTK no encontrado en $THEME_SRC"
fi

# Esquema de colores para Qt desde pywal (asegúrate de haber ejecutado 'wal' antes)
WAL_COLORS="$HOME/.cache/wal/BreezeDarkPywal.colors"
if [ -f "$WAL_COLORS" ]; then
  mkdir -p ~/.local/share/color-schemes/
  ln -sf "$WAL_COLORS" ~/.local/share/color-schemes/BreezeDarkPywal.colors
else
  echo "Advertencia: No se encontró $WAL_COLORS. Ejecuta 'wal' para generar el esquema."
fi

# --------------------------------------------
# Instalación de yay (AUR helper)
# --------------------------------------------
if ! command -v yay &>/dev/null; then
  echo "Instalando yay..."
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd "$SCRIPT_DIR"
else
  echo "yay ya está instalado."
fi

# --------------------------------------------
# Paquetes AUR
# --------------------------------------------
yay -S --noconfirm wlogout brave-bin visual-studio-code-bin vt-cli flameshot-git

# --------------------------------------------
# Habilitar servicios
# --------------------------------------------
sudo systemctl enable sddm.service

# Servicios de usuario (sin sudo)
systemctl --user enable --now waybar.service 2>/dev/null || echo "waybar.service no se pudo habilitar (posiblemente no instalado)"
systemctl --user enable --now swaync.service 2>/dev/null || echo "swaync.service no disponible"
systemctl --user enable --now nm-applet.service 2>/dev/null || echo "nm-applet.service no disponible (puedes iniciar nm-applet con tu WM)"

# --------------------------------------------
# Mensajes finales
# --------------------------------------------
echo "
 --- Post-instalación completada ---

 Recuerda:
 - Activar os-prober en /etc/default/grub si tienes windows o mac-os y regenera grub.
 - Para usar xauth con PAM, edita /etc/pam.d/other y añade:
     session optional   pam_xauth.so
 - Ejecuta 'wal' para generar la paleta de colores si deseas los temas Pywal manualmente o una ves dentro con [ win + shift + r ].
 - Activa tus temas en nwg-look [BreezeDarkPywal] y en las configuraciones kde elige Brezze y los colores de [ BreezeDarkPywal ]
"
