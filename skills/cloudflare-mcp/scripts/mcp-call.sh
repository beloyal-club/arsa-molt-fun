#!/bin/bash
# Call Cloudflare MCP servers via HTTP transport
# Usage: mcp-call.sh <server> <method> [params_json]
# Example: mcp-call.sh bindings list_kv_namespaces
# Example: mcp-call.sh browser fetch '{"url":"https://example.com"}'

set -e

SERVER="${1:-bindings}"
METHOD="${2:-}"
PARAMS="${3:-{}}"

if [ -z "$METHOD" ]; then
  echo "Usage: $0 <server> <method> [params_json]"
  echo ""
  echo "Servers: bindings, builds, observability, browser, radar, ai-gateway, containers, docs, graphql"
  echo ""
  echo "Example: $0 bindings list_kv_namespaces"
  exit 1
fi

# Server URL mapping
case "$SERVER" in
  bindings)    URL="https://bindings.mcp.cloudflare.com/mcp" ;;
  builds)      URL="https://builds.mcp.cloudflare.com/mcp" ;;
  observability) URL="https://observability.mcp.cloudflare.com/mcp" ;;
  browser)     URL="https://browser.mcp.cloudflare.com/mcp" ;;
  radar)       URL="https://radar.mcp.cloudflare.com/mcp" ;;
  ai-gateway)  URL="https://ai-gateway.mcp.cloudflare.com/mcp" ;;
  containers)  URL="https://containers.mcp.cloudflare.com/mcp" ;;
  docs)        URL="https://docs.mcp.cloudflare.com/mcp" ;;
  autorag)     URL="https://autorag.mcp.cloudflare.com/mcp" ;;
  auditlogs)   URL="https://auditlogs.mcp.cloudflare.com/mcp" ;;
  dns-analytics) URL="https://dns-analytics.mcp.cloudflare.com/mcp" ;;
  graphql)     URL="https://graphql.mcp.cloudflare.com/mcp" ;;
  *)
    echo "Unknown server: $SERVER"
    exit 1
    ;;
esac

# Check for API token
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "Error: CLOUDFLARE_API_TOKEN not set"
  echo "Create one at: https://dash.cloudflare.com/profile/api-tokens"
  exit 1
fi

# Build JSON-RPC request
REQUEST=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "$METHOD",
    "arguments": $PARAMS
  }
}
EOF
)

# Make the request
curl -s -X POST "$URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Accept: application/json" \
  -d "$REQUEST" | jq .
