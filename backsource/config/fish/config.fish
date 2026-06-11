if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Wrapper para nvim con socket por instancia
function nvim
    # No inyectar --listen cuando se usa nvim en modo remoto/headless.
    if contains -- --server $argv; or contains -- --headless $argv
        command nvim $argv
        return
    end

    set -l socket "/tmp/nvim-"(date +%s)"-"(random)".pipe"
    command nvim --listen "$socket" $argv
end

# Cargar colores de pywal
#if test -e ~/.cache/wal/colors.fish
#    source ~/.cache/wal/colors.fish
#end

# Función para ir a cualquier proyecto dinámicamente
function pro
    cd "$HOME/proyectos/$argv[1]"
end
# Autocompletado para el comando pro
complete -c pro -f -a "(ls $HOME/proyectos/)"

# Función para ir a cualquier proyecto dinámicamente
function uni
    cd "$HOME/proyectos/Apuntes-Universidad--Informatica/$argv[1]"
end
# Autocompletado para el comando pro
complete -c uni -f -a "(ls $HOME/proyectos/Apuntes-Universidad--Informatica/)"

# Ejecutables home/.local
set -gx PATH $HOME/.local/bin $PATH

alias reloadMirrors="sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist && sudo pacman -Scc --noconfirm && sudo pacman -Syyu --noconfirm"
alias update="sudo pacman -Syu && sudo pacman -Sc && yay -Syu && yay -Sc"
alias updates="sudo pacman -Syu --noconfirm && sudo pacman -Sc --noconfirm && yay -Syu --noconfirm && yay -Sc --noconfirm && sudo shutdown now"
alias neu="cd $HOME/proyectos/NeuroSupport/client/src/"
alias tare="cd $HOME/proyectos/tareasPOO/"

alias image="kitty +kitten icat"
