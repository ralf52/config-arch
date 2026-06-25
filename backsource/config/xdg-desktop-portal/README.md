No, no es estrictamente obligatorio crearlo, pero sí es muy recomendable si quieres evitar que tus aplicaciones tengan comportamientos inesperados (como que el selector de archivos no muestre los temas de tu sistema o fallen ciertas integraciones). [1, 2, 3]
Instalar Arch a mano significa que no tienes un entorno de escritorio preconfigurando los portales por ti, por lo que ajustar el archivo portals.conf te da el control total sobre ellos. [2]
Aquí te detallo lo que necesitas saber y cómo hacer que Flameshot funcione correctamente:

## 1. El archivo portals.conf

Lo que hace este archivo es dictarle a xdg-desktop-portal cuál de los portales instalados debe priorizar para una tarea específica. [1, 2]

- Tu configuración actual: default=hyprland;gtk [2, 3]
- ¿Qué significa? Le dice al sistema que utilice xdg-desktop-portal-hyprland por defecto y que use xdg-desktop-portal-gtk como respaldo o para otras funciones (por ejemplo, el selector de archivos o cuadros de diálogo, ya que la versión de Hyprland no implementa esta función). [1, 3, 4, 5]
- La ruta correcta: La Wiki de Hyprland y la comunidad recomiendan ubicarlo específicamente en ~/.config/xdg-desktop-portal/hyprland-portals.conf (en lugar de portals.conf), aunque xdg-desktop-portal lee de varias rutas. [6, 7]

## 2. Lo que SÍ necesitas para que Flameshot funcione en Wayland

Más allá del archivo de configuración, para que Flameshot y otras aplicaciones accedan al sistema de capturas en Hyprland, asegúrate de cumplir con lo siguiente:

- Instalar los paquetes correctos: Debes tener instalados xdg-desktop-portal, xdg-desktop-portal-gtk y xdg-desktop-portal-hyprland. (Nota: Es vital que evites tener instalado xdg-desktop-portal-wlr junto con xdg-desktop-portal-hyprland, ya que D-Bus entrará en conflicto y fallarán las capturas). [8, 9, 10, 11, 12]
- Exportar la variable de entorno: Flameshot necesita saber en qué entorno de escritorio estás corriendo. En tu archivo de configuración de Hyprland (~/.config/hypr/hyprland.conf), asegúrate de tener la variable de la sesión seteada:
  env = XDG_CURRENT_DESKTOP,Hyprland [2, 4, 13]
- Lanzar la interfaz gráfica: Al lanzar la captura, asegúrate de llamarlo directamente con el subcomando GUI:
  flameshot gui [13, 14, 15]
- Habilitar el adaptador de Grim: La comunidad y la documentación aconsejan que Flameshot utilice el adaptador Grim para garantizar compatibilidad, agregando esto en la configuración general de Flameshot:
  useGrimAdapter=true [9, 14]

· 1970 M01 1
Para poder ayudarte a ajustar el archivo y que todo funcione a la perfección, dime:

- ¿Tienes instalado xdg-desktop-portal-wlr junto con la versión de Hyprland?
- ¿Estás utilizando algún lanzador de aplicaciones en específico para abrir el comando de Flameshot?

[1] [https://wiki.archlinux.org](https://wiki.archlinux.org/title/XDG_Desktop_Portal)
[2] [https://wiki.archlinux.org](https://wiki.archlinux.org/title/XDG_Desktop_Portal?useskin=vector)
[3] [https://wiki.hypr.land](https://wiki.hypr.land/0.50.0/Hypr-Ecosystem/xdg-desktop-portal-hyprland/)
[4] [https://wiki.archlinux.org](https://translate.google.com/translate?u=https://wiki.archlinux.org/title/XDG_Desktop_Portal&hl=es&sl=en&tl=es&client=sge)
[5] [https://wiki.hypr.land](https://translate.google.com/translate?u=https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland/&hl=es&sl=en&tl=es&client=sge)
[6] [https://wiki.hypr.land](https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland/)
[7] [https://discourse.nixos.org](https://discourse.nixos.org/t/portals-dont-work-on-hyprland-after-update-to-0-55-2-from-0-54-3/77816)
[8] [https://flameshot.org](https://flameshot.org/docs/guide/wayland-help/)
[9] [https://myhack.tech](https://myhack.tech/fixing-flameshot-on-hyprland-wayland-archlinux)
[10] [https://wiki.hypr.land](https://wiki.hypr.land/0.23.0beta/Useful-Utilities/Hyprland-desktop-portal/)
[11] [https://forum.hypr.land](https://forum.hypr.land/t/cant-start-xdg-desktop-portal-hyprland-automatically/460)
[12] [https://www.reddit.com](https://www.reddit.com/r/hyprland/comments/1m9oktp/properly_setting_up_xdgdesktopportalhyprland_is/)
[13] [https://www.reddit.com](https://www.reddit.com/r/arch/comments/1do46y6/flameshot_no_working_properly_archhyprland/?tl=es-419)
[14] [https://www.reddit.com](https://www.reddit.com/r/hyprland/comments/1cldxg8/binding_hyprshot_after_flameshot_failed/?tl=es-419)
[15] [https://github.com](https://github.com/flatpak/xdg-desktop-portal/issues/1070)

La variable useGrimAdapter=true se habilita directamente dentro del archivo de configuración global de Flameshot, ubicado en tu directorio de usuario en la ruta ~/.config/flameshot/flameshot.ini. [1, 2, 3]

## Paso a paso para configurarlo:

1.  Abre la terminal en tu entorno Hyprland.
2.  Crea el directorio y el archivo en caso de que no existan todavía (al ser una instalación limpia de Arch hecho a mano, es muy probable que debas crearlos) ejecutando:

mkdir -p ~/.config/flameshot
touch ~/.config/flameshot/flameshot.ini

3.  Abre el archivo con tu editor de texto favorito (por ejemplo, nano o vim):

nano ~/.config/flameshot/flameshot.ini

4.  Agrega el bloque de configuración exactamente de la siguiente manera:

[General]
useGrimAdapter=true

5.  Guarda los cambios (En nano se hace presionando Ctrl + O, luego Enter para confirmar, y Ctrl + X para salir). [4, 5, 6, 7]

## ⚠️ Nota importante sobre tu versión de Flameshot:

- Si estás utilizando Flameshot v13 o inferior, esta opción es fundamental en Wayland/Hyprland para que delegue la captura de pantalla a la herramienta grim bajo el capó y se salte los fallos de distorsión visual. Por supuesto, debes tener el paquete grim instalado en tu sistema Arch (sudo pacman -S grim). [1, 4, 8]
- Si actualizaste recientemente a Flameshot v14.0.0 o superior, los desarrolladores eliminaron la opción useGrimAdapter de los archivos de configuración debido a que rediseñaron por completo el soporte nativo para los xdg-desktop-portals. Si al ejecutar flameshot gui te da un error diciendo que la opción ya no está soportada, simplemente borra esa línea del archivo flameshot.ini. [9, 10]

Si quieres dejar tu atajo listo para capturar pantalla al instante, dime: ¿qué combinación de teclas te gustaría usar en tu hyprland.conf para activar Flameshot?

[1] [https://flameshot.org](https://translate.google.com/translate?u=https://flameshot.org/docs/guide/wayland-help/&hl=es&sl=en&tl=es&client=sge)
[2] [https://flameshot.org](https://flameshot.org/docs/advanced/configuration/)
[3] [https://codesandbox.io](https://codesandbox.io/p/github/flameshot-org/flameshot)
[4] [https://github.com](https://github.com/flameshot-org/flameshot/discussions/4147)
[5] [https://labex.io](https://labex.io/es/tutorials/linux-message-authentication-with-hmac-in-cryptography-632760)
[6] [https://labex.io](https://labex.io/es/tutorials/linux-terraform-outputs-management-632661)
[7] [https://colectivodisonancia.net](https://colectivodisonancia.net/herramientas/cifrado-gpg-terminal/)
[8] [https://github.com](https://github.com/flameshot-org/flameshot/issues/4195)
[9] [https://github.com](https://github.com/flameshot-org/flameshot/issues/4653)
[10] [https://github.com](https://github.com/flameshot-org/flameshot/issues/4653)
