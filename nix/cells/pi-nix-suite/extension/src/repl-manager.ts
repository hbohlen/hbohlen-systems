import type { TmuxManager } from './tmux.js';
import type { ReplType, ReplSession } from './types.js';
import { access } from 'node:fs/promises';
import { join } from 'node:path';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

export class ReplManager {
  private tmux: TmuxManager;
  private sessions: Map<string, ReplSession> = new Map();
  private config: Record<ReplType, { enabled: boolean; command: string; initCommands?: string[]; detectVenv?: boolean }>;

  constructor(
    tmux: TmuxManager,
    config: ReplManager['config']
  ) {
    this.tmux = tmux;
    this.config = config;
  }

  async openRepl(type: ReplType, cwd: string): Promise<string> {
    const config = this.config[type];
    if (!config?.enabled) {
      throw new Error(`REPL type '${type}' is not enabled`);
    }

    // Check if REPL is installed
    const isAvailable = await this.checkReplAvailable(type, cwd);
    if (!isAvailable) {
      throw new Error(`${type} REPL is not available. Install it with your package manager.`);
    }

    // Create new pane for REPL
    const paneId = await this.tmux.createReplSplit('horizontal');

    // Build command with venv detection for Python
    let command = config.command;
    if (type === 'python' && config.detectVenv) {
      const venvPython = await this.findVenvPython(cwd);
      if (venvPython) {
        command = venvPython;
      }
    }

    // Send command to pane
    await this.tmux.sendToPane(paneId, command);

    // Send init commands if any
    if (config.initCommands) {
      for (const initCmd of config.initCommands) {
        await new Promise(r => setTimeout(r, 500)); // Wait for REPL to start
        await this.tmux.sendToPane(paneId, initCmd);
      }
    }

    // Store session
    const session: ReplSession = {
      type,
      paneId,
      workingDir: cwd,
      startTime: new Date(),
      history: [],
    };
    this.sessions.set(paneId, session);

    return paneId;
  }

  async closeRepl(paneId: string): Promise<void> {
    const session = this.sessions.get(paneId);
    if (!session) {
      throw new Error(`No REPL session found for pane ${paneId}`);
    }

    await this.tmux.closePane(paneId);
    this.sessions.delete(paneId);
  }

  async sendToRepl(paneId: string, code: string): Promise<void> {
    const session = this.sessions.get(paneId);
    if (!session) {
      throw new Error(`No REPL session found for pane ${paneId}`);
    }

    await this.tmux.sendToPane(paneId, code);
    session.history.push(code);
  }

  getActiveRepls(): ReplSession[] {
    return Array.from(this.sessions.values());
  }

  getReplByType(type: ReplType): ReplSession | undefined {
    return Array.from(this.sessions.values()).find(s => s.type === type);
  }

  async closeAllRepls(): Promise<void> {
    const paneIds = Array.from(this.sessions.keys());
    for (const paneId of paneIds) {
      await this.closeRepl(paneId);
    }
  }

  private async checkReplAvailable(type: ReplType, cwd: string): Promise<boolean> {
    try {
      switch (type) {
        case 'nix':
          // Check for nix command
          await execFileAsync('which', ['nix']);
          return true;
        case 'python':
          // Check for python3 or venv python
          const venvPython = await this.findVenvPython(cwd);
          if (venvPython) return true;
          await execFileAsync('which', ['python3']);
          return true;
        case 'node':
          await execFileAsync('which', ['node']);
          return true;
        default:
          return false;
      }
    } catch {
      return false;
    }
  }

  private async findVenvPython(cwd: string): Promise<string | null> {
    const venvPaths = [
      join(cwd, '.venv/bin/python'),
      join(cwd, 'venv/bin/python'),
      join(cwd, '.venv/bin/python3'),
      join(cwd, 'venv/bin/python3'),
    ];

    for (const venvPath of venvPaths) {
      try {
        await access(venvPath);
        return venvPath;
      } catch {
        continue;
      }
    }
    return null;
  }
}
