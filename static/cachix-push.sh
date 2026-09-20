#!/usr/bin/env bash
# Shared cachix push logic.
#
# Consumers:
#   - modules/nixos/common-nix-settings.nix : nix post-build-hook, paths come in $OUT_PATHS
#   - .github/workflows/deploy.yaml         : cache job, paths come from the built closure
#
# Environment:
#   CACHIX_NAME       cache to push to                        (required)
#   OUT_PATHS         whitespace separated store paths        (required)
#   IGNORE_PATTERNS   substrings; matching paths are skipped  (default below)
#   MAX_SIZE          max closure size in bytes               (default 500 MB)
#   CACHIX_TOKEN_FILE file holding a cachix auth token        (optional)
#
# `cachix` and `nix` are expected to be on PATH.

set -uo pipefail

: "${CACHIX_NAME:?CACHIX_NAME must be set}"
IGNORE_PATTERNS="${IGNORE_PATTERNS-source etc system home-manager user-environment}"
# ponytail: closure-size via nix path-info — one daemon round-trip per output,
# but gates on total upload size (path + all deps) which is what cachix actually uploads.
MAX_SIZE="${MAX_SIZE:-$((500 * 1024 * 1024))}" # 500 MB

# Filter out ignored patterns and oversized paths
FILTERED_PATHS=()
for path in ${OUT_PATHS:-}; do
  # Check if path should be ignored
  should_ignore=false
  if [[ -n "$IGNORE_PATTERNS" ]]; then
    IFS=' ' read -ra PATTERN_ARRAY <<< "$IGNORE_PATTERNS"
    for pattern in "${PATTERN_ARRAY[@]}"; do
      if [[ -n "$pattern" && "$path" == *"$pattern"* ]]; then
        should_ignore=true
        break
      fi
    done
  fi

  if [[ "$should_ignore" == "false" ]]; then
    size=$(nix path-info --closure-size "$path" 2>/dev/null | cut -f2)
    if [[ -n "$size" && "$size" -gt "$MAX_SIZE" ]]; then
      echo "Skipping $path: $size bytes exceeds ${MAX_SIZE} bytes (500 MB)"
      should_ignore=true
    fi
  fi

  if [[ "$should_ignore" == "false" ]]; then
    FILTERED_PATHS+=("$path")
  fi
done

if [[ "${#FILTERED_PATHS[@]}" -eq 0 ]]; then
  echo "Nothing to push to cachix"
  exit 0
fi

# Authenticate when a token file is provided (the CI runner is already authenticated)
if [[ -n "${CACHIX_TOKEN_FILE:-}" ]]; then
  cachix authtoken --stdin < "$CACHIX_TOKEN_FILE"
fi

cachix push "$CACHIX_NAME" "${FILTERED_PATHS[@]}"
