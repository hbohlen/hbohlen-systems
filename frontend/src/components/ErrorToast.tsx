import { useEffect } from 'react'
import { X, AlertCircle, WifiOff, Clock, Key, AlertTriangle } from 'lucide-react'
import { ApiError, ErrorCodes } from '../api/apiClient'

interface ErrorToastProps {
  error: Error | ApiError | null
  onDismiss: () => void
  autoDismissMs?: number
}

/**
 * ErrorToast component for displaying error messages with specific guidance
 * Handles different error types with appropriate icons and retry guidance
 */
export function ErrorToast({ error, onDismiss, autoDismissMs = 8000 }: ErrorToastProps) {
  useEffect(() => {
    if (!error) return

    // Log error to browser console
    console.error('[ErrorToast] Displaying error:', error)

    // Auto-dismiss after specified time
    const timer = setTimeout(() => {
      onDismiss()
    }, autoDismissMs)

    return () => clearTimeout(timer)
  }, [error, onDismiss, autoDismissMs])

  if (!error) return null

  const errorInfo = getErrorInfo(error)

  return (
    <div
      className="fixed bottom-4 right-4 left-4 sm:left-auto sm:w-96 z-50 animate-in slide-in-from-bottom-2 fade-in duration-200"
      role="alert"
      aria-live="assertive"
    >
      <div className="bg-destructive text-destructive-foreground rounded-lg shadow-lg p-4 border border-destructive/50">
        <div className="flex items-start gap-3">
          <div className="flex-shrink-0 mt-0.5">
            {errorInfo.icon}
          </div>
          <div className="flex-1 min-w-0">
            <h4 className="font-semibold text-sm mb-1">
              {errorInfo.title}
            </h4>
            <p className="text-sm opacity-90 leading-relaxed">
              {errorInfo.message}
            </p>
            {errorInfo.action && (
              <p className="text-sm mt-2 opacity-80 font-medium">
                {errorInfo.action}
              </p>
            )}
          </div>
          <button
            onClick={onDismiss}
            className="flex-shrink-0 p-1 rounded hover:bg-destructive-foreground/10 transition-colors"
            aria-label="Dismiss error"
          >
            <X size={16} />
          </button>
        </div>
      </div>
    </div>
  )
}

/**
 * Get error information based on error type
 */
function getErrorInfo(error: Error | ApiError): {
  title: string
  message: string
  action?: string
  icon: React.ReactNode
} {
  // Handle ApiError with specific error codes
  if (error instanceof ApiError && error.code) {
    switch (error.code) {
      case ErrorCodes.BACKEND_UNREACHABLE:
        return {
          title: 'Connection Error',
          message: error.message,
          action: 'Check that the backend server is running on port 3000.',
          icon: <WifiOff size={20} />,
        }

      case ErrorCodes.RATE_LIMIT:
        return {
          title: 'Rate Limit Exceeded',
          message: error.message,
          action: 'Please wait a moment before sending another message.',
          icon: <Clock size={20} />,
        }

      case ErrorCodes.UNCONFIGURED_PROVIDER:
        return {
          title: 'Provider Not Configured',
          message: error.message,
          action: 'Run `pi auth` in your terminal to authenticate with your LLM provider.',
          icon: <Key size={20} />,
        }

      case ErrorCodes.AUTHENTICATION_FAILED:
        return {
          title: 'Authentication Failed',
          message: error.message,
          action: 'Check that your API keys are valid using `pi auth status`.',
          icon: <Key size={20} />,
        }

      case ErrorCodes.STREAM_ERROR:
        return {
          title: 'Stream Error',
          message: error.message,
          action: 'Try sending your message again.',
          icon: <AlertTriangle size={20} />,
        }

      case ErrorCodes.NETWORK_ERROR:
        return {
          title: 'Network Error',
          message: error.message,
          action: 'Check your network connection and try again.',
          icon: <WifiOff size={20} />,
        }

      default:
        break
    }
  }

  // Handle network/fetch errors
  if (error instanceof TypeError && error.message.includes('fetch')) {
    return {
      title: 'Connection Error',
      message: 'Unable to connect to the server.',
      action: 'Make sure the backend is running and accessible.',
      icon: <WifiOff size={20} />,
    }
  }

  // Default error display
  return {
    title: 'Error',
    message: error.message || 'An unexpected error occurred.',
    action: 'Please try again or refresh the page.',
    icon: <AlertCircle size={20} />,
  }
}
