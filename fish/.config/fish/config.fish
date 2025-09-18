if status is-interactive
    # Commands to run in interactive sessions can go here
end

set --universal pure_enable_single_line_prompt true
# https://pure-fish.github.io/pure/components/colours/
# set --universal pure_color_mute white

alias py="python3"
source "$HOME/.cargo/env.fish"

# fish_add_path /opt/nvim-linux-x86_64/bin
# fish_add_path /home/charlie/.local/bin
# fish_add_path /usr/local/go/bin
# fish_add_path /home/charlie/go/bin
# fish_add_path /home/charlie/.local/protobuf/bin
# fish_add_path /home/charlie/Downloads/zen.linux-specific/zen/

export EDITOR=nvim
alias n="nvim"
alias s="kitten ssh"
alias ls="ls -a"
alias changeYoyoBase="cp $HOME/finofo/config/base.py $HOME/finofo/finofo-app-api/.venv/lib/python3.12/site-packages/yoyo/backends/base.py"
alias rollbackYoyoBase="cp $HOME/finofo/config/base.rollback.py $HOME/finofo/finofo-app-api/.venv/lib/python3.12/site-packages/yoyo/backends/base.py"

zoxide init fish | source
pyenv init - fish | source

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fastfetch

# pnpm
# set -gx PNPM_HOME "/home/charlie/.local/share/pnpm"
# if not string match -q -- $PNPM_HOME $PATH
#   set -gx PATH "$PNPM_HOME" $PATH
# end
# pnpm end

# Created by `pipx` on 2025-09-10 18:06:20
set PATH $PATH /Users/charliekim/.local/bin
