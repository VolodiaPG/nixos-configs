#!/usr/bin/env bash

if [[ -z "$OPENROUTER_API_KEY" ]]; then
  echo "Openrouter API key found, please put it in OPENROUTER_API_KEY environment variable" >&2
  exit 1
fi

CACHE_FILE="${TMPDIR:-/tmp}/openrouter-credits.cache"
NOW=$(date +%s)

# Default: refresh every 60 seconds
REFRESH_INTERVAL=60

# Read cache if it exists
if [[ -f "$CACHE_FILE" ]]; then
  read -r LAST_UPDATE LAST_CREDITS LAST_CHANGED < "$CACHE_FILE" 2>/dev/null || true

  # If credits changed recently, use shorter interval (10s)
  if [[ "$LAST_CHANGED" == "1" ]]; then
    REFRESH_INTERVAL=10
  fi

  # Calculate time since last update
  TIME_SINCE_UPDATE=$((NOW - LAST_UPDATE))

  # If not enough time passed, return cached value
  if [[ $TIME_SINCE_UPDATE -lt $REFRESH_INTERVAL ]]; then
    echo "$LAST_CREDITS"
    exit 0
  fi
fi

# Time to fetch fresh data
credits=$(curl -s -m 5 https://openrouter.ai/api/v1/credits -H "Authorization: Bearer $OPENROUTER_API_KEY" 2>/dev/null | jq '.data.total_credits - .data.total_usage' 2>/dev/null)

# Validate we got a number
if [[ -z "$credits" ]] || [[ "$credits" == "null" ]]; then
  # Return cached value if available, otherwise error
  if [[ -n "$LAST_CREDITS" ]]; then
    echo "$LAST_CREDITS"
    # Mark as not changed since we failed to get new data
    echo "$NOW $LAST_CREDITS 0" > "$CACHE_FILE"
    exit 0
  fi
  echo "Error fetching credits" >&2
  exit 1
fi

credits_formatted=$(printf "\$%.2f" "$credits")

# Detect if credits changed
CHANGED=0
if [[ -n "$LAST_CREDITS" ]] && [[ "$credits_formatted" != "$LAST_CREDITS" ]]; then
  CHANGED=1
fi

# Save to cache: timestamp credits changed_flag
echo "$NOW $credits_formatted $CHANGED" > "$CACHE_FILE"

echo "$credits_formatted"
