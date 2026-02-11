#!/usr/bin/env bash
#
# Catppuccin Theme Switcher
# Dynamically switches themes for kitty, tmux, and other applications
# Based on system theme (dark/light)

set -euo pipefail

# Configuration
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
THEME_STATE_DIR="$XDG_STATE_HOME/theme-switcher"
THEME_STATE_FILE="$THEME_STATE_DIR/current-theme"

# Logging
LOG_FILE="$THEME_STATE_DIR/theme-switcher.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$THEME_STATE_DIR"

# Logging functions
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

info() {
  echo -e "${GREEN}INFO:${NC} $*"
  log "INFO: $*"
}

warn() {
  echo -e "${YELLOW}WARN:${NC} $*"
  log "WARN: $*"
}

error() {
  echo -e "${RED}ERROR:${NC} $*"
  log "ERROR: $*"
}

# Detect current system theme
detect_system_theme() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # # Using dark-mode-notify, if var DARKMODE is set, and 1 or 0
    # if [[ -n "$DARKMODE" ]]; then
    #   if [[ "$DARKMODE" == "1" ]]; then
    #     echo "dark"
    #     return
    #   elif [[ "$DARKMODE" == "0" ]]; then
    #     echo "light"
    #     return
    #   fi
    # fi

    # macOS theme detection
    local interface_style=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
    if [[ "$interface_style" == "Dark" ]]; then
      echo "dark"
    else
      echo "light"
    fi
  elif [[ "$(uname -s)" == "Linux" ]]; then
    # Linux theme detection via various methods
    # Try dbus/gsettings first (GNOME/GTK)
    if command -v gsettings &> /dev/null; then
      local color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "")
      if [[ "$color_scheme" == *"dark"* ]]; then
        echo "dark"
        return
      elif [[ "$color_scheme" == *"light"* ]]; then
        echo "light"
        return
      fi
    fi

    # Get the last saved theme
    local last_theme=$(get_saved_theme)
    echo "$last_theme"

  else
    # Unknown OS, default to dark
    warn "Unknown OS, defaulting to dark theme"
    echo "dark"
  fi
}

# Get saved theme
get_saved_theme() {
  if [[ -f "$THEME_STATE_FILE" ]]; then
    cat "$THEME_STATE_FILE"
  else
    echo ""
  fi
}

# Save current theme
save_theme() {
  local theme="$1"
  echo "$theme" > "$THEME_STATE_FILE"
  log "Theme saved: $theme"
}

# Apply theme to kitty (all running instances)
apply_kitty_theme() {
  local theme="$1"

  if ! command -v kitty &> /dev/null; then
    error "kitty not found"
    return
  fi

  info "Applying $theme theme to kitty..."

  local conf_path=$(mktemp)
  if [ "$theme" == "light" ]; then
     cat ~/.config/kitty/kitty.conf | sed -e "s/Mocha/Latte/g" > "$conf_path"
  else
     cat ~/.config/kitty/kitty.conf > "$conf_path"
  fi

  # Kitty supports live theme reloading via remote control
  # The theme files are managed by home-manager and catppuccin/nix
  # We just need to reload the config
  for socket in /tmp/kitty-*; do
    if [[ -S "$socket" ]]; then
      kitty @ --to "unix:$socket" load-config "$conf_path" || true
    fi
  done

  rm $conf_path 2>/dev/null || true

  log "Kitty theme applied"
}

# Apply theme to lazygit (on restart)
apply_lazygit_theme() {
  local theme="$1"

  if ! command -v lazygit &> /dev/null; then
    error "lazygit not found"
    return
  fi

  info "Applying $theme theme to lazygit..."

  if [ "$theme" == "light" ]; then
    rm -f ~/.config/lazygit/theme.yml || true
    ln -s ~/.config/lazygit/theme.light.yml ~/.config/lazygit/theme.yml
  else
    rm -f ~/.config/lazygit/theme.yml
    ln -s ~/.config/lazygit/theme.dark.yml ~/.config/lazygit/theme.yml
  fi

  log "Lazygit theme applied"
}

# Apply theme to tmux (all running sessions)
apply_tmux_theme() {
  local theme="$1"

  if ! command -v tmux &> /dev/null; then
    error "tmux not found"
    return
  fi

  # Check if tmux is running
  if ! tmux list-sessions &> /dev/null; then
    log "tmux not running"
    return
  fi

  local plugin_location=$(cat ~/.config/tmux/tmux.conf | sed -rn 's/^run-shell (.*catppuccin.*)$/\1/p')
  # ../
  plugin_location=$(dirname "$plugin_location")

  info "Applying $theme theme to tmux..."

  local conf_path=$(mktemp)

  # Fix hot reloading of tmux catppuccin theme: https://github.com/catppuccin/tmux/issues/426
  cat <<EOF > "$conf_path"
run "rg -Io 'set.*@(\\\\w+)\\\\s' -r '@\$1' $plugin_location | uniq | xargs -n1 -P0 tmux set -Ugq"
EOF

  if [ "$theme" == "light" ]; then
    cat ~/.config/tmux/tmux.conf | sed -e "s/mocha/latte/g" >> "$conf_path"
  else
    cat ~/.config/tmux/tmux.conf >> "$conf_path"
  fi

  tmux source "$conf_path" 2>/dev/null || true

  rm $conf_path 2>/dev/null || true

  log "Tmux theme applied"
}

# Apply theme to neovim (signal running instances)
apply_nvim_theme() {
  local theme="$1"

  info "Signaling neovim instances about theme change..."

  # Neovim instances will pick up the theme on next start
  # For running instances, we can use remote control if nvim-remote is available
  if command -v nvr &> /dev/null; then
    # Find all nvim instances and send theme change command
    for server in /tmp/nvim_*; do
      if [[ -S "$server" ]]; then
        (if [[ "$theme" == "light" ]]; then
          nvr --servername "$server" -c "colorscheme catppuccin-latte" 2>/dev/null || true
        else
          nvr --servername "$server" -c "colorscheme catppuccin-mocha" 2>/dev/null || true
        fi)&
      fi
    done

    log "Neovim theme change signaled"
  else
    error "nvr not found"
  fi
}

# Available targets dispatch table
# Format: "name:function_name"
# To add a new target, just add an entry here and define the function above
TARGETS=(
  "kitty:apply_kitty_theme"
  "tmux:apply_tmux_theme"
  "lazygit:apply_lazygit_theme"
  "nvim:apply_nvim_theme"
)

# Get all available target names
get_available_targets() {
  local names=()
  for entry in "${TARGETS[@]}"; do
    names+=("${entry%%:*}")
  done
  echo "${names[*]}"
}

# Apply theme to a specific target
apply_theme_to_target() {
  local target="$1"
  local theme="$2"

  for entry in "${TARGETS[@]}"; do
    local name="${entry%%:*}"
    local func="${entry##*:}"
    if [[ "$name" == "$target" ]]; then
      $func "$theme" &
      return 0
    fi
  done

  error "Unknown target: $target (available: $(get_available_targets))"
  return 1
}

# Main theme switching function
switch_theme() {
  local new_theme="$1"
  local targets="${2:-all}"
  local saved_theme=$(get_saved_theme)

  info "Switching theme from '${saved_theme:-none}' to '$new_theme'"

  if [[ "$targets" == "all" ]]; then
    # Apply theme to all applications
    for entry in "${TARGETS[@]}"; do
      local func="${entry##*:}"
      $func "$new_theme" &
    done
  else
    # Apply to specific targets (comma-separated)
    IFS=',' read -ra target_list <<< "$targets"
    for target in "${target_list[@]}"; do
      target=$(echo "$target" | tr -d ' ')  # trim whitespace
      apply_theme_to_target "$target" "$new_theme"
    done
  fi

  wait

  # Save the new theme
  save_theme "$new_theme"

  info "Theme switch to $new_theme completed successfully"
}

# Show usage information
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [THEME]

Arguments:
  THEME                     Theme to apply: 'light', 'dark', or 'auto' (default: auto)

Options:
  -t, --target TARGETS      Comma-separated list of targets to update (default: all)
                            Available: $(get_available_targets)
  -h, --help                Show this help message

Examples:
  $(basename "$0") dark                    # Apply dark theme to all targets
  $(basename "$0") -t tmux light           # Apply light theme to tmux only
  $(basename "$0") --target tmux,nvim      # Apply auto theme to tmux and nvim
EOF
}

# Main execution
main() {
  local theme="auto"
  local targets="all"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--target)
        if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
          targets="$2"
          shift 2
        else
          error "Option $1 requires an argument"
          exit 1
        fi
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        theme="$1"
        shift
        ;;
    esac
  done

  # Validate theme
  if [[ "$theme" == "auto" ]]; then
    theme=$(detect_system_theme)
    info "Auto-detected system theme: $theme"
  elif [[ "$theme" != "light" && "$theme" != "dark" ]]; then
    error "Invalid theme: $theme (must be 'light', 'dark', or 'auto')"
    exit 1
  fi

  switch_theme "$theme" "$targets"
}

# Run main function
main "$@"
