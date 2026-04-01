import { Hono } from 'hono';
import { SDKSessionManager } from '../session-manager.js';

export function createApiRoutes(sessionManager: SDKSessionManager) {
  const api = new Hono();

  // Auth middleware
  api.use('*', async (c, next) => {
    const token = c.req.header('Authorization')?.replace('Bearer ', '');
    const expectedToken = process.env.OMP_WEB_TOKEN;
    
    if (expectedToken && token !== expectedToken) {
      return c.json({ error: 'Unauthorized' }, 401);
    }
    
    await next();
  });

  // List sessions
  api.get('/sessions', async (c) => {
    const sessions = await sessionManager.listSessions();
    return c.json({ sessions });
  });

  // Create new session
  api.post('/sessions', async (c) => {
    // Note: actual session creation happens on WebSocket connect
    // This just returns a new ID
    const id = crypto.randomUUID();
    return c.json({ id, status: 'created' });
  });

  // Get session details
  api.get('/sessions/:id', async (c) => {
    const id = c.req.param('id');
    const sessions = await sessionManager.listSessions();
    const session = sessions.find(s => s.id === id);
    
    if (!session) {
      return c.json({ error: 'Session not found' }, 404);
    }
    
    return c.json({ session });
  });

  // Fork session
  api.post('/sessions/:id/fork', async (c) => {
    const id = c.req.param('id');
    // Note: forking requires WebSocket context, handled via WS
    return c.json({ error: 'Use WebSocket to fork sessions' }, 400);
  });

  // Delete session
  api.delete('/sessions/:id', async (c) => {
    const id = c.req.param('id');
    const success = await sessionManager.deleteSession(id);
    
    if (!success) {
      return c.json({ error: 'Session not found' }, 404);
    }
    
    return c.json({ status: 'deleted' });
  });

  // Health check
  api.get('/health', (c) => {
    return c.json({ status: 'ok', timestamp: Date.now() });
  });

  return api;
}
