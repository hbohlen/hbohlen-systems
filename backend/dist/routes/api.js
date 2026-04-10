import { Hono } from 'hono';
import { healthRouter } from './health.js';
import { configRouter } from '../controllers/ConfigController.js';
import { chatRouter } from '../controllers/ChatController.js';
const apiRouter = new Hono();
// Mount all API routes
apiRouter.route('/health', healthRouter);
apiRouter.route('/config', configRouter);
apiRouter.route('/chat', chatRouter);
export { apiRouter };
