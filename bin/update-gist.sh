#!/bin/bash

# Script to update GitHub Gist with file contents
# Usage: ./update-gist.sh <file_path>

set -euo pipefail

# Configuration
GIST_ID="275fc2348de45ea3ca32c75a4d831f22"
GIST_URL="https://api.github.com/gists/$GIST_ID"

# Check arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <file_path>"
    echo "Example: $0 ../pao-yaml-spec.md"
    exit 1
fi

FILE_PATH="$1"

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File '$FILE_PATH' does not exist"
    exit 1
fi

# Check if GitHub token is available
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set"
    echo "Please set your GitHub personal access token:"
    echo "export GITHUB_TOKEN=your_token_here"
    exit 1
fi

# Get filename from path
FILENAME=$(basename "$FILE_PATH")

# Read file content and escape for JSON
FILE_CONTENT=$(cat "$FILE_PATH" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "description": "PAO Specification - $FILENAME",
  "files": {
    "$FILENAME": {
      "content": "$FILE_CONTENT"
    }
  }
}
EOF
)

# Update the gist
echo "Updating gist $GIST_ID with contents of $FILE_PATH..."

RESPONSE=$(curl -s -X PATCH \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "$GIST_URL")

# Check if update was successful
if echo "$RESPONSE" | grep -q '"html_url"'; then
    HTML_URL=$(echo "$RESPONSE" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Gist updated successfully!"
    echo "📋 URL: $HTML_URL"
else
    echo "❌ Failed to update gist"
    echo "Response: $RESPONSE"
    exit 1
fi