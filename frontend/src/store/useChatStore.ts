import { create } from 'zustand'

export interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: number
}

export interface ChatState {
  // State
  messages: Message[]
  selectedProvider: string | null
  selectedModel: string | null
  isStreaming: boolean

  // Actions
  addMessage: (role: 'user' | 'assistant', content: string) => void
  appendToLastMessage: (chunk: string) => void
  setSelectedModel: (provider: string, model: string) => void
  setStreaming: (streaming: boolean) => void
  clearMessages: () => void
}

export const useChatStore = create<ChatState>((set) => ({
  // Initial state
  messages: [],
  selectedProvider: null,
  selectedModel: null,
  isStreaming: false,

  // Actions
  addMessage: (role, content) =>
    set((state) => ({
      messages: [
        ...state.messages,
        {
          id: generateMessageId(),
          role,
          content,
          timestamp: Date.now(),
        },
      ],
    })),

  appendToLastMessage: (chunk) =>
    set((state) => {
      if (state.messages.length === 0) return state

      const lastMessage = state.messages[state.messages.length - 1]
      if (lastMessage.role !== 'assistant') return state

      const updatedMessages = [...state.messages]
      updatedMessages[updatedMessages.length - 1] = {
        ...lastMessage,
        content: lastMessage.content + chunk,
      }

      return { messages: updatedMessages }
    }),

  setSelectedModel: (provider, model) =>
    set({
      selectedProvider: provider,
      selectedModel: model,
    }),

  setStreaming: (streaming) =>
    set({
      isStreaming: streaming,
    }),

  clearMessages: () =>
    set({
      messages: [],
      isStreaming: false,
    }),
}))

function generateMessageId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}
