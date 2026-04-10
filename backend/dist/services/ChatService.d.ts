interface ChatMessage {
    role: 'user' | 'assistant';
    content: string;
}
interface StreamChunk {
    type: 'text_delta' | 'error' | 'done';
    content?: string;
    error?: string;
}
declare class ChatService {
    streamChat(messages: ChatMessage[], provider: string, model: string): AsyncGenerator<StreamChunk>;
    validateProvider(provider: string): Promise<boolean>;
}
export declare const chatService: ChatService;
export type { ChatMessage, StreamChunk };
//# sourceMappingURL=ChatService.d.ts.map