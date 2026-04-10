import { readFile } from 'fs/promises';
import { config } from '../config.js';
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
    async getProviders() {
        const agentConfig = await this.loadConfig();
        const providers = [];
        for (const [providerName, providerConfig] of Object.entries(agentConfig.providers)) {
            if (providerConfig.models && Array.isArray(providerConfig.models)) {
                for (const model of providerConfig.models) {
                    providers.push(`${providerName}/${model}`);
                }
            }
        }
        return providers;
    }
    async getDefaultProvider() {
        const agentConfig = await this.loadConfig();
        const entries = Object.entries(agentConfig.providers);
        if (entries.length === 0) {
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
        const agentConfig = await this.loadConfig();
        return agentConfig.providers[provider]?.apiKey;
    }
    async isProviderConfigured(provider) {
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
