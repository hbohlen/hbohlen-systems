import type { DetectedPattern, SkillSuggestion } from './types.js';
interface MessagePart {
    type: string;
    text?: string;
    name?: string;
    arguments?: Record<string, unknown>;
}
interface Message {
    role: string;
    content: MessagePart[];
}
export declare class SkillGenerator {
    private config;
    private pendingSuggestions;
    private savedSkillsDir;
    constructor(config: SkillGenerator['config']);
    analyzeSession(messages: Message[], workingDir: string): SkillSuggestion | null;
    private checkSkillExists;
    detectPattern(messages: Message[], workingDir: string): DetectedPattern | null;
    private identifyPattern;
    private generateSkillContent;
    private describeTool;
    private extractExampleQuery;
    getPendingSuggestions(): SkillSuggestion[];
    approveSkill(name: string): SkillSuggestion | null;
    rejectSkill(name: string): boolean;
    saveApprovedSkills(): Promise<string[]>;
}
export {};
//# sourceMappingURL=skill-generator.d.ts.map