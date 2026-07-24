#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$SCRIPT_DIR/../modules/dev/opencode"

PRO_URL="https://pro-chat-api.tamu.ai/openai/models"
BASE_URL="https://chat-api.tamu.ai/openai/models"

usage() {
  echo "Usage: update-tamu-models [options]"
  echo ""
  echo "Fetches available models from TAMU AI Pro and Base APIs and updates model files."
  echo ""
  echo "Options:"
  echo "  --pro-key KEY    API key for TAMU Pro Chat (or set TAMU_PRO_AI_KEY env var)"
  echo "  --base-key KEY   API key for TAMU Chat (or set TAMU_AI_KEY env var)"
  echo "  -h, --help       Show this help"
  echo ""
  echo "If only one key is provided, the other tier is skipped."
}

fetch_models() {
  local url="$1"
  local key="$2"
  if [ -z "$key" ]; then
    echo "Skipping $(basename "$url"): no API key provided."
    return 1
  fi
  curl -s -X 'GET' "$url" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $key" \
    | jq '.data | sort_by(.id) | map({key: .id, value: {name: .name}}) | from_entries'
}

PRO_KEY="${TAMU_PRO_AI_KEY:-}"
BASE_KEY="${TAMU_AI_KEY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pro-key)
      PRO_KEY="$2"; shift 2 ;;
    --base-key)
      BASE_KEY="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

FETCHED=0

echo "Fetching models from TAMU Pro Chat API..."
PRO_JSON=$(fetch_models "$PRO_URL" "$PRO_KEY") || true
if [ -n "$PRO_JSON" ] && [ "$PRO_JSON" != "null" ]; then
  echo "$PRO_JSON" | jq '.' > "$MODELS_DIR/tamu-models-pro.json"
  echo "Updated tamu-models-pro.json with $(echo "$PRO_JSON" | jq 'length') models."
  FETCHED=1
else
  echo "Error: Failed to fetch pro models or received empty response."
fi

echo "Fetching models from TAMU Chat API..."
BASE_JSON=$(fetch_models "$BASE_URL" "$BASE_KEY") || true
if [ -n "$BASE_JSON" ] && [ "$BASE_JSON" != "null" ]; then
  echo "$BASE_JSON" | jq '.' > "$MODELS_DIR/tamu-models-base.json"
  echo "Updated tamu-models-base.json with $(echo "$BASE_JSON" | jq 'length') models."
  FETCHED=1
else
  echo "Error: Failed to fetch base models or received empty response."
fi

if [ $FETCHED -eq 0 ]; then
  echo "Error: No models were fetched. Check your API keys."
  exit 1
fi
