import { useEffect, useRef } from 'react'
import { useChatStore } from '../store/useChatStore'
import { MessageBubble } from './MessageBubble'

export function MessageList() {
  const { messages, isStreaming } = useChatStore()
  const scrollRef = useRef<HTMLDivElement>(null)
  const bottomRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom when new messages arrive or content updates
  useEffect(() => {
    if (bottomRef.current) {
      bottomRef.current.scrollIntoView({ behavior: 'smooth' })
    }
  }, [messages, isStreaming])

  if (messages.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="text-center text-muted-foreground">
          <p className="text-lg font-medium mb-2">Welcome to pi-web-ui</p>
          <p className="text-sm">
            Select a model and start chatting with your LLM provider.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div
      ref={scrollRef}
      className="flex-1 overflow-y-auto p-4 space-y-6"
    >
      {messages.map((message, index) => (
        <MessageBubble
          key={message.id}
          message={message}
          isStreaming={
            isStreaming &&
            index === messages.length - 1 &&
            message.role === 'assistant'
          }
        />
      ))}
      <div ref={bottomRef} />
    </div>
  )
}
