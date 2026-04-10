import { useEffect, useState, useCallback } from 'react'
import { ChevronDown, Loader2, Play, Check, X, Circle } from 'lucide-react'
import { useChatStore } from '../store/useChatStore'
import { fetchConfig, testProvider, ApiError } from '../api/apiClient'

interface ModelSelectorProps {
  disabled?: boolean
}

export function ModelSelector({ disabled }: ModelSelectorProps) {
  const [providers, setProviders] = useState<string[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isOpen, setIsOpen] = useState(false)
  const [testingProvider, setTestingProvider] = useState<string | null>(null)

  const {
    selectedProvider,
    selectedModel,
    setSelectedModel,
    setProviderStatus,
    providerStatuses,
    isStreaming,
  } = useChatStore()

  // Fetch configuration on mount
  useEffect(() => {
    const loadConfig = async () => {
      try {
        setIsLoading(true)
        setError(null)

        const data = await fetchConfig()
        setProviders(data.providers)

        // Auto-select default if available and nothing selected
        if (data.defaults && !selectedProvider) {
          setSelectedModel(data.defaults.provider, data.defaults.model)
        }
      } catch (err) {
        const errorMessage = err instanceof ApiError
          ? err.message
          : err instanceof Error
            ? err.message
            : 'Failed to load models'
        setError(errorMessage)
        console.error('Error fetching config:', err)
      } finally {
        setIsLoading(false)
      }
    }

    loadConfig()
  }, [selectedProvider, setSelectedModel])

  const handleSelect = useCallback(
    (providerModel: string) => {
      const [provider, ...modelParts] = providerModel.split('/')
      const model = modelParts.join('/') // Handle models with slashes in name
      setSelectedModel(provider, model)
      setIsOpen(false)
    },
    [setSelectedModel]
  )

  const handleTest = useCallback(
    async (providerModel: string, e: React.MouseEvent) => {
      e.stopPropagation()
      if (testingProvider) return

      setTestingProvider(providerModel)
      setProviderStatus(providerModel, 'testing')
      
      try {
        const result = await testProvider(providerModel)
        setProviderStatus(providerModel, result.success ? 'connected' : 'failed')
      } catch {
        setProviderStatus(providerModel, 'failed')
      } finally {
        setTestingProvider(null)
      }
    },
    [testingProvider, setProviderStatus]
  )

  // Format provider/model for display
  const formatDisplay = (provider: string, model: string | null): string => {
    if (!provider || !model) return 'Select a model...'
    return `${provider} / ${model}`
  }

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement
      if (!target.closest('[data-model-selector]')) {
        setIsOpen(false)
      }
    }

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isOpen])

  // Loading state
  if (isLoading) {
    return (
      <div className="flex items-center gap-2 px-4 py-2 text-muted-foreground">
        <Loader2 size={16} className="animate-spin" />
        <span className="text-sm">Loading models...</span>
      </div>
    )
  }

  // Error state
  if (error) {
    return (
      <div className="flex items-center gap-2 px-4 py-2 text-destructive">
        <span className="text-sm">Error: {error}</span>
      </div>
    )
  }

  // Empty state
  if (providers.length === 0) {
    return (
      <div className="flex items-center gap-2 px-4 py-2 text-muted-foreground">
        <Circle size={16} />
        <span className="text-sm">No providers configured</span>
      </div>
    )
  }

  const currentSelection = selectedProvider && selectedModel
    ? `${selectedProvider}/${selectedModel}`
    : null

  return (
    <div data-model-selector className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        disabled={disabled}
        className="flex items-center gap-2 px-4 py-2 bg-secondary text-secondary-foreground rounded-lg hover:bg-secondary/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors min-w-[200px] justify-between"
      >
        <span className="text-sm truncate">
          {formatDisplay(selectedProvider || '', selectedModel)}
        </span>
        <ChevronDown
          size={16}
          className={`transition-transform ${isOpen ? 'rotate-180' : ''}`}
        />
      </button>

      {isOpen && (
        <div className="absolute top-full left-0 right-0 mt-1 bg-popover border border-border rounded-lg shadow-lg z-50 max-h-60 overflow-y-auto">
          {providers.map((providerModel) => {
            const [provider, ...modelParts] = providerModel.split('/')
            const model = modelParts.join('/')
            const isSelected = currentSelection === providerModel
            const status = providerStatuses[providerModel]
            const isTesting = testingProvider === providerModel

            return (
              <div
                key={providerModel}
                className={`flex items-center justify-between px-4 py-2 hover:bg-accent transition-colors ${
                  isSelected ? 'bg-accent' : ''
                }`}
              >
                <button
                  onClick={() => handleSelect(providerModel)}
                  className="flex-1 text-left"
                >
                  <span className="font-medium">{provider}</span>
                  <span className="text-muted-foreground"> / {model}</span>
                </button>
                
                <button
                  onClick={(e) => handleTest(providerModel, e)}
                  disabled={isTesting || isStreaming}
                  className="p-1 hover:bg-primary/20 rounded ml-2 disabled:opacity-50"
                  title="Test connection"
                >
                  {isTesting ? (
                    <Loader2 size={14} className="animate-spin" />
                  ) : status === 'connected' ? (
                    <Check size={14} className="text-green-500" />
                  ) : status === 'failed' ? (
                    <X size={14} className="text-red-500" />
                  ) : (
                    <Play size={14} className="text-muted-foreground" />
                  )}
                </button>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
