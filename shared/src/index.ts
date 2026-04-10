export interface ConfigResponse {
  providers: string[]
  defaults: {
    provider: string
    model: string
  } | null
}

export interface ChatRequest {
  messages: ChatMessage[]
  provider: string
  model: string
}

export interface ChatMessage {
  role: 'user' | 'assistant'
  content: string
}

export interface StreamChunk {
  type: 'text_delta' | 'error' | 'done'
  content?: string
  error?: string
}

export interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: number
}