import { Hono } from 'hono';
import { configService } from '../services/ConfigService.js';
const configRouter = new Hono();
configRouter.get('/config', async (c) => {
    const startTime = performance.now();
    try {
        const providers = await configService.getProviders();
        const defaultProvider = await configService.getDefaultProvider();
        const response = {
            providers,
            defaults: defaultProvider ? {
                provider: defaultProvider.provider,
                model: defaultProvider.model
            } : null
        };
        const duration = Math.round(performance.now() - startTime);
        console.log(`[ConfigController] GET /config - ${providers.length} providers, ${duration}ms`);
        return c.json(response);
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        console.error(`[ConfigController] Error fetching config: ${errorMessage}`);
        return c.json({
            error: 'Failed to load configuration',
            details: errorMessage
        }, 500);
    }
});
export { configRouter };
