import { useCallback, useState } from 'react'
import { useChatStore } from '../store/useChatStore'
import { MessageList } from './MessageList'
import { ChatInput } from './ChatInput'
import { ModelSelector } from './ModelSelector'
import { ErrorToast } from './ErrorToast'
import { streamChat, ApiError, ErrorCodes } from '../api/apiClient'
import { MessageSquare } from 'lucide-react'

export function ChatPage() {
  const [error, setError] = useState<Error | ApiError | null>(null)

  const {
    addMessage,
    appendToLastMessage,
    setStreaming,
    selectedProvider,
    selectedModel,
  } = useChatStore()

  const handleSendMessage = useCallback(
    async (content: string) => {
      if (!selectedProvider || !selectedModel) {
        console.error('No provider/model selected')
        setError(new Error('Please select a model before sending a message'))
        return
      }

      // Clear any previous errors
      setError(null)

      // Add user message immediately
      addMessage('user', content)

      // Add empty assistant message for streaming
      addMessage('assistant', '')

      // Set streaming state
      setStreaming(true)

      try {
        // Prepare messages for API (excluding the empty assistant message we just added)
        const currentMessages = useChatStore.getState().messages
        const messagesForApi = currentMessages
          .slice(0, -1) // Exclude the empty assistant message
          .filter((m) => m.role === 'user' || m.role === 'assistant')
          .map((m) => ({
            role: m.role,
            content: m.content,
          }))

        // Stream chat response using apiClient
        for await (const chunk of streamChat({
          messages: messagesForApi,
          provider: selectedProvider,
          model: selectedModel,
        })) {
          if (chunk.type === 'text_delta' && chunk.content) {
            appendToLastMessage(chunk.content)
          } else if (chunk.type === 'error') {
            console.error('Stream error:', chunk.error)
            const streamError = new ApiError(
              chunk.error || 'Stream error occurred',
              undefined,
              ErrorCodes.STREAM_ERROR
            )
            setError(streamError)
            appendToLastMessage(`\n\n[Error: ${chunk.error}]`)
            setStreaming(false)
            return
          } else if (chunk.type === 'done') {
            setStreaming(false)
            return
          }
        }

        // Stream completed normally
        setStreaming(false)
      } catch (err) {
        console.error('Chat error:', err)

        const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'

        // Set error for ErrorToast display
        setError(err instanceof ApiError ? err : new Error(errorMessage))

        // Append error to message
        appendToLastMessage(`\n\n[Error: ${errorMessage}]`)
        setStreaming(false)
      }
    },
    [addMessage, appendToLastMessage, setStreaming, selectedProvider, selectedModel]
  )

  const hasModelSelected = selectedProvider && selectedModel

  return (
    <div className="h-screen flex flex-col bg-background">
      {/* Header */}
      <header className="border-b border-border bg-card px-4 py-3">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <MessageSquare size={18} className="text-primary-foreground" />
            </div>
            <div>
              <h1 className="font-semibold text-lg">pi-web-ui</h1>
              <p className="text-xs text-muted-foreground">
                Chat with pi-authenticated LLMs
              </p>
            </div>
          </div>

          <ModelSelector disabled={useChatStore((state) => state.isStreaming)} />
        </div>
      </header>

      {/* Main content - Message list */}
      <main className="flex-1 overflow-hidden flex flex-col max-w-4xl mx-auto w-full">
        <MessageList />
      </main>

      {/* Footer - Input area */}
      <footer className="bg-card">
        <ChatInput
          onSendMessage={handleSendMessage}
          disabled={!hasModelSelected}
        />
        {!hasModelSelected && (
          <div className="text-center py-2 text-xs text-muted-foreground border-t border-border">
            Please select a model to start chatting
          </div>
        )}
      </footer>

      {/* Error Toast */}
      <ErrorToast error={error} onDismiss={() => setError(null)} />
    </div>
  )
}
