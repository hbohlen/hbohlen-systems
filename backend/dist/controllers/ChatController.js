import { Hono } from 'hono';
import { stream } from 'hono/streaming';
import { chatService } from '../services/ChatService.js';
const chatRouter = new Hono();
chatRouter.post('/chat', async (c) => {
    const startTime = Date.now();
    try {
        // Parse and validate request body
        const body = await c.req.json();
        if (!body.messages || !Array.isArray(body.messages) || body.messages.length === 0) {
            console.warn(`[ChatController] Invalid request: missing or empty messages array`);
            return c.json({
                error: 'Bad Request',
                details: 'messages array is required and must not be empty'
            }, 400);
        }
        if (!body.provider || typeof body.provider !== 'string') {
            console.warn(`[ChatController] Invalid request: missing or invalid provider`);
            return c.json({
                error: 'Bad Request',
                details: 'provider is required and must be a string'
            }, 400);
        }
        if (!body.model || typeof body.model !== 'string') {
            console.warn(`[ChatController] Invalid request: missing or invalid model`);
            return c.json({
                error: 'Bad Request',
                details: 'model is required and must be a string'
            }, 400);
        }
        // Validate provider is configured
        const isValidProvider = await chatService.validateProvider(body.provider);
        if (!isValidProvider) {
            console.warn(`[ChatController] Unconfigured provider requested: ${body.provider}`);
            return c.json({
                error: 'Bad Request',
                details: `Provider "${body.provider}" is not configured. Please authenticate via pi CLI`
            }, 400);
        }
        console.log(`[ChatController] POST /chat - ${body.provider}/${body.model}, ${body.messages.length} messages`);
        // Return SSE stream
        return stream(c, async (sseStream) => {
            // Set SSE headers
            c.header('Content-Type', 'text/event-stream');
            c.header('Cache-Control', 'no-cache');
            c.header('Connection', 'keep-alive');
            try {
                const streamIterator = chatService.streamChat(body.messages, body.provider, body.model);
                for await (const chunk of streamIterator) {
                    // Format as SSE event
                    const eventData = JSON.stringify(chunk);
                    await sseStream.write(`data: ${eventData}\n\n`);
                    // If done or error, end the stream
                    if (chunk.type === 'done' || chunk.type === 'error') {
                        break;
                    }
                }
                const duration = Date.now() - startTime;
                console.log(`[ChatController] Stream completed in ${duration}ms`);
            }
            catch (error) {
                const errorMessage = error instanceof Error ? error.message : 'Unknown error';
                console.error(`[ChatController] Stream error: ${errorMessage}`);
                // Send error event to client
                const errorData = JSON.stringify({
                    type: 'error',
                    error: errorMessage
                });
                await sseStream.write(`data: ${errorData}\n\n`);
            }
        });
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        console.error(`[ChatController] Error processing request: ${errorMessage}`);
        return c.json({
            error: 'Internal Server Error',
            details: errorMessage
        }, 500);
    }
});
export { chatRouter };
