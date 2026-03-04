---
name: openai-codex
description: Generate code using OpenAI Codex/GPT-4 via the Responses API. Use when spawning coding tasks to OpenAI models instead of Claude, or when user requests Codex specifically. Supports code generation, file editing, and multi-file projects.
---

# OpenAI Codex

Generate code via OpenAI's Responses API (Codex-style).

## Prerequisites

- `OPENAI_API_KEY` environment variable set

## Quick Start

For simple code generation:
```bash
./scripts/codex-generate.sh "Create a Python function that calculates fibonacci numbers"
```

For file-based tasks:
```bash
./scripts/codex-generate.sh "Refactor this code to use async/await" --file ./src/api.ts
```

## API Endpoint

The Responses API (`POST https://api.openai.com/v1/responses`) accepts:

```json
{
  "model": "gpt-4o",
  "input": "Your coding task description",
  "instructions": "You are an expert programmer...",
  "tools": [
    {"type": "code_interpreter"},
    {"type": "file_search"}
  ]
}
```

## Usage Patterns

### 1. Simple Code Generation
```bash
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "system", "content": "You are an expert programmer. Output only code, no explanations."},
      {"role": "user", "content": "Create a React component that..."}
    ]
  }' | jq -r '.choices[0].message.content'
```

### 2. Code Review/Refactor
Pass existing code as context:
```bash
CODE=$(cat ./src/component.tsx)
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"gpt-4o\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You are an expert code reviewer.\"},
      {\"role\": \"user\", \"content\": \"Review and improve this code:\\n\\n$CODE\"}
    ]
  }"
```

### 3. Multi-File Projects
Use the helper script with directory context:
```bash
./scripts/codex-project.sh "Add authentication to this Express app" --dir ./backend
```

## Best Practices

1. **Be specific** - Include language, framework, and style preferences
2. **Provide context** - Pass relevant existing code for consistency
3. **Request format** - Ask for specific output format (JSON, TypeScript, etc.)
4. **Iterate** - Use follow-up requests to refine output

## Models

| Model | Best For |
|-------|----------|
| `gpt-5.3` | Default - complex multi-file tasks, architecture |
| `gpt-4o` | Fallback for simpler tasks |
| `o1` | Algorithmic problems, optimization |
| `o3-mini` | Fast reasoning tasks |

## Integration with Sub-Agents

To spawn a Codex-based coding task from the main agent:

```bash
# Generate code and save to file
./scripts/codex-generate.sh "Create a REST API endpoint for user registration" \
  --output ./src/routes/register.ts \
  --model gpt-4o
```

The script handles:
- API authentication
- Response parsing
- File writing
- Error handling
