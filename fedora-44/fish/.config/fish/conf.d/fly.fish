# flyctl (installed via fly.io/install.sh)
set -gx FLYCTL_INSTALL "$HOME/.fly"
test -d "$FLYCTL_INSTALL/bin" && fish_add_path "$FLYCTL_INSTALL/bin"
