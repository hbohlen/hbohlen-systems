import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import { serveStatic } from '@hono/node-server/serve-static';
import { cors } from 'hono/cors';
import { config } from './config.js';
import { healthRouter } from './routes/health.js';
import { configRouter } from './controllers/ConfigController.js';
import { chatRouter } from './controllers/ChatController.js';
const app = new Hono();
// CORS middleware
app.use('/api/*', cors({
    origin: '*',
    allowMethods: ['GET', 'POST'],
    allowHeaders: ['Content-Type']
}));
// Request logging middleware
app.use('/api/*', async (c, next) => {
    const start = Date.now();
    console.log(`${new Date().toISOString()} - ${c.req.method} ${c.req.path}`);
    await next();
    const duration = Date.now() - start;
    console.log(`${new Date().toISOString()} - ${c.req.method} ${c.req.path} - ${duration}ms`);
});
// API routes
app.route('/api', healthRouter);
app.route('/api', configRouter);
app.route('/api', chatRouter);
// Static files (SPA fallback) - serve from frontend dist
app.use('*', serveStatic({ root: '../frontend/dist' }));
app.use('*', serveStatic({ path: '../frontend/dist/index.html' }));
console.log(`Starting server on port ${config.port}...`);
serve({
    fetch: app.fetch,
    port: config.port,
});
console.log(`Server running at http://localhost:${config.port}`);
