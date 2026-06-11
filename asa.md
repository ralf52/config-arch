# NOTAS CONFIGURACION ARCH + HYPRLAND

## Eliminar la pantalla muerta LVDS-1

Ubicación `/etc/default/grub`
loglevel=3 es para evitar ruido al tener 2 sistemas operativos
video=LVDS-1:d Es para que esa pantalla este apagada desde el arranque

```grub
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 video=LVDS-1:d"

GRUB_DISABLE_OS_PROBER=false
```

## Configurar temas gtk y qt

[Aspecto Uniforme Qt y Gtk](https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications)
[Seleccionar tema gtk](https://wiki.archlinux.org/title/GTK#Theme_not_applied_to_root_applications)
[Seleccionar tema qt](https://wiki.archlinux.org/title/Qt#Theme_not_applied_to_root_applications)

```bash
sudo pacman -S qt5ct qt6ct gtk3 gtk4 breeze breeze-gtk
```

## Qt

Cree un enlace simbolico en `~/.local/share/color-schemes/` de `~/.cache/wall/BreezeDarkPywal.colors`

[Variables de entorno](https://wiki.archlinux.org/title/Environment_variables#Defining_variables)

## Uso de un tema de icono GTK en aplicaciones Qt

Si no está utilizando un [entorno de escritorio](https://wiki.archlinux.org/title/Desktop_environment "Entorno de escritorio"), por ejemplo si está ejecutando un sistema mínimo con [i3-wm](https://archlinux.org/packages/?name=i3-wm), [instal](https://wiki.archlinux.org/title/Install "Instalar") [ldconf-editor](https://archlinux.org/packages/?name=dconf-editor) y configure el tema del ícono como se explicó anteriormente. Es posible que también tengas que establecer el valor`DESKTOP_SESSION` en tu perfil. Consulte [Variables de entorno#Defining variables](https://wiki.archlinux.org/title/Environment_variables#Defining_variables "Variables ambientales") para conocer las posibles formas de obtener el resultado deseado.

## Instalar Paquetes

```bash
# Actualizar
sudo pacman -Syu;

# Sistema
sudo pacman -S
grub
os-prober
base
base-devel
bash-completion
networkmanager
intel-speed-select
intel-ucode
alsa-firmware
alsa-plugins
alsa-utils
lib32-mesa
linux-firmware
linux-zen
linux-zen-headers
pavucontrol
pipewire
pipewire-alsa
pipewire-audio
pipewire-jack
pipewire-pulse
reflector
sddm
sddm-kcm
sudo
ufw
gufw
fish
ntfs-3g
timeshift
usbguard
x86_energy_perf_policy
;
# Interfaz
sudo pacman -S
xdg-desktop-portal-gtk
xdg-desktop-portal-hyprland
xdg-user-dirs
xorg-xhost
awww
flameshot
python-pywal
hypridle
hyprland
hyprlock
hyprpolkitagent
waybar
network-manager-applet
seahorse
swaync
wl-clipboard
wofi
breeze
breeze-gtk
gtk3-demos
gtk4-demos
noto-fonts
noto-fonts-cjk
noto-fonts-emoji
noto-fonts-extra
ttf-hack
ttf-inconsolata
ttf-nerd-fonts-symbols
ttf-nerd-fonts-symbols-mono
ttf-recursive-nerd
ttf-roboto-mono-nerd
otf-firamono-nerd
otf-font-awesome
gnu-free-fonts
;
# Utilidades
sudo pacman -S
cdrtools
gnome-disk-utility
gnome-keyring
cmake
dolphin
firefox
7zip
gparted
kcalc
kitty
man-db
mpv
nano
neovim
nwg-drawer
nwg-look
udftools
unzip
vlc
wget
xterm
zip
;
# Apps Extra
sudo pacman -S
obs-studio
obsidian
fastfetch
nodejs
npm
virtualbox
lazygit
luarocks
htop
github-cli
codeblocks
cool-retro-term
gcc
gdb
git
;
```

```bash
#Actualizar
yay -Syu;

# Sistema
yay -S
wlogout
wlogout-debug
;
# Apps
yay -S
brave-bin
visual-studio-code-bin
vt-cli
vt-cli-debug
;
```

### Recomendados

xdg-utils - abrir archivos con ciertas apps antes usaba perl-file-mimeinfo

### Podrian Interesarte

ark - archivos .zip
fbset - cambiar la resolución, los colores o la orientación de la pantalla en la TTY
grim - graba la pantalla ligeramente

## Copiar Configuracion de Usuario

```bash
cp backsources/config/* ~/.config
```
