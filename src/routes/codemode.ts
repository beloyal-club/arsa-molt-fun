import { Hono } from 'hono';
import type { AppEnv } from '../types';
import { createCodemodeExecutor } from '../codemode/executor';

/**
 * Codemode API routes - Sandboxed code execution
 *
 * These routes allow executing LLM-generated code in an isolated Worker environment.
 * The sandbox has no direct network access - all capabilities are provided through
 * explicitly defined tools.
 */
const codemode = new Hono<AppEnv>();

// POST /api/codemode/execute - Execute code in sandbox
codemode.post('/execute', async (c) => {
  const body = await c.req.json<{ code?: string }>();
  const { code } = body;

  if (!code) {
    return c.json({ error: 'code is required' }, 400);
  }

  try {
    const { executor, tools, createCodeTool } = createCodemodeExecutor(c.env);
    const codeTool = createCodeTool({ tools, executor });

    // Execute the code in the sandbox
    // The execute function is always defined for tools created by createCodeTool
    if (!codeTool.execute) {
      return c.json({ success: false, error: 'Tool execute function not available' }, 500);
    }
    const result = await codeTool.execute({ code }, {});
    return c.json({ success: true, result });
  } catch (e) {
    const error = e instanceof Error ? e.message : 'Unknown error';
    console.error('[CODEMODE] Execution failed:', error);
    return c.json({ success: false, error }, 500);
  }
});

// GET /api/codemode/status - Check if Codemode is enabled
codemode.get('/status', (c) => {
  const hasLoader = !!c.env.LOADER;
  return c.json({
    enabled: hasLoader,
    message: hasLoader ? 'Codemode ready' : 'LOADER binding not configured',
  });
});

export { codemode };
