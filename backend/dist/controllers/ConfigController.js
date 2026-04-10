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
// GET /api/providers - List all providers with details
configRouter.get('/providers', async (c) => {
    try {
        const envProviders = configService.detectEnvProviders();
        const customProviders = await configService.getCustomProviders();
        const allProviders = [
            ...envProviders.map(p => ({ id: p, type: 'env' })),
            ...customProviders.map(p => ({ id: `custom/${p.name}`, type: 'custom', ...p }))
        ];
        return c.json({ env: envProviders, custom: customProviders, all: allProviders });
    }
    catch (error) {
        console.error('[ConfigController] Error listing providers:', error);
        return c.json({ error: 'Failed to list providers' }, 500);
    }
});
// POST /api/providers - Add custom provider
configRouter.post('/providers', async (c) => {
    try {
        const body = await c.req.json();
        if (!body.name || !body.apiKey) {
            return c.json({ error: 'Name and API key required' }, 400);
        }
        const providers = await configService.addCustomProvider({
            name: body.name,
            apiKey: body.apiKey,
            baseUrl: body.baseUrl
        });
        return c.json({ success: true, providers });
    }
    catch (error) {
        console.error('[ConfigController] Error adding provider:', error);
        return c.json({ error: 'Failed to add provider' }, 500);
    }
});
// DELETE /api/providers/:name - Remove custom provider
configRouter.delete('/providers/:name', async (c) => {
    try {
        const name = c.req.param('name');
        const providers = await configService.removeCustomProvider(decodeURIComponent(name));
        return c.json({ success: true, providers });
    }
    catch (error) {
        console.error('[ConfigController] Error removing provider:', error);
        return c.json({ error: 'Failed to remove provider' }, 500);
    }
});
// POST /api/providers/test - Test provider connection
configRouter.post('/providers/test', async (c) => {
    try {
        const body = await c.req.json();
        if (!body.provider) {
            return c.json({ error: 'Provider required' }, 400);
        }
        const result = await configService.testProvider(body.provider, body.apiKey);
        return c.json(result);
    }
    catch (error) {
        console.error('[ConfigController] Error testing provider:', error);
        return c.json({ success: false, error: 'Test failed' }, 500);
    }
});
export { configRouter };
