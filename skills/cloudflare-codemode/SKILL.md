---
name: cloudflare-codemode
description: Reference for @cloudflare/codemode - lets LLMs write and execute code instead of making tool calls. Runs in isolated Cloudflare Workers sandboxes. Use when building AI applications that need code execution capabilities.
---

# Cloudflare Code Mode

`@cloudflare/codemode` lets LLMs write executable code that orchestrates multiple tools, instead of calling tools one at a time. Code runs in secure, isolated Cloudflare Workers sandboxes.

## Why Code Mode?

LLMs are better at writing code than calling tools — they've seen millions of lines of real-world TypeScript but only contrived tool-calling examples.

**Traditional tool calling:**
```
Tool: getWeather(london) → 72°F sunny
Tool: sendEmail(team@example.com, "Nice day!", ...)
```

**Code Mode:**
```javascript
async () => {
  const weather = await codemode.getWeather({ location: "London" });
  if (weather.includes("sunny")) {
    await codemode.sendEmail({
      to: "team@example.com",
      subject: "Nice day!",
      body: `It's ${weather}`
    });
  }
  return { weather, notified: true };
}
```

## Installation

```bash
npm install @cloudflare/codemode agents ai zod
```

## Quick Start

```typescript
import { createCodeTool } from "@cloudflare/codemode/ai";
import { DynamicWorkerExecutor } from "@cloudflare/codemode";
import { streamText, tool } from "ai";
import { z } from "zod";

// 1. Define tools with AI SDK
const tools = {
  getWeather: tool({
    description: "Get weather for a location",
    inputSchema: z.object({ location: z.string() }),
    execute: async ({ location }) => `Weather in ${location}: 72°F, sunny`
  }),
  sendEmail: tool({
    description: "Send an email",
    inputSchema: z.object({
      to: z.string(),
      subject: z.string(),
      body: z.string()
    }),
    execute: async ({ to, subject, body }) => `Email sent to ${to}`
  })
};

// 2. Create an executor (runs in isolated Worker)
const executor = new DynamicWorkerExecutor({
  loader: env.LOADER
});

// 3. Create the codemode tool
const codemode = createCodeTool({ tools, executor });

// 4. Use with streamText
const result = streamText({
  model,
  system: "You are a helpful assistant.",
  messages,
  tools: { codemode }
});
```

## Wrangler Configuration

```jsonc
// wrangler.jsonc
{
  "worker_loaders": [{ "binding": "LOADER" }],
  "compatibility_flags": ["nodejs_compat"]
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Host Worker                                                 │
│  - createCodeTool generates TypeScript types from tools     │
│  - LLM writes async arrow function                          │
│  - ToolDispatcher holds the actual tool functions           │
└──────────────┬──────────────────────────────────────────────┘
               │ Workers RPC
               ▼
┌─────────────────────────────────────────────────────────────┐
│  Dynamic Worker (isolated sandbox)                          │
│  - LLM-generated code runs here                             │
│  - codemode.myTool() → dispatcher.call() via RPC            │
│  - fetch() blocked by default                               │
│  - Console output captured                                  │
└─────────────────────────────────────────────────────────────┘
```

## Security

- **Network isolation**: External fetch() and connect() are blocked by default
- **Enforced at Workers runtime level** via `globalOutbound: null`
- **Sandboxed code can only call tools** via codemode.* calls

To allow controlled outbound:
```typescript
const executor = new DynamicWorkerExecutor({
  loader: env.LOADER,
  globalOutbound: env.MY_OUTBOUND_SERVICE // route through a Fetcher
});
```

## With MCP Tools

```typescript
const codemode = createCodeTool({
  tools: {
    ...myTools,
    ...this.mcp.getAITools()  // MCP tools work seamlessly
  },
  executor
});
```

## Executor Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `loader` | WorkerLoader | required | Worker Loader binding |
| `timeout` | number | 30000 | Execution timeout (ms) |
| `globalOutbound` | Fetcher \| null | null | Network access control |

## Limitations

- **needsApproval not supported yet** — approval-required tools execute immediately
- Requires Cloudflare Workers environment
- JavaScript execution only

## Integration with arsa-molt-fun

To add Code Mode to this Worker:

1. Add to wrangler.jsonc:
   ```jsonc
   "worker_loaders": [{ "binding": "LOADER" }]
   ```

2. Install package:
   ```bash
   npm install @cloudflare/codemode
   ```

3. Create executor in worker code and pass to OpenClaw

## References

- Package: https://www.npmjs.com/package/@cloudflare/codemode
- GitHub: https://github.com/cloudflare/agents/tree/main/packages/codemode
- Examples: https://github.com/cloudflare/agents/tree/main/examples/codemode
