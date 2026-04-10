import { useState } from 'react'
import { X } from 'lucide-react'
import { useChatStore } from '../store/useChatStore'
import { addProvider, testProvider, ApiError } from '../api/apiClient'

interface AddProviderModalProps {
  isOpen: boolean
  onClose: () => void
}

export function AddProviderModal({ isOpen, onClose }: AddProviderModalProps) {
  const [name, setName] = useState('')
  const [apiKey, setApiKey] = useState('')
  const [baseUrl, setBaseUrl] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const addCustomProvider = useChatStore(state => state.addCustomProvider)

  if (!isOpen) return null

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      await addProvider({ name, apiKey, baseUrl: baseUrl || undefined })
      addCustomProvider({ name, apiKey, baseUrl: baseUrl || undefined })
      setName('')
      setApiKey('')
      setBaseUrl('')
      onClose()
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Failed to add provider')
    } finally {
      setIsLoading(false)
    }
  }

  const handleTest = async () => {
    if (!name || !apiKey) return
    setIsLoading(true)
    setError(null)
    
    try {
      const result = await testProvider(`custom/${name}`, apiKey)
      if (result.success) {
        setError(null)
        alert('Connection successful!')
      } else {
        setError(`Connection failed: ${result.error}`)
      }
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Test failed')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-card border border-border rounded-lg w-full max-w-md p-6 shadow-xl">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold">Add Custom Provider</h2>
          <button
            onClick={onClose}
            className="p-1 hover:bg-accent rounded"
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Provider Name</label>
            <input
              type="text"
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="e.g., my-openai"
              required
              className="w-full px-3 py-2 bg-background border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">API Key</label>
            <input
              type="password"
              value={apiKey}
              onChange={e => setApiKey(e.target.value)}
              placeholder="sk-..."
              required
              className="w-full px-3 py-2 bg-background border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Base URL (optional)</label>
            <input
              type="url"
              value={baseUrl}
              onChange={e => setBaseUrl(e.target.value)}
              placeholder="https://api.openai.com/v1"
              className="w-full px-3 py-2 bg-background border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          {error && (
            <div className="text-sm text-destructive">{error}</div>
          )}

          <div className="flex gap-2 justify-end pt-2">
            <button
              type="button"
              onClick={handleTest}
              disabled={!name || !apiKey || isLoading}
              className="px-4 py-2 text-sm border border-border rounded-lg hover:bg-accent disabled:opacity-50"
            >
              Test
            </button>
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm border border-border rounded-lg hover:bg-accent"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!name || !apiKey || isLoading}
              className="px-4 py-2 text-sm bg-primary text-primary-foreground rounded-lg hover:opacity-90 disabled:opacity-50"
            >
              Add
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
