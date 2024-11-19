if status is-interactive
    # Commands to run in interactive sessions can go here
end

source ~/.asdf/asdf.fish

fish_add_path /opt/nvim-linux64/bin
fish_add_path /home/charlie/.local/bin 
fish_add_path /usr/local/go/bin
fish_add_path /home/charlie/go/bin
fish_add_path /home/charlie/.local/protobuf/bin

export EDITOR=nvim

zoxide init fish | source
nvm use lts

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fastfetch
