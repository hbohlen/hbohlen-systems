import { readFile, writeFile, mkdir } from 'fs/promises';
import { dirname } from 'path';
import { config } from '../config.js';
// Environment variable to provider mapping
const ENV_PROVIDER_MAP = {
    'OPENAI_API_KEY': 'openai',
    'ANTHROPIC_API_KEY': 'anthropic',
    'ANTHROPIC_OAUTH_TOKEN': 'anthropic',
    'GEMINI_API_KEY': 'google',
    'GOOGLE_CLOUD_API_KEY': 'google-vertex',
    'GROQ_API_KEY': 'groq',
    'OPENCODE_API_KEY': 'opencode-go',
    'MINIMAX_API_KEY': 'minimax',
    'MINIMAX_CN_API_KEY': 'minimax-cn',
    'MISTRAL_API_KEY': 'mistral',
    'CEREBRAS_API_KEY': 'cerebras',
    'XAI_API_KEY': 'xai',
    'OPENROUTER_API_KEY': 'openrouter',
    'HUGGINGFACE_TOKEN': 'huggingface',
    'KIMI_API_KEY': 'kimi-coding',
    'ZAI_API_KEY': 'zai',
    'AZURE_OPENAI_API_KEY': 'azure-openai-responses',
    'GITHUB_TOKEN': 'github-copilot',
    'COPILOT_GITHUB_TOKEN': 'github-copilot',
    'GH_TOKEN': 'github-copilot',
};
class ConfigService {
    cachedConfig = null;
    lastLoadTime = 0;
    cacheTtlMs = 30000; // 30 seconds
    async loadConfig() {
        // Check cache first
        const now = Date.now();
        if (this.cachedConfig && now - this.lastLoadTime < this.cacheTtlMs) {
            return this.cachedConfig;
        }
        try {
            const data = await readFile(config.authFilePath, 'utf-8');
            const parsed = JSON.parse(data);
            // Validate structure
            if (!parsed.providers || typeof parsed.providers !== 'object') {
                throw new Error('Invalid auth.json structure: missing providers');
            }
            this.cachedConfig = parsed;
            this.lastLoadTime = now;
            console.log(`[ConfigService] Loaded config with ${Object.keys(parsed.providers).length} providers`);
            return parsed;
        }
        catch (error) {
            console.warn(`[ConfigService] Failed to load auth.json: ${error instanceof Error ? error.message : String(error)}`);
            // Return empty config on failure
            const emptyConfig = {
                version: 1,
                providers: {}
            };
            this.cachedConfig = emptyConfig;
            this.lastLoadTime = now;
            return emptyConfig;
        }
    }
    /**
     * Detect providers from environment variables
     */
    detectEnvProviders() {
        const providers = [];
        const detected = new Set();
        for (const [envVar, provider] of Object.entries(ENV_PROVIDER_MAP)) {
            if (process.env[envVar] && !detected.has(provider)) {
                detected.add(provider);
                // Use default model placeholder - will be resolved by frontend
                providers.push(`${provider}/default`);
            }
        }
        console.log(`[ConfigService] Detected env providers: ${providers.join(', ') || 'none'}`);
        return providers;
    }
    /**
     * Load custom providers from config file
     */
    async loadCustomProviders() {
        try {
            const data = await readFile(config.customProvidersPath, 'utf-8');
            const parsed = JSON.parse(data);
            return parsed.providers || [];
        }
        catch {
            return [];
        }
    }
    /**
     * Save custom providers to config file
     */
    async saveCustomProviders(providers) {
        const dir = dirname(config.customProvidersPath);
        await mkdir(dir, { recursive: true });
        const configData = { version: 1, providers };
        await writeFile(config.customProvidersPath, JSON.stringify(configData, null, 2));
    }
    /**
     * Add a custom provider
     */
    async addCustomProvider(provider) {
        const existing = await this.loadCustomProviders();
        const filtered = existing.filter(p => p.name !== provider.name);
        const updated = [...filtered, provider];
        await this.saveCustomProviders(updated);
        this.invalidateCache();
        return updated;
    }
    /**
     * Remove a custom provider
     */
    async removeCustomProvider(name) {
        const existing = await this.loadCustomProviders();
        const updated = existing.filter(p => p.name !== name);
        await this.saveCustomProviders(updated);
        this.invalidateCache();
        return updated;
    }
    /**
     * Get all custom providers
     */
    async getCustomProviders() {
        return this.loadCustomProviders();
    }
    /**
     * Test a provider connection
     */
    async testProvider(provider, apiKey) {
        const key = apiKey || await this.getApiKey(provider);
        if (!key) {
            return { success: false, error: 'No API key found' };
        }
        try {
            // Try to import pi-ai and validate the provider exists
            const piAi = await import('@mariozechner/pi-ai');
            // Normalize provider name (remove custom/ prefix if present)
            const normalizedProvider = provider.startsWith('custom/')
                ? provider.replace('custom/', '')
                : provider;
            // Get list of recognized providers
            const knownProviders = piAi.getProviders();
            if (!knownProviders.includes(normalizedProvider)) {
                // For custom providers, we can't validate ahead of time
                // Just return success and let the actual chat call fail if invalid
                if (provider.startsWith('custom/')) {
                    return { success: true };
                }
                return { success: false, error: `Unknown provider: ${provider}` };
            }
            return { success: true };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error'
            };
        }
    }
    async getProviders() {
        // Env providers (format: "provider/default")
        const envProviders = this.detectEnvProviders();
        // Custom providers (format: "custom/name")
        const customProviders = await this.loadCustomProviders();
        const customProviderStrings = customProviders.map(p => `custom/${p.name}`);
        return [...envProviders, ...customProviderStrings];
    }
    async getDefaultProvider() {
        const agentConfig = await this.loadConfig();
        const entries = Object.entries(agentConfig.providers);
        if (entries.length === 0) {
            // Try env providers
            const envProviders = this.detectEnvProviders();
            if (envProviders.length > 0) {
                const first = envProviders[0];
                const [provider] = first.split('/');
                // Find the env var that maps to this provider
                const envVar = Object.entries(ENV_PROVIDER_MAP).find(([, p]) => p === provider)?.[0];
                const apiKey = envVar ? process.env[envVar] : '';
                return {
                    provider: provider,
                    model: 'default',
                    apiKey: apiKey || ''
                };
            }
            return null;
        }
        // Use the first provider with a default model
        for (const [providerName, providerConfig] of entries) {
            if (providerConfig.defaultModel) {
                return {
                    provider: providerName,
                    model: providerConfig.defaultModel,
                    apiKey: providerConfig.apiKey
                };
            }
        }
        // Fallback to first provider's first model
        const [firstProvider, firstConfig] = entries[0];
        if (firstConfig.models && firstConfig.models.length > 0) {
            return {
                provider: firstProvider,
                model: firstConfig.models[0],
                apiKey: firstConfig.apiKey
            };
        }
        return null;
    }
    async getApiKey(provider) {
        // Check env first
        for (const [envVar, p] of Object.entries(ENV_PROVIDER_MAP)) {
            if (p === provider && process.env[envVar]) {
                return process.env[envVar];
            }
        }
        // Check custom providers (handle both "provider" and "custom/provider" formats)
        const customProviders = await this.loadCustomProviders();
        const customProviderName = provider.startsWith('custom/') ? provider.replace('custom/', '') : provider;
        const custom = customProviders.find(p => p.name === customProviderName);
        if (custom) {
            return custom.apiKey;
        }
        // Also check by full match
        const customByFull = customProviders.find(p => `custom/${p.name}` === provider);
        if (customByFull) {
            return customByFull.apiKey;
        }
        // Fallback to auth.json
        const agentConfig = await this.loadConfig();
        return agentConfig.providers[provider]?.apiKey;
    }
    async isProviderConfigured(provider) {
        // Check env
        for (const [envVar, p] of Object.entries(ENV_PROVIDER_MAP)) {
            if (p === provider && process.env[envVar]) {
                return true;
            }
        }
        // Check custom
        const customProviders = await this.loadCustomProviders();
        const customProviderName = provider.startsWith('custom/') ? provider.replace('custom/', '') : provider;
        if (customProviders.some(p => p.name === customProviderName)) {
            return true;
        }
        // Fallback to auth.json
        const agentConfig = await this.loadConfig();
        return provider in agentConfig.providers;
    }
    invalidateCache() {
        this.cachedConfig = null;
        this.lastLoadTime = 0;
        console.log('[ConfigService] Cache invalidated');
    }
}
// Export singleton instance
export const configService = new ConfigService();
