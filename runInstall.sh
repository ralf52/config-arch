#!/bin/bash
# Script post instalacion este script esta hecho para ejecutarse
# despues de haber instalado una instalacion minima de la archWIKI
# y debe ejecutarse este script dentro de un usuario que no sea root

# Comprobar que estes dentro de un usuario
if [[ whoami == root ]]; then
  echo "Antes de ejecutar este script crea un usuario con/n \ 
  # useradd -m -G wheel -s /usr/bin/bash tu_usuario \
  y despues añadele contraseña con 
  # passwd tu_usuario/n \
  y por ultimo inicia sesion e instala y ejecuta
  # pacman -S xdg-user-dirs-update
  # -u tu_usuario xdg-user-dirs-update --force
  "
fi

# Instalar Sistema
sud pacman -S sudo qt5ct qt6ct gtk3 gtk4 breeze \
  breeze-gtk nwg-look nwg-drawer \
  os-prober base-devel \
  bash-completion networkmanager \
  alsa-firmware alsa-plugins \
  alsa-utils lib32-mesa pavucontrol \
  pipewire pipewire-alsa \
  pipewire-audio pipewire-jack \
  pipewire-pulse reflector sddm \
  sddm-kcm sudo ufw \
  gufw fish ntfs-3g timeshift usbguard \
  x86_energy_perf_policy plasma

# Instalar Drivers intel
sudo pacman -S intel-speed-select intel-ucode

# Instalar Interfaz
sudo pacman -S sudo pacman -S xdg-desktop-portal-gtk \
  xdg-desktop-portal-hyprland xdg-user-dirs \
  pam xorg-xhost python-pywal hypridle \
  uwm hyprland hyprlock hyprpolkitagent \
  waybar network-manager-applet seahorse swaync \
  wl-clipboard wofi breeze breeze-gtk gtk3-demos \
  gtk4-demos noto-fonts noto-fonts-cjk noto-fonts-emoji \
  noto-fonts-extra ttf-hack ttf-inconsolata ttf-nerd-fonts-symbols \
  ttf-nerd-fonts-symbols-mono ttf-recursive-nerd ttf-roboto-mono-nerd \
  otf-firamono-nerd otf-font-awesome gnu-free-fonts
#Instalar Utilidades
sudo pacman -S htop obs-studio obsidian fastfetch virtualbox \
  grim qt6-imageformat cdrtools gnome-disk-utility gnome-keyring cmake dolphin firefox \
  p7zip gparted kcalc kitty man-db mpv nano neovim nwg-drawer nwg-look udftools \
  unzip vlc wget xterm zip

# Nvim LazyVim y configuraciones generales
cp backsource/config/* ~/.config/
sudo pacman -S luarocks nodejs npm lazy-git

# Servicios
sudo systemctl enable sddm.service
sudo systemctl --user enable waybar.service swaync.service network-manager-applet.service

# Copiar configuracion de temas
# gtk
mkdir -P ~/.themes/
cp ~/Descargas/config-arch/backsource/themes/gtk/Breeze-Dark-Simple-wall/ ~/.themes/
# qt
ln -sf ~/.cache/wal/BreezeDarkPywal.colors ~/.local/share/color-schemes/BreezeDarkPywal.colors

# Instalar AUR (Este script fue sacado del github de https://github.com/Jguer/yay)
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si

# Instalar utilidades
yay -S wlogout brave-bin visual-studio-code-bin vt-cli flameshot-git
echo "
      Os-prober Instalado Activelo en /etc/default/grub\n\n \
      
      -para PAM esta instalado solo agregue a /etc/pam.d/other las siguientes lineas\n \
      session optional   pam_xauth.so\n 
      Si no pudo ver los mensajes completos revise el codigo final del script
      "
