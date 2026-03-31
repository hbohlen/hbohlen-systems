import type { TmuxManager } from './tmux.js';
import type { ReplType, ReplSession } from './types.js';
export declare class ReplManager {
    private tmux;
    private sessions;
    private config;
    constructor(tmux: TmuxManager, config: ReplManager['config']);
    openRepl(type: ReplType, cwd: string): Promise<string>;
    closeRepl(paneId: string): Promise<void>;
    sendToRepl(paneId: string, code: string): Promise<void>;
    getActiveRepls(): ReplSession[];
    getReplByType(type: ReplType): ReplSession | undefined;
    closeAllRepls(): Promise<void>;
    private checkReplAvailable;
    private findVenvPython;
}
//# sourceMappingURL=repl-manager.d.ts.map