---
name: cloudflare-mcp
description: Access Cloudflare services via MCP HTTP endpoints. Includes Workers, KV, R2, D1, Observability, Browser Rendering, Radar, and more. Requires CLOUDFLARE_API_TOKEN env var with appropriate permissions.
---

# Cloudflare MCP Server Integration

Access Cloudflare services via Model Context Protocol HTTP endpoints.

## Prerequisites

A `CLOUDFLARE_API_TOKEN` environment variable with permissions for the services you want to use:
- **Workers Scripts**: Edit permission for bindings/builds
- **Analytics**: Read for observability
- **Account Settings**: Read for AI Gateway
- **Zone Settings**: Read for DNS analytics

Create tokens at: https://dash.cloudflare.com/profile/api-tokens

## Available MCP Servers

| Server | URL | Description |
|--------|-----|-------------|
| Documentation | `https://docs.mcp.cloudflare.com/mcp` | Cloudflare reference docs |
| Workers Bindings | `https://bindings.mcp.cloudflare.com/mcp` | KV, R2, D1, AI, Queues |
| Workers Builds | `https://builds.mcp.cloudflare.com/mcp` | Build insights and management |
| Observability | `https://observability.mcp.cloudflare.com/mcp` | Logs and analytics |
| Radar | `https://radar.mcp.cloudflare.com/mcp` | Internet traffic insights |
| Containers | `https://containers.mcp.cloudflare.com/mcp` | Sandbox environments |
| Browser Rendering | `https://browser.mcp.cloudflare.com/mcp` | Web scraping, screenshots |
| AI Gateway | `https://ai-gateway.mcp.cloudflare.com/mcp` | Prompt/response logs |
| AutoRAG | `https://autorag.mcp.cloudflare.com/mcp` | RAG document search |
| Audit Logs | `https://auditlogs.mcp.cloudflare.com/mcp` | Account audit logs |
| DNS Analytics | `https://dns-analytics.mcp.cloudflare.com/mcp` | DNS performance |
| GraphQL | `https://graphql.mcp.cloudflare.com/mcp` | Cloudflare GraphQL API |

## HTTP Transport

MCP servers support streamable-http at `/mcp` endpoints. Use `scripts/mcp-call.sh` to make requests.

### Example: List KV Namespaces

```bash
./scripts/mcp-call.sh bindings list_kv_namespaces
```

### Example: Browser Screenshot

```bash
./scripts/mcp-call.sh browser fetch '{"url":"https://example.com","format":"screenshot"}'
```

## Authentication Flow

1. First request initializes the session (OAuth flow)
2. Subsequent requests use the session cookie
3. Token is passed via Authorization header

## Common Use Cases

### Workers Development
- List/create KV namespaces
- Read/write KV values
- Manage R2 buckets
- Query D1 databases

### Observability
- Query worker logs
- Analyze error rates
- Debug performance issues

### Browser Automation
- Take screenshots
- Convert pages to markdown
- Scrape content

### Internet Intelligence (Radar)
- Traffic trends
- URL scanning
- Threat intelligence

## Permissions Matrix

| Server | Required Permission |
|--------|---------------------|
| bindings | Workers Scripts: Edit |
| builds | Workers Scripts: Edit |
| observability | Analytics: Read |
| ai-gateway | Account Settings: Read |
| browser | Workers Scripts: Edit |
| radar | (public, no token needed) |
| containers | Workers Scripts: Edit |

## Troubleshooting

- **401 Unauthorized**: Check CLOUDFLARE_API_TOKEN permissions
- **Timeout**: MCP servers may have cold start delay (10-30s)
- **Rate limits**: Cloudflare API has rate limits per endpoint

## References

- GitHub: https://github.com/cloudflare/mcp-server-cloudflare
- MCP Protocol: https://modelcontextprotocol.io/
- Cloudflare API Tokens: https://dash.cloudflare.com/profile/api-tokens
