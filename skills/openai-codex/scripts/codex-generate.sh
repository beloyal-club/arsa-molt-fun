#!/bin/bash
# Generate code using OpenAI API
# Usage: codex-generate.sh "task description" [--file input.ts] [--output out.ts] [--model gpt-4o]

set -e

TASK="$1"
shift

# Parse optional arguments
FILE=""
OUTPUT=""
MODEL="gpt-5.3"
SYSTEM_PROMPT="You are an expert programmer. Output only clean, production-ready code with minimal comments. No explanations or markdown formatting unless specifically requested."

while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      FILE="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --model)
      MODEL="$2"
      shift 2
      ;;
    --system)
      SYSTEM_PROMPT="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -z "$TASK" ]]; then
  echo "Usage: codex-generate.sh \"task description\" [--file input] [--output output] [--model model]"
  exit 1
fi

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "Error: OPENAI_API_KEY not set"
  exit 1
fi

# Build user message
USER_MSG="$TASK"
if [[ -n "$FILE" && -f "$FILE" ]]; then
  FILE_CONTENT=$(cat "$FILE")
  USER_MSG="$TASK

Here is the existing code:

\`\`\`
$FILE_CONTENT
\`\`\`"
fi

# Escape for JSON
USER_MSG_ESCAPED=$(echo "$USER_MSG" | jq -Rs .)
SYSTEM_ESCAPED=$(echo "$SYSTEM_PROMPT" | jq -Rs .)

# Call OpenAI API
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [
      {\"role\": \"system\", \"content\": $SYSTEM_ESCAPED},
      {\"role\": \"user\", \"content\": $USER_MSG_ESCAPED}
    ],
    \"temperature\": 0.2
  }")

# Extract code from response
CODE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [[ -z "$CODE" ]]; then
  echo "Error: No response from API"
  echo "$RESPONSE" | jq .
  exit 1
fi

# Strip markdown code blocks if present
CODE=$(echo "$CODE" | sed '/^```[a-z]*$/d' | sed '/^```$/d')

# Output
if [[ -n "$OUTPUT" ]]; then
  mkdir -p "$(dirname "$OUTPUT")"
  echo "$CODE" > "$OUTPUT"
  echo "✅ Written to $OUTPUT"
else
  echo "$CODE"
fi
