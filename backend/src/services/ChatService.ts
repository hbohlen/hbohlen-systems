import { stream as piStream } from '@mariozechner/pi-ai'
import type { Model, Api, UserMessage, TextContent } from '@mariozechner/pi-ai'
import { configService } from './ConfigService.js'

interface ChatMessage {
  role: 'user' | 'assistant'
  content: string
}

interface StreamChunk {
  type: 'text_delta' | 'error' | 'done'
  content?: string
  error?: string
}

class ChatService {
  async *streamChat(
    messages: ChatMessage[],
    provider: string,
    model: string
  ): AsyncGenerator<StreamChunk> {
    // Validate provider exists
    const isConfigured = await configService.isProviderConfigured(provider)
    if (!isConfigured) {
      throw new Error(`Provider "${provider}" is not configured. Please authenticate via pi CLI`)
    }

    // Get API key
    const apiKey = await configService.getApiKey(provider)
    if (!apiKey) {
      throw new Error(`No API key found for provider "${provider}"`)
    }

    try {
      console.log(`[ChatService] Starting stream for ${provider}/${model}`)

      // Build messages for pi-ai SDK - only user messages are valid input
      const formattedMessages: UserMessage[] = messages
        .filter(m => m.role === 'user')
        .map(m => ({
          role: 'user',
          content: [{ type: 'text', text: m.content } as TextContent],
          timestamp: Date.now()
        }))

      // Create a simple model object for the SDK
      const modelObj: Model<Api> = {
        id: model,
        name: model,
        api: 'openai-completions', // Default API type
        provider: provider as 'openai' | 'anthropic' | 'google' | 'github-copilot' | 'groq' | 'ollama',
        baseUrl: '',
        reasoning: false,
        input: ['text'],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 8192,
        maxTokens: 4096
      }

      // Call pi-ai SDK
      const stream = piStream(
        modelObj,
        { messages: formattedMessages },
        { apiKey }
      )

      // Yield chunks from the stream
      for await (const event of stream) {
        if (event.type === 'text_delta' && event.delta) {
          yield {
            type: 'text_delta',
            content: event.delta
          }
        } else if (event.type === 'error') {
          const errorMessage = event.error?.errorMessage || 'Unknown stream error'
          yield {
            type: 'error',
            error: errorMessage
          }
          return
        } else if (event.type === 'done') {
          yield {
            type: 'done'
          }
          return
        }
      }

      // If stream ends without explicit done event
      yield { type: 'done' }
    } catch (error) {
      console.error(`[ChatService] Stream error:`, error)
      throw error
    }
  }

  async validateProvider(provider: string): Promise<boolean> {
    return configService.isProviderConfigured(provider)
  }
}

// Export singleton instance
export const chatService = new ChatService()

// Export types
export type { ChatMessage, StreamChunk }
