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
    getProviders(): Promise<string[]>;
    getDefaultProvider(): Promise<ProviderInfo | null>;
    getApiKey(provider: string): Promise<string | undefined>;
    isProviderConfigured(provider: string): Promise<boolean>;
    invalidateCache(): void;
}
export declare const configService: ConfigService;
export type { AgentConfig, ProviderConfig, ProviderInfo };
//# sourceMappingURL=ConfigService.d.ts.map