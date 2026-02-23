import { Hono } from 'hono';
import type { AppEnv } from '../types';

/**
 * Internal secrets API routes - Localhost-only access
 *
 * These routes allow the container to fetch secrets from Cloudflare Secrets Store
 * at runtime without requiring a container restart.
 *
 * Security: Only accessible from localhost (within the container).
 */
const secrets = new Hono<AppEnv>();

// GET /api/internal/secrets/:name - Fetch a secret by name
secrets.get('/:name', async (c) => {
  const secretName = c.req.param('name');
  const env = c.env;

  // Verify request is from container (localhost only)
  // In Workers, requests from within the container don't have CF-Connecting-IP
  // or have it set to a local address
  const clientIP = c.req.header('CF-Connecting-IP');
  if (clientIP && clientIP !== '127.0.0.1' && clientIP !== '::1') {
    console.log(`[SECRETS] Forbidden: request from non-localhost IP: ${clientIP}`);
    return c.json({ error: 'Forbidden' }, 403);
  }

  // Check if SECRETS binding is configured
  if (!env.SECRETS) {
    console.log('[SECRETS] SECRETS binding not configured');
    return c.json({ error: 'Secrets Store not configured' }, 501);
  }

  try {
    const value = await env.SECRETS.get(secretName);
    if (value === null) {
      return c.json({ error: 'Secret not found' }, 404);
    }
    return c.json({ value });
  } catch (e) {
    console.error('[SECRETS] Failed to fetch secret:', e);
    return c.json({ error: 'Failed to fetch secret' }, 500);
  }
});

export { secrets };
