#!/usr/bin/env bash
# Parse pi-session HTML exports to JSONL format
# Usage: ./parse-session-html.sh <input.html> [output.jsonl]

set -euo pipefail

# Check arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <input.html> [output.jsonl]" >&2
    echo "  Parses session HTML export to JSONL format" >&2
    echo "  If output.jsonl is not specified, writes to stdout" >&2
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-}"

# Check input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' not found" >&2
    exit 1
fi

# Extract base64 data from the script tag
# The data is in: <script id="session-data" type="application/json">BASE64_DATA</script>
# Use grep to find the line with session-data, then extract content between > and <
BASE64_DATA=$(grep 'id="session-data"' "$INPUT_FILE" | head -1 | \
    cut -d'>' -f2 | \
    cut -d'<' -f1 | \
    tr -d '\n' | \
    sed 's/^[[:space:]]*//')

if [[ -z "$BASE64_DATA" ]]; then
    echo "Error: Could not find session-data script tag in '$INPUT_FILE'" >&2
    exit 1
fi

# Decode base64 and parse JSON
JSON_DATA=$(echo "$BASE64_DATA" | base64 -d 2>/dev/null)

if [[ -z "$JSON_DATA" ]]; then
    echo "Error: Failed to decode base64 data" >&2
    exit 1
fi

# Check if jq is available for JSON parsing
if command -v jq &> /dev/null; then
    # Use jq to convert to JSONL
    # Output header first, then each entry on its own line
    if [[ -n "$OUTPUT_FILE" ]]; then
        # Write to file
        echo "$JSON_DATA" | jq -c '.header' > "$OUTPUT_FILE"
        echo "$JSON_DATA" | jq -c '.entries[]' >> "$OUTPUT_FILE"
    else
        # Write to stdout
        echo "$JSON_DATA" | jq -c '.header'
        echo "$JSON_DATA" | jq -c '.entries[]'
    fi
else
    # Fallback: use grep/sed to extract entries (less robust)
    echo "Warning: jq not found, using basic extraction (less reliable)" >&2
    
    # Extract header
    HEADER=$(echo "$JSON_DATA" | grep -o '"header":{[^}]*}' | sed 's/"header"://')
    
    # Extract entries array
    ENTRIES=$(echo "$JSON_DATA" | grep -o '"entries":\[.*\]' | sed 's/"entries":\[//' | sed 's/\]$//')
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$HEADER" > "$OUTPUT_FILE"
        # Split entries by },{
        echo "$ENTRIES" | sed 's/},{/}\n{/g' >> "$OUTPUT_FILE"
    else
        echo "$HEADER"
        echo "$ENTRIES" | sed 's/},{/}\n{/g'
    fi
fi

echo "Parsed session from '$INPUT_FILE'" >&2
