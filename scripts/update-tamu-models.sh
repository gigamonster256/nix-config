#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/../modules/dev/opencode/tamu-models.json"

usage() {
  echo "Usage: update-tamu-models [api-key]"
  echo ""
  echo "Fetches available models from TAMU AI API and updates tamu-models.json"
  echo ""
  echo "The API key can be provided as an argument or via TAMU_AI_KEY env var"
}

# check for -h or --help
for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    usage
    exit 0
  fi
done

# Get API key from argument or env var
API_KEY="${1:-$TAMU_AI_KEY}"

if [ -z "$API_KEY" ]; then
  echo "Error: API key not provided."
  echo "Pass it as an argument or set TAMU_AI_KEY environment variable."
  usage
  exit 1
fi

echo "Fetching models from TAMU AI API..."

MODELS_JSON=$(curl -s -X 'GET' \
  'https://chat-api.tamu.ai/openai/models' \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $API_KEY" \
  | jq '.data | map({key: .id, value: {name: .name}}) | from_entries')

if [ -z "$MODELS_JSON" ] || [ "$MODELS_JSON" = "null" ]; then
  echo "Error: Failed to fetch models or received empty response."
  exit 1
fi

echo "$MODELS_JSON" | jq '.' > "$OUTPUT_FILE"

echo "Updated $OUTPUT_FILE with $(echo "$MODELS_JSON" | jq 'length') models."
