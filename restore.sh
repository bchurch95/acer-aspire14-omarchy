#!/usr/bin/env bash
# ==============================================================================
# Omarchy User Preferences & Desktop Restoration Script
# Repository: https://github.com/bchurch95/omarchy-config
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"

BOLD="$(tput bold 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
RESET="$(tput sgr0 2>/dev/null || echo '')"

log_info()    { echo "${BLUE}${BOLD}==>${RESET} $*"; }
log_success() { echo "${GREEN}${BOLD} [OK]${RESET} $*"; }
log_warn()    { echo "${YELLOW}${BOLD}[WARN]${RESET} $*"; }

usage() {
  cat <<EOF
${BOLD}Omarchy Preferences Restore Tool${RESET}

Usage: $0 [option]

Options:
  --all         Deploy all user configurations and synchronize shell plugins
  --configs     Deploy only user configurations (~/.config, ~/.local/bin, ~/.local/share)
  --plugins     Clone and synchronize all curated plugins via bchurch95/omarchy-plugins
  --packages    Install explicit application packages via pacman / yay
  --help        Show this help message

Running without arguments will launch the interactive menu.
EOF
}

check_prerequisites() {
  for pkg in git jq curl; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      log_info "Installing required utility: $pkg..."
      if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm "$pkg" || true
      fi
    fi
  done
}

restore_user_configs() {
  log_info "Restoring User Configurations (~/.config, ~/.local)..."

  # Hyprland
  mkdir -p "$HOME/.config/hypr"
  cp -v "$CONFIGS_DIR/hypr/"*.lua "$HOME/.config/hypr/"
  log_success "Hyprland configs restored (bindings, looknfeel, input, monitors, autostart)."

  # Omarchy Shell & Bar Modules
  mkdir -p "$HOME/.config/omarchy/bar/modules"
  cp -v "$CONFIGS_DIR/omarchy/shell.json" "$HOME/.config/omarchy/shell.json"
  cp -v "$CONFIGS_DIR/omarchy/bar/modules/"*.qml "$HOME/.config/omarchy/bar/modules/"
  if [[ -d "$CONFIGS_DIR/omarchy/shell-profiles" ]]; then
    mkdir -p "$HOME/.config/omarchy/shell-profiles"
    cp -rv "$CONFIGS_DIR/omarchy/shell-profiles/"* "$HOME/.config/omarchy/shell-profiles/"
  fi
  if [[ -d "$CONFIGS_DIR/omarchy/hooks" ]]; then
    mkdir -p "$HOME/.config/omarchy/hooks"
    cp -rv "$CONFIGS_DIR/omarchy/hooks/"* "$HOME/.config/omarchy/hooks/"
    find "$HOME/.config/omarchy/hooks" -type f -name "*.hook" -exec chmod +x {} +
  fi
  log_success "Omarchy shell layout, hooks, shell-profiles, and custom bar modules restored."

  # Custom / Local Plugins (ben.apple-music-button, ben.media, etc.)
  if [[ -d "$CONFIGS_DIR/plugins" ]]; then
    mkdir -p "$HOME/.config/omarchy/plugins"
    for plugin_dir in "$CONFIGS_DIR/plugins/"*; do
      if [[ -d "$plugin_dir" ]]; then
        plugin_name="$(basename "$plugin_dir")"
        mkdir -p "$HOME/.config/omarchy/plugins/$plugin_name"
        cp -rv "$plugin_dir/"* "$HOME/.config/omarchy/plugins/$plugin_name/"
        log_success "Local plugin $plugin_name restored."
      fi
    done
  fi

  # Custom Themes
  if [[ -d "$CONFIGS_DIR/themes" ]]; then
    mkdir -p "$HOME/.config/omarchy/themes"
    cp -rv "$CONFIGS_DIR/themes/"* "$HOME/.config/omarchy/themes/"
    log_success "Custom themes (purple-rising, q2dm1) restored."
  fi

  # Terminals
  mkdir -p "$HOME/.config/alacritty" "$HOME/.config/ghostty" "$HOME/.config/kitty" "$HOME/.config/foot"
  [[ -f "$CONFIGS_DIR/terminals/alacritty.toml" ]] && cp -v "$CONFIGS_DIR/terminals/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  [[ -f "$CONFIGS_DIR/terminals/ghostty.config" ]] && cp -v "$CONFIGS_DIR/terminals/ghostty.config" "$HOME/.config/ghostty/config"
  [[ -f "$CONFIGS_DIR/terminals/kitty.conf" ]] && cp -v "$CONFIGS_DIR/terminals/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  [[ -f "$CONFIGS_DIR/terminals/foot.ini" ]] && cp -v "$CONFIGS_DIR/terminals/foot.ini" "$HOME/.config/foot/foot.ini"
  log_success "Terminal font sizes and configurations restored."

  # Chrome Flags & Desktop Launchers
  cp -v "$CONFIGS_DIR/chrome-flags.conf" "$HOME/.config/chrome-flags.conf"
  ln -sf chrome-flags.conf "$HOME/.config/google-chrome-flags.conf"
  ln -sf chrome-flags.conf "$HOME/.config/google-chrome-stable-flags.conf"
  ln -sf chrome-flags.conf "$HOME/.config/chromium-flags.conf"

  mkdir -p "$HOME/.local/bin"
  cp -v "$CONFIGS_DIR/local-bin/"* "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/"*

  mkdir -p "$HOME/.local/share/applications"
  cp -v "$CONFIGS_DIR/applications/Apple Music.desktop" "$HOME/.local/share/applications/Apple Music.desktop"

  # Application Icons
  if [[ -d "$CONFIGS_DIR/icons" ]]; then
    mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps"
    cp -v "$CONFIGS_DIR/icons/"* "$HOME/.local/share/icons/hicolor/256x256/apps/" 2>/dev/null || true
    command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
  fi
  log_success "Chrome flags, icons, and Apple Music isolated launcher restored."

  # Bash additions
  if [[ -f "$CONFIGS_DIR/bash/bashrc-additions.sh" ]]; then
    if ! grep -q "update-plugins" "$HOME/.bashrc" 2>/dev/null; then
      echo "" >> "$HOME/.bashrc"
      cat "$CONFIGS_DIR/bash/bashrc-additions.sh" >> "$HOME/.bashrc"
      log_success "Appended custom aliases to ~/.bashrc."
    fi
  fi

  # PipeWire Virtual Sinks & HomePod Audio Bridge
  if [[ -d "$CONFIGS_DIR/pipewire" ]]; then
    mkdir -p "$HOME/.config/pipewire/pipewire-pulse.conf.d"
    cp -v "$CONFIGS_DIR/pipewire/"*.conf "$HOME/.config/pipewire/pipewire-pulse.conf.d/"
  fi
  if [[ -d "$CONFIGS_DIR/systemd/user" ]]; then
    mkdir -p "$HOME/.config/systemd/user"
    cp -v "$CONFIGS_DIR/systemd/user/"*.service "$HOME/.config/systemd/user/"
    systemctl --user daemon-reload || true
    systemctl --user enable --now homepod-bridge.service 2>/dev/null || true
  fi
  if [[ -f "$CONFIGS_DIR/owntone/owntone.conf" ]]; then
    sudo mkdir -p /srv/music
    [[ ! -p /srv/music/desktop.pipe ]] && sudo mkfifo /srv/music/desktop.pipe || true
    sudo chmod 666 /srv/music/desktop.pipe || true
    sudo chmod 777 /srv/music || true
    sudo cp -v "$CONFIGS_DIR/owntone/owntone.conf" "/etc/owntone.conf"
    sudo systemctl enable --now owntone.service 2>/dev/null || true
    sudo systemctl restart owntone.service 2>/dev/null || true
  fi
  log_success "PipeWire HomePods sink and OwnTone AirPlay bridge restored."

  # PCIe ASPM & Power Management
  if [[ -f "$CONFIGS_DIR/tmpfiles.d/aspm.conf" ]]; then
    sudo mkdir -p /etc/tmpfiles.d
    sudo cp -v "$CONFIGS_DIR/tmpfiles.d/aspm.conf" /etc/tmpfiles.d/aspm.conf
    sudo systemd-tmpfiles --create /etc/tmpfiles.d/aspm.conf 2>/dev/null || true
  fi
  if [[ -f "$CONFIGS_DIR/limine-entry-tool.d/aspm.conf" && -d /etc/limine-entry-tool.d ]]; then
    sudo cp -v "$CONFIGS_DIR/limine-entry-tool.d/aspm.conf" /etc/limine-entry-tool.d/aspm.conf
  fi
  command -v powerprofilesctl >/dev/null && powerprofilesctl set balanced || true
  log_success "PCIe ASPM powersave policy and balanced power profile restored."

  # Reload desktop
  command -v hyprctl >/dev/null && hyprctl reload || true
  command -v omarchy >/dev/null && omarchy restart shell || true
}

restore_plugins() {
  check_prerequisites
  log_info "Synchronizing Omarchy Shell Plugins..."
  local PLUGINS_REPO_DIR="$HOME/Work/omarchy-plugins"

  if [[ ! -d "$PLUGINS_REPO_DIR/.git" ]]; then
    mkdir -p "$HOME/Work"
    log_info "Cloning bchurch95/omarchy-plugins repository..."
    git clone https://github.com/bchurch95/omarchy-plugins.git "$PLUGINS_REPO_DIR"
  else
    log_info "Updating bchurch95/omarchy-plugins repository..."
    git -C "$PLUGINS_REPO_DIR" pull --rebase || true
  fi

  if [[ -f "$PLUGINS_REPO_DIR/sync.sh" ]]; then
    bash "$PLUGINS_REPO_DIR/sync.sh" install
    log_success "All plugins installed and synchronized from plugins.json."
  else
    log_warn "sync.sh not found in $PLUGINS_REPO_DIR."
  fi
}

restore_packages() {
  local PKG_FILE="$CONFIGS_DIR/packages/explicit-packages.txt"
  if [[ ! -f "$PKG_FILE" ]]; then
    log_warn "Package list not found at $PKG_FILE."
    return 1
  fi

  log_info "Installing packages from $PKG_FILE..."
  local pkgs
  pkgs=$(awk '{print $1}' "$PKG_FILE")

  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm $pkgs || true
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm $pkgs || true
  fi
  log_success "Packages installation attempted."
}

# Main Execution
ACTION="${1:-}"

case "$ACTION" in
  --all)
    check_prerequisites
    restore_user_configs
    restore_plugins
    log_success "Complete desktop preferences restoration finished!"
    ;;
  --configs)
    restore_user_configs
    ;;
  --plugins)
    restore_plugins
    ;;
  --packages)
    restore_packages
    ;;
  --help|-h)
    usage
    ;;
  "")
    echo "${BOLD}Omarchy Preferences Restore Wizard${RESET}"
    echo "1) Restore All (User Configs, Themes, Terminals & Shell Plugins)"
    echo "2) Restore User Configs Only (~/.config, ~/.local)"
    echo "3) Restore & Synchronize Shell Plugins"
    echo "4) Install Application Packages"
    echo "q) Quit"
    read -rp "Select option [1-4/q]: " choice
    case "$choice" in
      1)
        check_prerequisites
        restore_user_configs
        restore_plugins
        log_success "All components successfully restored!"
        ;;
      2) restore_user_configs ;;
      3) restore_plugins ;;
      4) restore_packages ;;
      *) echo "Exiting without changes." ;;
    esac
    ;;
  *)
    echo "Unknown option: $ACTION" >&2
    usage
    exit 1
    ;;
esac
