import { useEffect, useState, useCallback } from 'react'
import { ChevronDown, Loader2 } from 'lucide-react'
import { useChatStore } from '../store/useChatStore'
import { fetchConfig, ApiError } from '../api/apiClient'

interface ModelSelectorProps {
  disabled?: boolean
}

export function ModelSelector({ disabled }: ModelSelectorProps) {
  const [providers, setProviders] = useState<string[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isOpen, setIsOpen] = useState(false)

  const {
    selectedProvider,
    selectedModel,
    setSelectedModel,
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
        <span className="text-sm">No models configured</span>
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

            return (
              <button
                key={providerModel}
                onClick={() => handleSelect(providerModel)}
                className={`w-full text-left px-4 py-2 text-sm hover:bg-accent hover:text-accent-foreground transition-colors ${
                  isSelected ? 'bg-accent text-accent-foreground' : ''
                }`}
              >
                <span className="font-medium">{provider}</span>
                <span className="text-muted-foreground"> / {model}</span>
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}
