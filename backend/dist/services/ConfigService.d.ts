interface CustomProvider {
    name: string;
    apiKey: string;
    baseUrl?: string;
    models?: string[];
}
interface AgentConfig {
    version: number;
    providers: Record<string, ProviderConfig>;
}
interface ProviderConfig {
    type: string;
    apiKey: string;
    models: string[];
    defaultModel: string;
}
interface ProviderInfo {
    provider: string;
    model: string;
    apiKey: string;
}
declare class ConfigService {
    private cachedConfig;
    private lastLoadTime;
    private readonly cacheTtlMs;
    loadConfig(): Promise<AgentConfig>;
    /**
     * Detect providers from environment variables
     */
    detectEnvProviders(): string[];
    /**
     * Load custom providers from config file
     */
    loadCustomProviders(): Promise<CustomProvider[]>;
    /**
     * Save custom providers to config file
     */
    saveCustomProviders(providers: CustomProvider[]): Promise<void>;
    /**
     * Add a custom provider
     */
    addCustomProvider(provider: CustomProvider): Promise<CustomProvider[]>;
    /**
     * Remove a custom provider
     */
    removeCustomProvider(name: string): Promise<CustomProvider[]>;
    /**
     * Get all custom providers
     */
    getCustomProviders(): Promise<CustomProvider[]>;
    /**
     * Test a provider connection
     */
    testProvider(provider: string, apiKey?: string): Promise<{
        success: boolean;
        error?: string;
    }>;
    getProviders(): Promise<string[]>;
    getDefaultProvider(): Promise<ProviderInfo | null>;
    getApiKey(provider: string): Promise<string | undefined>;
    isProviderConfigured(provider: string): Promise<boolean>;
    invalidateCache(): void;
}
export declare const configService: ConfigService;
export type { AgentConfig, ProviderConfig, ProviderInfo, CustomProvider };
//# sourceMappingURL=ConfigService.d.ts.map