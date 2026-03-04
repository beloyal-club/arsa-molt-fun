#!/bin/bash
# Generate code with project context using OpenAI API
# Usage: codex-project.sh "task description" --dir ./project [--output out.ts] [--model gpt-4o]

set -e

TASK="$1"
shift

# Parse arguments
DIR=""
OUTPUT=""
MODEL="gpt-5.3"
MAX_FILES=20
MAX_CHARS=50000

while [[ $# -gt 0 ]]; do
  case $1 in
    --dir)
      DIR="$2"
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
    *)
      shift
      ;;
  esac
done

if [[ -z "$TASK" || -z "$DIR" ]]; then
  echo "Usage: codex-project.sh \"task\" --dir ./project [--output file] [--model model]"
  exit 1
fi

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "Error: OPENAI_API_KEY not set"
  exit 1
fi

# Build project context from directory
PROJECT_CONTEXT=""
FILE_COUNT=0
TOTAL_CHARS=0

echo "📂 Scanning $DIR..." >&2

while IFS= read -r -d '' file; do
  if [[ $FILE_COUNT -ge $MAX_FILES ]]; then
    echo "⚠️  Truncated at $MAX_FILES files" >&2
    break
  fi
  
  CONTENT=$(cat "$file" 2>/dev/null || true)
  CHARS=${#CONTENT}
  
  if [[ $((TOTAL_CHARS + CHARS)) -gt $MAX_CHARS ]]; then
    echo "⚠️  Truncated at $MAX_CHARS chars" >&2
    break
  fi
  
  REL_PATH="${file#$DIR/}"
  PROJECT_CONTEXT+="
=== $REL_PATH ===
$CONTENT
"
  TOTAL_CHARS=$((TOTAL_CHARS + CHARS))
  FILE_COUNT=$((FILE_COUNT + 1))
done < <(find "$DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.json" -o -name "*.md" \) ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" ! -path "*/__pycache__/*" -print0 2>/dev/null | head -z -n $MAX_FILES)

echo "📊 Loaded $FILE_COUNT files ($TOTAL_CHARS chars)" >&2

# Build prompt
USER_MSG="$TASK

Project files:
$PROJECT_CONTEXT"

SYSTEM_PROMPT="You are an expert programmer working on an existing codebase. Analyze the project structure and implement the requested changes. Output clean, production-ready code that fits the existing style."

USER_MSG_ESCAPED=$(echo "$USER_MSG" | jq -Rs .)
SYSTEM_ESCAPED=$(echo "$SYSTEM_PROMPT" | jq -Rs .)

echo "🚀 Calling OpenAI ($MODEL)..." >&2

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [
      {\"role\": \"system\", \"content\": $SYSTEM_ESCAPED},
      {\"role\": \"user\", \"content\": $USER_MSG_ESCAPED}
    ],
    \"temperature\": 0.2,
    \"max_tokens\": 4096
  }")

CODE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [[ -z "$CODE" ]]; then
  echo "Error: No response" >&2
  echo "$RESPONSE" | jq . >&2
  exit 1
fi

if [[ -n "$OUTPUT" ]]; then
  mkdir -p "$(dirname "$OUTPUT")"
  echo "$CODE" > "$OUTPUT"
  echo "✅ Written to $OUTPUT" >&2
else
  echo "$CODE"
fi
