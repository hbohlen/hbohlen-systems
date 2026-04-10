import { useState, useRef, useCallback } from 'react'
import { Send } from 'lucide-react'
import { useChatStore } from '../store/useChatStore'

interface ChatInputProps {
  onSendMessage: (message: string) => void | Promise<void>
  disabled?: boolean
}

export function ChatInput({ onSendMessage, disabled }: ChatInputProps) {
  const [input, setInput] = useState('')
  const textareaRef = useRef<HTMLTextAreaElement>(null)
  const isStreaming = useChatStore((state) => state.isStreaming)

  const isDisabled = disabled || isStreaming || !input.trim()

  const handleSend = useCallback(async () => {
    const trimmedInput = input.trim()
    if (!trimmedInput || isStreaming) return

    // Clear input first for immediate feedback
    setInput('')

    // Call the send handler
    await onSendMessage(trimmedInput)

    // Refocus textarea
    textareaRef.current?.focus()
  }, [input, isStreaming, onSendMessage])

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault()
        if (!isDisabled) {
          handleSend()
        }
      }
    },
    [handleSend, isDisabled]
  )

  const handleInputChange = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      setInput(e.target.value)

      // Auto-resize textarea
      const textarea = e.target
      textarea.style.height = 'auto'
      textarea.style.height = `${Math.min(textarea.scrollHeight, 200)}px`
    },
    []
  )

  return (
    <div className="border-t border-border bg-card p-4">
      <div className="max-w-4xl mx-auto flex gap-3 items-end">
        <div className="flex-1 relative">
          <textarea
            ref={textareaRef}
            value={input}
            onChange={handleInputChange}
            onKeyDown={handleKeyDown}
            placeholder="Type your message... (Shift+Enter for newline)"
            disabled={disabled || isStreaming}
            rows={1}
            className="w-full resize-none bg-background border border-input rounded-lg px-4 py-3 pr-12 text-sm focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent disabled:opacity-50 disabled:cursor-not-allowed min-h-[48px] max-h-[200px]"
            style={{ height: 'auto' }}
          />
          <div className="absolute right-3 bottom-3 text-xs text-muted-foreground pointer-events-none">
            {input.length > 0 && (
              <span className="hidden sm:inline">Enter to send</span>
            )}
          </div>
        </div>

        <button
          onClick={handleSend}
          disabled={isDisabled}
          className="flex-shrink-0 bg-primary text-primary-foreground rounded-lg px-4 py-3 hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-primary transition-colors"
          aria-label="Send message"
        >
          <Send size={18} />
        </button>
      </div>
    </div>
  )
}
