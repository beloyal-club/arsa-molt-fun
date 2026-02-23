import { Hono } from 'hono';
import type { AppEnv } from '../types';

/**
 * Internal secrets API routes - Localhost-only access
 *
 * Secrets Store bindings are one-per-secret (not dynamic lookup).
 * Each secret in wrangler.jsonc maps to env.<BINDING_NAME>.get()
 *
 * Security: Only accessible from localhost (within the container).
 */
const secrets = new Hono<AppEnv>();

// GET /api/internal/secrets/:name - Fetch a secret by binding name
secrets.get('/:name', async (c) => {
  const bindingName = c.req.param('name');
  const env = c.env;

  // Verify request is from container (localhost only)
  const clientIP = c.req.header('CF-Connecting-IP');
  if (clientIP && clientIP !== '127.0.0.1' && clientIP !== '::1') {
    console.log(`[SECRETS] Forbidden: request from non-localhost IP: ${clientIP}`);
    return c.json({ error: 'Forbidden' }, 403);
  }

  // Secrets Store bindings are accessed as env.<BINDING_NAME>.get()
  // Each binding must be declared in wrangler.jsonc
  const binding = (env as unknown as Record<string, { get?: () => Promise<string> }>)[bindingName];
  
  if (!binding || typeof binding.get !== 'function') {
    console.log(`[SECRETS] Binding '${bindingName}' not found or not a Secrets Store binding`);
    return c.json({ 
      error: 'Secret binding not found',
      hint: 'Add binding to wrangler.jsonc: secrets_store_secrets: [{ binding: "NAME", store_id: "...", secret_name: "..." }]'
    }, 404);
  }

  try {
    const value = await binding.get();
    return c.json({ value });
  } catch (e) {
    console.error('[SECRETS] Failed to fetch secret:', e);
    return c.json({ error: 'Failed to fetch secret' }, 500);
  }
});

// GET /api/internal/secrets - List available secret bindings
secrets.get('/', (c) => {
  // Return known bindings (add more as they're configured)
  const knownBindings = ['TEST_SECRET'];
  const available = knownBindings.filter(name => {
    const binding = (c.env as unknown as Record<string, unknown>)[name];
    return binding && typeof (binding as { get?: unknown }).get === 'function';
  });
  
  return c.json({ 
    bindings: available,
    note: 'Each secret requires a binding in wrangler.jsonc'
  });
});

export { secrets };
