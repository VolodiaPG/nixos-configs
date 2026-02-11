#!/usr/bin/env bash
# Generate a catppuccin theme variable for tmux session name based on hashing the session name
# Outputs tmux format variable like #{@thm_teal}

set -euo pipefail

# Catppuccin theme variable names (works with any flavor: latte, frappe, macchiato, mocha)
declare -a COLOR_VARS=(
  "#{@thm_rosewater}"
  # "#{@thm_flamingo}"
  "#{@thm_pink}"
  "#{@thm_mauve}"
  "#{@thm_red}"
  # "#{@thm_maroon}"
  "#{@thm_peach}"
  "#{@thm_yellow}"
  "#{@thm_green}"
  # "#{@thm_teal}"
  "#{@thm_sky}"
  # "#{@thm_sapphire}"
  "#{@thm_blue}"
  # "#{@thm_lavender}"
)

# Get session name from argument or stdin
SESSION_NAME="${1:-}"
if [[ -z "$SESSION_NAME" ]]; then
  echo "Usage: $0 <session_name>" >&2
  exit 1
fi

# Calculate hash of session name and map to color index
# Use sum of byte values modulo number of colors for deterministic but distributed result
hash_value=$(echo -n "$SESSION_NAME" | cksum | cut -d' ' -f1)
color_index=$((hash_value % ${#COLOR_VARS[@]}))

# Output the tmux format variable
echo "${COLOR_VARS[$color_index]}"
