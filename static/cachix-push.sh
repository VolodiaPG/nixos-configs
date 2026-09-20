#!/usr/bin/env bash
# Shared cachix push logic.
#
# Consumers:
#   - modules/nixos/common-nix-settings.nix : nix post-build-hook, paths come in $OUT_PATHS
#   - .github/workflows/deploy.yaml         : cache job, paths come from the built closure
#
# Environment:
#   CACHIX_NAME       cache to push to                        (required)
#   OUT_PATHS         whitespace separated store paths, or -  (stdin when unset/empty)
#   IGNORE_PATTERNS   substrings; matching paths are skipped  (default below)
#   MAX_SIZE          max closure size in bytes               (default 500 MB)
#   CACHIX_TOKEN_FILE file holding a cachix auth token        (optional)
#
# `cachix`, `nix` and GNU `xargs` are expected to be on PATH.

set -uo pipefail

: "${CACHIX_NAME:?CACHIX_NAME must be set}"
IGNORE_PATTERNS="${IGNORE_PATTERNS-source etc system home-manager user-environment}"
# ponytail: closure-size via nix path-info — gates on total upload size
# (path + all deps) which is what cachix actually uploads.
MAX_SIZE="${MAX_SIZE:-$((500 * 1024 * 1024))}" # 500 MB

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
all="$work_dir/all"
candidates="$work_dir/candidates"
sizes="$work_dir/sizes"
filtered="$work_dir/filtered"

# Paths come from $OUT_PATHS (the post-build-hook convention) or, when that is
# empty, from stdin: a whole closure listing does not fit in an environment
# variable (execve caps a single string at 128 KB).
if [[ -n "${OUT_PATHS:-}" ]]; then
  tr -s '[:space:]' '\n' <<< "$OUT_PATHS"
else
  tr -s '[:space:]' '\n'
fi | grep -v '^$' | sort -u > "$all"

# Drop ignored patterns first, so the size query below only runs on survivors
read -ra pattern_array <<< "$IGNORE_PATTERNS"
: > "$candidates"
while IFS= read -r path; do
  should_ignore=false
  for pattern in ${pattern_array[@]+"${pattern_array[@]}"}; do
    if [[ -n "$pattern" && "$path" == *"$pattern"* ]]; then
      should_ignore=true
      break
    fi
  done

  if [[ "$should_ignore" == "false" ]]; then
    printf '%s\n' "$path" >> "$candidates"
  fi
done < "$all"

# One batched query — "<path>\t<closure size>" — instead of a daemon round-trip
# per path; xargs chunks it so the argument list cannot overflow either.
xargs -r -d '\n' -a "$candidates" nix path-info --closure-size 2>/dev/null > "$sizes"

declare -A closure_size=()
while read -r path size; do
  if [[ -n "$path" ]]; then
    closure_size["$path"]="$size"
  fi
done < "$sizes"

: > "$filtered"
while IFS= read -r path; do
  size="${closure_size[$path]:-}"
  if [[ -n "$size" && "$size" -gt "$MAX_SIZE" ]]; then
    echo "Skipping $path: $size bytes exceeds ${MAX_SIZE} bytes"
    continue
  fi
  printf '%s\n' "$path" >> "$filtered"
done < "$candidates"

if [[ ! -s "$filtered" ]]; then
  echo "Nothing to push to cachix"
  exit 0
fi

# Authenticate when a token file is provided (the CI runner is already authenticated)
if [[ -n "${CACHIX_TOKEN_FILE:-}" ]]; then
  cachix authtoken --stdin < "$CACHIX_TOKEN_FILE"
fi

echo "Pushing $(wc -l < "$filtered") paths to $CACHIX_NAME"
xargs -r -d '\n' -a "$filtered" cachix push "$CACHIX_NAME"
