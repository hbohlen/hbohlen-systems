import type { TmuxWindow, SubagentConfig } from './types.js';
export declare class TmuxManager {
    private socketPath;
    private sessionName;
    private windowPrefix;
    constructor(socketPath?: string, sessionName?: string, windowPrefix?: string);
    private getTmuxCommand;
    private execTmux;
    isSessionAttached(): Promise<boolean>;
    listWindows(): Promise<TmuxWindow[]>;
    findSubagentWindows(): Promise<TmuxWindow[]>;
    spawnSubagentWindow(config: SubagentConfig): Promise<number>;
    private buildSubagentCommand;
    private getAgentPrompt;
    closeWindow(index: number): Promise<void>;
    renameWindow(index: number, newName: string): Promise<void>;
    createReplSplit(type?: 'horizontal' | 'vertical'): Promise<string>;
    sendToPane(paneId: string, input: string): Promise<void>;
    closePane(paneId: string): Promise<void>;
}
//# sourceMappingURL=tmux.d.ts.map