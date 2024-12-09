if status is-interactive
    # Commands to run in interactive sessions can go here
end

# source ~/.asdf/asdf.fish
alias py="python3"

fish_add_path /opt/nvim-linux64/bin
fish_add_path /home/charlie/.local/bin 
fish_add_path /usr/local/go/bin
fish_add_path /home/charlie/go/bin
fish_add_path /home/charlie/.local/protobuf/bin
fish_add_path /home/charlie/Downloads/zen.linux-specific/zen/

export EDITOR=nvim
alias n="nvim"

zoxide init fish | source

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fastfetch

# pnpm
set -gx PNPM_HOME "/home/charlie/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end

alias npm="pnpm"
# pnpm end
