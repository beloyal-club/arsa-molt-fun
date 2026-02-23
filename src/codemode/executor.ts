import { createCodeTool } from '@cloudflare/codemode/ai';
import { DynamicWorkerExecutor } from '@cloudflare/codemode';
import { tool } from 'ai';
import { z } from 'zod';
import type { MoltbotEnv } from '../types';

/**
 * Creates a Codemode executor with available tools for sandboxed code execution.
 * The executor runs LLM-generated code in an isolated Worker environment.
 */
export function createCodemodeExecutor(env: MoltbotEnv) {
  if (!env.LOADER) {
    throw new Error('LOADER binding not configured');
  }

  const executor = new DynamicWorkerExecutor({
    loader: env.LOADER as WorkerLoader,
    timeout: 30000,
  });

  // Define tools available in the sandbox
  const tools = {
    log: tool({
      description: 'Log a message to the console',
      inputSchema: z.object({ message: z.string() }),
      execute: async ({ message }: { message: string }) => {
        console.log('[codemode]', message);
        return `Logged: ${message}`;
      },
    }),
  };

  return { executor, tools, createCodeTool };
}
