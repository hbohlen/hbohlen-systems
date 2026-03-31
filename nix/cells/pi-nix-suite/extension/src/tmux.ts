import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import type { TmuxWindow, TmuxPane, SubagentConfig } from './types.js';

const execFileAsync = promisify(execFile);

export class TmuxManager {
  private socketPath: string;
  private sessionName: string;
  private windowPrefix: string;

  constructor(
    socketPath: string = process.env.XDG_RUNTIME_DIR + '/pi-tmux',
    sessionName: string = 'pi-main',
    windowPrefix: string = 'pi-'
  ) {
    this.socketPath = socketPath;
    this.sessionName = sessionName;
    this.windowPrefix = windowPrefix;
  }

  private getTmuxCommand(): string {
    return `tmux -S ${this.socketPath}`;
  }

  private async execTmux(args: string[]): Promise<string> {
    const { stdout } = await execFileAsync('tmux', ['-S', this.socketPath, ...args]);
    return stdout.trim();
  }

  async isSessionAttached(): Promise<boolean> {
    try {
      await this.execTmux(['has-session', '-t', this.sessionName]);
      return true;
    } catch {
      return false;
    }
  }

  async listWindows(): Promise<TmuxWindow[]> {
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
    } catch {
      return [];
    }
  }

  async findSubagentWindows(): Promise<TmuxWindow[]> {
    const windows = await this.listWindows();
    return windows.filter(w => w.name.startsWith(this.windowPrefix + 'subagent'));
  }

  async spawnSubagentWindow(config: SubagentConfig): Promise<number> {
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

  private buildSubagentCommand(config: SubagentConfig): string {
    const args: string[] = [];
    
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

  private getAgentPrompt(agentType: string): string | null {
    const prompts: Record<string, string> = {
      scout: 'You are a fast reconnaissance agent. Focus on gathering information efficiently. Use grep, find, and read tools. Be concise.',
      worker: 'You are an implementation agent. Focus on writing code and making changes. Use all available tools including write and edit.',
      'nix-expert': 'You are a Nix specialist. Focus on Nix expressions, flakes, and NixOS configuration. Always verify with nix flake check when possible.',
    };
    return prompts[agentType] || null;
  }

  async closeWindow(index: number): Promise<void> {
    await this.execTmux(['kill-window', '-t', `${this.sessionName}:${index}`]);
  }

  async renameWindow(index: number, newName: string): Promise<void> {
    await this.execTmux([
      'rename-window',
      '-t', `${this.sessionName}:${index}`,
      newName
    ]);
  }

  // REPL pane management
  async createReplSplit(type: 'horizontal' | 'vertical' = 'horizontal'): Promise<string> {
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

  async sendToPane(paneId: string, input: string): Promise<void> {
    await this.execTmux([
      'send-keys',
      '-t', paneId,
      input,
      'Enter'
    ]);
  }

  async closePane(paneId: string): Promise<void> {
    await this.execTmux(['kill-pane', '-t', paneId]);
  }
}
