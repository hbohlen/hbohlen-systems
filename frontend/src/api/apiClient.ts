// API Client for backend communication
// Provides fetch wrappers with error handling, logging, and base URL configuration

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || ''

interface ChatMessage {
  role: 'user' | 'assistant'
  content: string
}

interface ConfigResponse {
  providers: string[]
  defaults: {
    provider: string
    model: string
  } | null
}

interface ChatRequest {
  messages: ChatMessage[]
  provider: string
  model: string
}

interface StreamChunk {
  type: 'text_delta' | 'error' | 'done'
  content?: string
  error?: string
}

// Error codes for specific error types
export const ErrorCodes = {
  BACKEND_UNREACHABLE: 'BACKEND_UNREACHABLE',
  RATE_LIMIT: 'RATE_LIMIT',
  UNCONFIGURED_PROVIDER: 'UNCONFIGURED_PROVIDER',
  AUTHENTICATION_FAILED: 'AUTHENTICATION_FAILED',
  NETWORK_ERROR: 'NETWORK_ERROR',
  STREAM_ERROR: 'STREAM_ERROR',
  UNKNOWN: 'UNKNOWN',
} as const

type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes]

// Custom error class for API errors
export class ApiError extends Error {
  constructor(
    message: string,
    public statusCode?: number,
    public code?: ErrorCode
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

// Helper to construct full URL
function buildUrl(path: string): string {
  const base = API_BASE_URL.replace(/\/$/, '')
  const cleanPath = path.startsWith('/') ? path : `/${path}`
  return `${base}${cleanPath}`
}

// Helper to log requests in development
function logRequest(method: string, url: string, body?: unknown) {
  if (import.meta.env.DEV) {
    console.log(`[API] ${method} ${url}`, body ? { body } : '')
  }
}

// Helper to log responses in development
function logResponse(method: string, url: string, response: Response, data?: unknown) {
  if (import.meta.env.DEV) {
    console.log(`[API] ${method} ${url} - ${response.status}`, data ? { data } : '')
  }
}

// Helper to log errors in development
function logError(method: string, url: string, error: unknown) {
  console.error(`[API] ${method} ${url} - Error:`, error)
}

/**
 * Fetch configuration from the backend
 * Returns available providers and default selection
 */
export async function fetchConfig(): Promise<ConfigResponse> {
  const url = buildUrl('/api/config')
  const method = 'GET'

  try {
    logRequest(method, url)

    const response = await fetch(url, {
      method,
      headers: {
        Accept: 'application/json',
      },
    })

    if (!response.ok) {
      throw await handleErrorResponse(response)
    }

    const data: ConfigResponse = await response.json()
    logResponse(method, url, response, data)

    return data
  } catch (error) {
    logError(method, url, error)

    if (error instanceof ApiError) {
      throw error
    }

    if (error instanceof TypeError && error.message.includes('fetch')) {
      throw new ApiError(
        'Unable to connect to server. Please check that the backend is running.',
        undefined,
        ErrorCodes.BACKEND_UNREACHABLE
      )
    }

    throw new ApiError(
      'Failed to load configuration',
      undefined,
      ErrorCodes.UNKNOWN
    )
  }
}

/**
 * Send a chat message and receive a streaming response
 * Returns an async iterator that yields stream chunks
 */
export async function* streamChat(
  request: ChatRequest
): AsyncGenerator<StreamChunk, void, unknown> {
  const url = buildUrl('/api/chat')
  const method = 'POST'

  try {
    logRequest(method, url, request)

    const response = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json',
        Accept: 'text/event-stream',
      },
      body: JSON.stringify(request),
    })

    if (!response.ok) {
      throw await handleErrorResponse(response)
    }

    const reader = response.body?.getReader()
    if (!reader) {
      throw new ApiError(
        'No response body received',
        undefined,
        ErrorCodes.STREAM_ERROR
      )
    }

    const decoder = new TextDecoder()
    let buffer = ''

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split('\n')
      buffer = lines.pop() || ''

      for (const line of lines) {
        const chunk = parseSSELine(line)
        if (chunk) {
          logResponse(method, url, response, chunk)
          yield chunk

          if (chunk.type === 'done' || chunk.type === 'error') {
            return
          }
        }
      }
    }

    // Process any remaining data in buffer
    if (buffer) {
      const chunk = parseSSELine(buffer)
      if (chunk) {
        yield chunk
      }
    }
  } catch (error) {
    logError(method, url, error)

    if (error instanceof ApiError) {
      throw error
    }

    if (error instanceof TypeError && error.message.includes('fetch')) {
      throw new ApiError(
        'Unable to connect to server. Please check that the backend is running.',
        undefined,
        ErrorCodes.BACKEND_UNREACHABLE
      )
    }

    throw new ApiError(
      'Failed to send message',
      undefined,
      ErrorCodes.UNKNOWN
    )
  }
}

/**
 * Parse an SSE data line into a StreamChunk
 */
function parseSSELine(line: string): StreamChunk | null {
  const trimmed = line.trim()
  if (!trimmed.startsWith('data: ')) return null

  const data = trimmed.slice(6)

  // Handle legacy [DONE] marker
  if (data === '[DONE]') {
    return { type: 'done' }
  }

  try {
    const parsed = JSON.parse(data)
    if (parsed.type === 'text_delta' || parsed.type === 'error' || parsed.type === 'done') {
      return parsed as StreamChunk
    }
  } catch {
    // Not valid JSON, ignore
  }

  return null
}

/**
 * Handle error responses from the backend
 */
async function handleErrorResponse(response: Response): Promise<ApiError> {
  const status = response.status
  let message = `Request failed: ${status}`
  let code: ErrorCode = ErrorCodes.UNKNOWN

  try {
    const data = await response.json()
    message = data.error || data.message || message
  } catch {
    // Could not parse JSON, use status-based message
  }

  // Map HTTP status codes to error types
  switch (status) {
    case 400:
      code = ErrorCodes.UNCONFIGURED_PROVIDER
      message = message || 'Provider not configured. Run `pi auth` in your terminal to authenticate.'
      break
    case 401:
    case 403:
      code = ErrorCodes.AUTHENTICATION_FAILED
      message = message || 'Authentication failed. Please check your pi CLI authentication.'
      break
    case 429:
      code = ErrorCodes.RATE_LIMIT
      message = message || 'Rate limit hit. Please try again later.'
      break
    case 500:
    case 502:
    case 503:
    case 504:
      code = ErrorCodes.BACKEND_UNREACHABLE
      message = message || 'Server error. Please try again later.'
      break
  }

  return new ApiError(message, status, code)
}

// Export types for consumers
export type { ConfigResponse, ChatRequest, ChatMessage, StreamChunk }

// Provider management types
export interface CustomProvider {
  name: string
  apiKey: string
  baseUrl?: string
}

interface ProviderListResponse {
  env: string[]
  custom: CustomProvider[]
  all: Array<{ id: string; type: 'env' | 'custom' } & CustomProvider>
}

interface ProviderTestResult {
  success: boolean
  error?: string
}

interface ProviderActionResponse {
  success: boolean
  providers: CustomProvider[]
}

/**
 * List all providers (env + custom)
 */
export async function fetchProviders(): Promise<ProviderListResponse> {
  const url = buildUrl('/api/providers')
  const method = 'GET'

  try {
    logRequest(method, url)

    const response = await fetch(url, {
      method,
      headers: { Accept: 'application/json' },
    })

    if (!response.ok) {
      throw await handleErrorResponse(response)
    }

    const data: ProviderListResponse = await response.json()
    logResponse(method, url, response, data)

    return data
  } catch (error) {
    logError(method, url, error)
    throw error instanceof ApiError ? error : new ApiError('Failed to fetch providers')
  }
}

/**
 * Add a custom provider
 */
export async function addProvider(
  provider: Omit<CustomProvider, 'apiKey'> & { apiKey: string }
): Promise<ProviderActionResponse> {
  const url = buildUrl('/api/providers')
  const method = 'POST'

  try {
    logRequest(method, url, provider)

    const response = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(provider),
    })

    if (!response.ok) {
      throw await handleErrorResponse(response)
    }

    const data: ProviderActionResponse = await response.json()
    logResponse(method, url, response, data)

    return data
  } catch (error) {
    logError(method, url, error)
    throw error instanceof ApiError ? error : new ApiError('Failed to add provider')
  }
}

/**
 * Remove a custom provider
 */
export async function removeProvider(name: string): Promise<ProviderActionResponse> {
  const url = buildUrl(`/api/providers/${encodeURIComponent(name)}`)
  const method = 'DELETE'

  try {
    logRequest(method, url)

    const response = await fetch(url, {
      method,
      headers: { Accept: 'application/json' },
    })

    if (!response.ok) {
      throw await handleErrorResponse(response)
    }

    const data: ProviderActionResponse = await response.json()
    logResponse(method, url, response, data)

    return data
  } catch (error) {
    logError(method, url, error)
    throw error instanceof ApiError ? error : new ApiError('Failed to remove provider')
  }
}

/**
 * Test a provider connection
 */
export async function testProvider(
  provider: string,
  apiKey?: string
): Promise<ProviderTestResult> {
  const url = buildUrl('/api/providers/test')
  const method = 'POST'

  try {
    logRequest(method, url, { provider, apiKey })

    const response = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ provider, apiKey }),
    })

    if (!response.ok) {
      throw await handleErrorResponse(response)
    }

    const data: ProviderTestResult = await response.json()
    logResponse(method, url, response, data)

    return data
  } catch (error) {
    logError(method, url, error)
    throw error instanceof ApiError ? error : new ApiError('Failed to test provider')
  }
}
