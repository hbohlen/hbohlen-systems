import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
const execFileAsync = promisify(execFile);
export class TmuxManager {
    socketPath;
    sessionName;
    windowPrefix;
    constructor(socketPath = process.env.XDG_RUNTIME_DIR + '/pi-tmux', sessionName = 'pi-main', windowPrefix = 'pi-') {
        this.socketPath = socketPath;
        this.sessionName = sessionName;
        this.windowPrefix = windowPrefix;
    }
    getTmuxCommand() {
        return `tmux -S ${this.socketPath}`;
    }
    async execTmux(args) {
        const { stdout } = await execFileAsync('tmux', ['-S', this.socketPath, ...args]);
        return stdout.trim();
    }
    async isSessionAttached() {
        try {
            await this.execTmux(['has-session', '-t', this.sessionName]);
            return true;
        }
        catch {
            return false;
        }
    }
    async listWindows() {
        try {
            const output = await this.execTmux([
                'list-windows',
                '-t', this.sessionName,
                '-F', '#{window_index}|#{window_name}|#{window_id}|#{window_active}'
            ]);
            return output.split('\n').map(line => {
                const [index, name, id, active] = line.split('|');
                return {
                    index: parseInt(index, 10),
                    name,
                    id,
                    active: active === '1'
                };
            });
        }
        catch {
            return [];
        }
    }
    async findSubagentWindows() {
        const windows = await this.listWindows();
        return windows.filter(w => w.name.startsWith(this.windowPrefix + 'subagent'));
    }
    async spawnSubagentWindow(config) {
        const windowName = `${this.windowPrefix}subagent-${config.name}`;
        // Create new window
        const output = await this.execTmux([
            'new-window',
            '-d',
            '-t', this.sessionName,
            '-n', windowName,
            '-c', config.cwd,
            '-F', '#{window_index}'
        ]);
        const windowIndex = parseInt(output, 10);
        // Send the pi command to the new window
        const piCommand = this.buildSubagentCommand(config);
        await this.execTmux([
            'send-keys',
            '-t', `${this.sessionName}:${windowIndex}`,
            piCommand,
            'Enter'
        ]);
        return windowIndex;
    }
    buildSubagentCommand(config) {
        const args = [];
        if (config.model) {
            args.push('--model', config.model);
        }
        // Set up agent-specific system prompt based on type
        const agentPrompt = this.getAgentPrompt(config.agentType);
        if (agentPrompt) {
            args.push('--system-prompt', agentPrompt);
        }
        // Build the command string
        const escapedTask = config.task.replace(/"/g, '\\"');
        return `pi ${args.join(' ')} "${escapedTask}"`;
    }
    getAgentPrompt(agentType) {
        const prompts = {
            scout: 'You are a fast reconnaissance agent. Focus on gathering information efficiently. Use grep, find, and read tools. Be concise.',
            worker: 'You are an implementation agent. Focus on writing code and making changes. Use all available tools including write and edit.',
            'nix-expert': 'You are a Nix specialist. Focus on Nix expressions, flakes, and NixOS configuration. Always verify with nix flake check when possible.',
        };
        return prompts[agentType] || null;
    }
    async closeWindow(index) {
        await this.execTmux(['kill-window', '-t', `${this.sessionName}:${index}`]);
    }
    async renameWindow(index, newName) {
        await this.execTmux([
            'rename-window',
            '-t', `${this.sessionName}:${index}`,
            newName
        ]);
    }
    // REPL pane management
    async createReplSplit(type = 'horizontal') {
        const percentage = type === 'horizontal' ? '25' : '30';
        const output = await this.execTmux([
            'split-window',
            '-d',
            '-t', this.sessionName,
            '-F', '#{pane_id}',
            type === 'horizontal' ? '-v' : '-h',
            '-p', percentage,
        ]);
        return output.trim();
    }
    async sendToPane(paneId, input) {
        await this.execTmux([
            'send-keys',
            '-t', paneId,
            input,
            'Enter'
        ]);
    }
    async closePane(paneId) {
        await this.execTmux(['kill-pane', '-t', paneId]);
    }
}
//# sourceMappingURL=tmux.js.map