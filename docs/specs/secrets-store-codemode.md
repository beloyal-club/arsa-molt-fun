# Spec: Cloudflare Secrets Store + Codemode Integration

**Status:** Draft  
**Author:** Breth (orchestrator)  
**Date:** 2026-02-23  

## Goal

Enable runtime secret access without container restarts, and integrate Codemode for sandboxed code execution.

## Problem

Currently:
1. Secrets are Worker env vars, injected at container startup
2. Adding a new secret requires container restart
3. Code changes require direct file edits + deploy

## Solution

### Part 1: Secrets Store Integration

Use Cloudflare Secrets Store (beta) for runtime secret access.

#### 1.1 Create Secrets Store

```bash
npx wrangler secrets-store store create --remote
```

#### 1.2 Add Binding to wrangler.jsonc

```jsonc
{
  "secrets_store_secrets": [
    {
      "binding": "SECRETS",
      "store_id": "<STORE_ID>",
      "secret_name": "*"  // or specific names
    }
  ]
}
```

#### 1.3 Add Internal API Endpoint

New route in `src/routes/api.ts`:

```typescript
// GET /api/internal/secrets/:name
// Only accessible from within the container (localhost)
app.get('/api/internal/secrets/:name', async (c) => {
  const { name } = c.req.param();
  const env = c.env as MoltbotEnv;
  
  // Verify request is from container (localhost only)
  const clientIP = c.req.header('CF-Connecting-IP');
  if (clientIP && clientIP !== '127.0.0.1') {
    return c.json({ error: 'Forbidden' }, 403);
  }
  
  try {
    const value = await env.SECRETS.get(name);
    if (!value) {
      return c.json({ error: 'Secret not found' }, 404);
    }
    return c.json({ value });
  } catch (e) {
    return c.json({ error: 'Failed to fetch secret' }, 500);
  }
});
```

#### 1.4 Container-side Script

`/root/.openclaw/scripts/get-secret.sh`:

```bash
#!/bin/bash
SECRET_NAME="$1"
curl -s "http://localhost:8787/api/internal/secrets/${SECRET_NAME}" | jq -r '.value'
```

### Part 2: Codemode Integration

Enable sandboxed code execution for sub-agents.

#### 2.1 Install Dependencies

```bash
npm install @cloudflare/codemode agents ai zod
```

#### 2.2 Add Worker Loader Binding

In `wrangler.jsonc`:

```jsonc
{
  "worker_loaders": [{ "binding": "LOADER" }],
  "compatibility_flags": ["nodejs_compat"]
}
```

#### 2.3 Create Codemode Executor

New file `src/codemode/executor.ts`:

```typescript
import { createCodeTool } from "@cloudflare/codemode/ai";
import { DynamicWorkerExecutor } from "@cloudflare/codemode";
import { tool } from "ai";
import { z } from "zod";

export function createCodemodeExecutor(env: MoltbotEnv) {
  const executor = new DynamicWorkerExecutor({
    loader: env.LOADER,
    timeout: 30000,
  });

  // Define tools available in sandbox
  const tools = {
    fetchUrl: tool({
      description: "Fetch a URL and return the response",
      inputSchema: z.object({ url: z.string() }),
      execute: async ({ url }) => {
        const res = await fetch(url);
        return await res.text();
      }
    }),
    
    getSecret: tool({
      description: "Get a secret from Secrets Store",
      inputSchema: z.object({ name: z.string() }),
      execute: async ({ name }) => {
        const value = await env.SECRETS.get(name);
        return value || null;
      }
    }),
    
    // Add more tools as needed
  };

  return createCodeTool({ tools, executor });
}
```

#### 2.4 Add Codemode API Endpoint

New route in `src/routes/api.ts`:

```typescript
// POST /api/codemode/execute
// Executes code in sandboxed Worker
app.post('/api/codemode/execute', async (c) => {
  const { code } = await c.req.json();
  const env = c.env as MoltbotEnv;
  
  const codemode = createCodemodeExecutor(env);
  
  try {
    const result = await codemode.execute(code);
    return c.json({ success: true, result });
  } catch (e) {
    return c.json({ success: false, error: e.message }, 500);
  }
});
```

## Validation Criteria

- [ ] Can set a secret via Secrets Store API
- [ ] Can read secret at runtime without restart
- [ ] Can execute code in Codemode sandbox
- [ ] Sandbox cannot access external network (unless via tools)
- [ ] Sub-agents can use `/api/codemode/execute` endpoint

## Security Considerations

1. `/api/internal/secrets/*` must be localhost-only
2. Codemode sandbox has no direct network access
3. Only defined tools are callable from sandbox
4. Rate limiting on codemode endpoint

## Implementation Order

1. Set up Secrets Store (dashboard/wrangler)
2. Add secrets binding to wrangler.jsonc
3. Implement `/api/internal/secrets/:name`
4. Test secret retrieval
5. Add Codemode dependencies
6. Add worker_loaders binding
7. Implement executor + endpoint
8. Test sandboxed execution

## Open Questions

- [ ] What secrets should be migrated to Secrets Store?
- [ ] What tools should be available in Codemode sandbox?
- [ ] Should there be approval workflow for sandbox execution?
