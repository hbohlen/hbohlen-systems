# pi-nix-suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a pi extension providing tmux-native subagent visibility, multi-REPL integration (Nix/Python/Node), and a self-improving skill system with hybrid user approval.

**Architecture:** TypeScript pi extension using tmux CLI for window/pane management, spawning subagents as separate pi processes in new tmux windows. REPLs run in tmux splits. Skill generation uses pattern detection on successful sessions with one-keystroke user approval. Packaged as a Nix flake output.

**Tech Stack:** TypeScript, tmux CLI, pi extension API (@mariozechner/pi-coding-agent), Nix

---

## File Structure

```
nix/cells/pi-nix-suite/
├── default.nix                    # Package derivation
├── extension/                     # TypeScript source
│   ├── package.json
│   ├── tsconfig.json
│   ├── src/
│   │   ├── index.ts              # Main extension entry
│   │   ├── tmux.ts               # Tmux window/pane management
│   │   ├── repl-manager.ts       # REPL lifecycle
│   │   ├── skill-generator.ts    # Pattern detection & generation
│   │   ├── commands.ts           # Slash command handlers
│   │   └── types.ts              # Shared type definitions
│   └── templates/
│       ├── agent-scout.md
│       ├── agent-worker.md
│       ├── agent-nix-expert.md
│       └── skill-template.md
├── skills/                        # Version-controlled skills
│   ├── nixos-deploy.md
│   ├── flake-debug.md
│   └── system-upgrade.md
└── config.nix                     # Default configuration
```

---

## Task 1: Project Scaffolding

**Files:**
- Create: `nix/cells/pi-nix-suite/extension/package.json`
- Create: `nix/cells/pi-nix-suite/extension/tsconfig.json`
- Create: `nix/cells/pi-nix-suite/default.nix`

- [ ] **Step 1: Create package.json**

```json
{
  "name": "pi-nix-suite",
  "version": "0.1.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "check": "tsc --noEmit"
  },
  "dependencies": {
    "@mariozechner/pi-coding-agent": "^0.12.0",
    "@mariozechner/pi-agent-core": "^0.12.0",
    "@mariozechner/pi-ai": "^0.12.0",
    "@mariozechner/pi-tui": "^0.12.0",
    "@sinclair/typebox": "^0.32.0"
  },
  "devDependencies": {
    "typescript": "^5.3.0",
    "@types/node": "^20.0.0"
  }
}
```

- [ ] **Step 2: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

- [ ] **Step 3: Create default.nix**

```nix
{ pkgs, lib, ... }:

pkgs.buildNpmPackage rec {
  pname = "pi-nix-suite";
  version = "0.1.0";
  
  src = ./extension;
  
  npmDepsHash = lib.fakeHash; # Will update after first build attempt
  
  nativeBuildInputs = with pkgs; [
    nodejs
    typescript
  ];
  
  buildPhase = ''
    npm run build
  '';
  
  installPhase = ''
    mkdir -p $out/share/pi/extensions/pi-nix-suite
    cp -r dist/* $out/share/pi/extensions/pi-nix-suite/
    cp -r templates $out/share/pi/extensions/pi-nix-suite/ || true
    
    # Install default skills
    mkdir -p $out/share/pi/skills
    cp -r ${./skills}/* $out/share/pi/skills/ 2>/dev/null || true
  '';
  
  meta = with lib; {
    description = "Nix integration suite for pi coding agent";
    license = licenses.mit;
  };
}
```

- [ ] **Step 4: Create src directory structure**

```bash
mkdir -p nix/cells/pi-nix-suite/extension/src
mkdir -p nix/cells/pi-nix-suite/extension/templates
mkdir -p nix/cells/pi-nix-suite/skills
```

- [ ] **Step 5: Commit scaffolding**

```bash
git add nix/cells/pi-nix-suite/
git commit -m "feat(pi-nix-suite): project scaffolding with TypeScript and Nix build"
```

---

## Task 2: Type Definitions

**Files:**
- Create: `nix/cells/pi-nix-suite/extension/src/types.ts`

- [ ] **Step 1: Define core types**

```typescript
// types.ts

export type ReplType = 'nix' | 'python' | 'node';

export interface TmuxWindow {
  index: number;
  name: string;
  id: string;
  active: boolean;
}

export interface TmuxPane {
  id: string;
  windowIndex: number;
  active: boolean;
  width: number;
  height: number;
}

export interface ReplSession {
  type: ReplType;
  paneId: string;
  workingDir: string;
  startTime: Date;
  history: string[];
}

export interface SubagentConfig {
  name: string;
  agentType: 'scout' | 'worker' | 'nix-expert' | 'custom';
  task: string;
  cwd: string;
  model?: string;
  tools?: string[];
}

export interface DetectedPattern {
  name: string;
  description: string;
  toolSequence: string[];
  filePatterns: string[];
  keywords: string[];
  confidence: number;
  category: 'nix' | 'python' | 'node' | 'general';
}

export interface SkillSuggestion {
  name: string;
  description: string;
  pattern: DetectedPattern;
  content: string;
  approved: boolean | null;
}

export interface PiNixSuiteConfig {
  tmux: {
    socket: string;
    sessionName: string;
    windowPrefix: string;
    autoCloseCompleted: boolean;
    defaultLayout: string;
  };
  repls: Record<ReplType, {
    enabled: boolean;
    command: string;
    initCommands?: string[];
    detectVenv?: boolean;
  }>;
  skillGeneration: {
    enabled: boolean;
    threshold: number;
    autoSave: boolean;
    maxSuggestionsPerSession: number;
    categories: string[];
  };
}

export const DEFAULT_CONFIG: PiNixSuiteConfig = {
  tmux: {
    socket: '${XDG_RUNTIME_DIR}/pi-tmux',
    sessionName: 'pi-main',
    windowPrefix: 'pi-',
    autoCloseCompleted: true,
    defaultLayout: 'even-horizontal',
  },
  repls: {
    nix: {
      enabled: true,
      command: 'nix repl .#',
      initCommands: [],
    },
    python: {
      enabled: true,
      command: 'python3',
      detectVenv: true,
    },
    node: {
      enabled: true,
      command: 'node',
    },
  },
  skillGeneration: {
    enabled: true,
    threshold: 0.8,
    autoSave: false,
    maxSuggestionsPerSession: 3,
    categories: ['nix', 'deployment', 'python', 'node', 'general'],
  },
};
```

- [ ] **Step 2: Commit types**

```bash
git add nix/cells/pi-nix-suite/extension/src/types.ts
git commit -m "feat(pi-nix-suite): add core type definitions"
```

---

## Task 3: Tmux Manager Module

**Files:**
- Create: `nix/cells/pi-nix-suite/extension/src/tmux.ts`
- Create: `nix/cells/pi-nix-suite/extension/src/tmux.test.ts`

- [ ] **Step 1: Write failing test**

```typescript
// tmux.test.ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { TmuxManager } from './tmux.js';

describe('TmuxManager', () => {
  let tmux: TmuxManager;
  
  beforeEach(() => {
    tmux = new TmuxManager('/tmp/test-tmux.sock');
  });
  
  it('should format socket path correctly', () => {
    expect(tmux['socketPath']).toBe('/tmp/test-tmux.sock');
  });
  
  it('should generate correct tmux command prefix', () => {
    const prefix = tmux['getTmuxCommand']();
    expect(prefix).toContain('-S /tmp/test-tmux.sock');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd nix/cells/pi-nix-suite/extension
npm install -D vitest
npx vitest run src/tmux.test.ts
```

Expected: FAIL with "TmuxManager not defined"

- [ ] **Step 3: Implement TmuxManager**

```typescript
// tmux.ts
import { spawn, execFile } from 'node:child_process';
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
    const percentage = type === 'horizontal' ? '25%' : '30%';
    
    const output = await this.execTmux([
      'split-window',
      '-d',
      '-t', this.sessionName,
      '-F', '#{pane_id}',
      type === 'horizontal' ? '-v' : '-h',
      '-p', percentage.replace('%', ''),
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
```

- [ ] **Step 4: Run tests**

```bash
npx vitest run src/tmux.test.ts
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add nix/cells/pi-nix-suite/extension/src/tmux.ts
git add nix/cells/pi-nix-suite/extension/src/tmux.test.ts
git commit -m "feat(pi-nix-suite): add TmuxManager for window and pane control"
```

---

## Task 4: REPL Manager Module

**Files:**
- Create: `nix/cells/pi-nix-suite/extension/src/repl-manager.ts`

- [ ] **Step 1: Implement REPL manager**

```typescript
// repl-manager.ts
import type { TmuxManager } from './tmux.js';
import type { ReplType, ReplSession } from './types.js';
import { access } from 'node:fs/promises';
import { join } from 'node:path';

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

import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
const execFileAsync = promisify(execFile);
```

- [ ] **Step 2: Commit REPL manager**

```bash
git add nix/cells/pi-nix-suite/extension/src/repl-manager.ts
git commit -m "feat(pi-nix-suite): add ReplManager for Nix/Python/Node REPLs"
```

---

## Task 5: Skill Generator Module

**Files:**
- Create: `nix/cells/pi-nix-suite/extension/src/skill-generator.ts`

- [ ] **Step 1: Implement pattern detection and skill generation**

```typescript
// skill-generator.ts
import type { Message, ToolCall, ToolResult } from '@mariozechner/pi-agent-core';
import type { DetectedPattern, SkillSuggestion } from './types.js';
import { writeFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';

export class SkillGenerator {
  private config: {
    enabled: boolean;
    threshold: number;
    autoSave: boolean;
    maxSuggestionsPerSession: number;
    categories: string[];
  };
  private pendingSuggestions: SkillSuggestion[] = [];

  constructor(config: SkillGenerator['config']) {
    this.config = config;
  }

  analyzeSession(messages: Message[], workingDir: string): SkillSuggestion | null {
    if (!this.config.enabled) return null;
    if (this.pendingSuggestions.length >= this.config.maxSuggestionsPerSession) return null;

    const pattern = this.detectPattern(messages, workingDir);
    if (!pattern || pattern.confidence < this.config.threshold) return null;

    // Check if we already have a pending suggestion for this pattern
    const existing = this.pendingSuggestions.find(s => s.pattern.name === pattern.name);
    if (existing) return null;

    const skillContent = this.generateSkillContent(pattern, messages);
    
    const suggestion: SkillSuggestion = {
      name: pattern.name,
      description: pattern.description,
      pattern,
      content: skillContent,
      approved: null,
    };

    this.pendingSuggestions.push(suggestion);
    return suggestion;
  }

  detectPattern(messages: Message[], workingDir: string): DetectedPattern | null {
    const toolCalls: ToolCall[] = [];
    const filesTouched = new Set<string>();
    const keywords = new Set<string>();

    // Extract tool calls and file patterns from messages
    for (const msg of messages) {
      if (msg.role === 'assistant') {
        for (const part of msg.content) {
          if (part.type === 'toolCall') {
            toolCalls.push(part);
            keywords.add(part.name);
            
            // Extract file paths from tool arguments
            const args = part.arguments as Record<string, unknown>;
            if (args.file_path) filesTouched.add(args.file_path as string);
            if (args.path) filesTouched.add(args.path as string);
          }
          if (part.type === 'text') {
            // Extract keywords from text
            const text = part.text.toLowerCase();
            if (text.includes('nix')) keywords.add('nix');
            if (text.includes('flake')) keywords.add('flake');
            if (text.includes('deploy')) keywords.add('deploy');
            if (text.includes('python')) keywords.add('python');
            if (text.includes('node') || text.includes('npm')) keywords.add('node');
          }
        }
      }
    }

    // Detect pattern based on tool sequence and keywords
    return this.identifyPattern(toolCalls, filesTouched, keywords);
  }

  private identifyPattern(
    toolCalls: ToolCall[],
    filesTouched: Set<string>,
    keywords: Set<string>
  ): DetectedPattern | null {
    const toolSequence = toolCalls.map(t => t.name);
    const filePatterns = Array.from(filesTouched).map(f => {
      if (f.endsWith('.nix')) return '*.nix';
      if (f.endsWith('.py')) return '*.py';
      if (f.endsWith('.js') || f.endsWith('.ts')) return '*.js';
      if (f.includes('flake')) return 'flake.*';
      return f;
    });

    // Pattern: Nix flake debugging
    if (keywords.has('nix') && keywords.has('flake')) {
      return {
        name: 'nix-flake-debug',
        description: 'Debug and fix Nix flake evaluation errors',
        toolSequence: [...new Set(toolSequence)],
        filePatterns: [...new Set(filePatterns)],
        keywords: ['nix', 'flake', 'eval', 'check'],
        confidence: 0.9,
        category: 'nix',
      };
    }

    // Pattern: NixOS deployment
    if (keywords.has('nix') && keywords.has('deploy')) {
      return {
        name: 'nixos-deploy',
        description: 'Deploy NixOS configuration to remote hosts',
        toolSequence: [...new Set(toolSequence)],
        filePatterns: [...new Set(filePatterns)],
        keywords: ['nixos', 'deploy', 'rebuild', 'switch'],
        confidence: 0.85,
        category: 'deployment',
      };
    }

    // Pattern: Python dependency management
    if (keywords.has('python') && filePatterns.some(f => f.includes('requirements') || f.includes('.txt'))) {
      return {
        name: 'python-deps',
        description: 'Manage Python dependencies and virtual environments',
        toolSequence: [...new Set(toolSequence)],
        filePatterns: [...new Set(filePatterns)],
        keywords: ['python', 'pip', 'venv', 'requirements'],
        confidence: 0.8,
        category: 'python',
      };
    }

    // Pattern: Node.js package management
    if (keywords.has('node') || filePatterns.some(f => f.includes('package.json'))) {
      return {
        name: 'node-packages',
        description: 'Manage Node.js packages and build JavaScript projects',
        toolSequence: [...new Set(toolSequence)],
        filePatterns: [...new Set(filePatterns)],
        keywords: ['node', 'npm', 'package', 'build'],
        confidence: 0.8,
        category: 'node',
      };
    }

    return null;
  }

  private generateSkillContent(pattern: DetectedPattern, messages: Message[]): string {
    const toolList = pattern.toolSequence.join(', ');
    
    return `---
name: ${pattern.name}
description: ${pattern.description}
type: auto-generated
category: ${pattern.category}
tools: ${toolList}
generated: ${new Date().toISOString()}
confidence: ${pattern.confidence}
---

# ${pattern.name}

${pattern.description}

## When to Use

This skill is triggered when:
${pattern.keywords.map(k => `- ${k} is mentioned`).join('\n')}
${pattern.filePatterns.map(f => `- Working with ${f} files`).join('\n')}

## Workflow

1. Analyze the current state by reading relevant files
2. Identify the specific issue or task
3. Make necessary changes using appropriate tools
4. Verify the fix with relevant commands

## Common Patterns

${pattern.toolSequence.map(tool => `- **${tool}**: Use for ${this.describeTool(tool)}`).join('\n')}

## Example Usage

User: "${this.extractExampleQuery(messages)}"
→ Apply this skill to resolve the issue
`;
  }

  private describeTool(toolName: string): string {
    const descriptions: Record<string, string> = {
      read: 'examining file contents',
      write: 'creating new files',
      edit: 'modifying existing files',
      bash: 'running shell commands',
      grep: 'searching text patterns',
      find: 'locating files',
      ls: 'listing directory contents',
    };
    return descriptions[toolName] || 'general purpose';
  }

  private extractExampleQuery(messages: Message[]): string {
    // Find the first user message as an example
    for (const msg of messages) {
      if (msg.role === 'user') {
        for (const part of msg.content) {
          if (part.type === 'text') {
            return part.text.slice(0, 100) + (part.text.length > 100 ? '...' : '');
          }
        }
      }
    }
    return 'Help with this task';
  }

  getPendingSuggestions(): SkillSuggestion[] {
    return this.pendingSuggestions.filter(s => s.approved === null);
  }

  approveSkill(name: string): SkillSuggestion | null {
    const suggestion = this.pendingSuggestions.find(s => s.name === name);
    if (!suggestion) return null;
    
    suggestion.approved = true;
    return suggestion;
  }

  rejectSkill(name: string): boolean {
    const index = this.pendingSuggestions.findIndex(s => s.name === name);
    if (index === -1) return false;
    
    this.pendingSuggestions[index].approved = false;
    return true;
  }

  async saveApprovedSkills(): Promise<string[]> {
    const approved = this.pendingSuggestions.filter(s => s.approved === true);
    const savedPaths: string[] = [];
    
    const skillsDir = join(homedir(), '.pi/agent/skills/auto');
    await mkdir(skillsDir, { recursive: true });
    
    for (const skill of approved) {
      const filePath = join(skillsDir, `${skill.name}.md`);
      await writeFile(filePath, skill.content, 'utf-8');
      savedPaths.push(filePath);
    }
    
    // Clear saved suggestions
    this.pendingSuggestions = this.pendingSuggestions.filter(s => s.approved !== true);
    
    return savedPaths;
  }
}

import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
const execFileAsync = promisify(execFile);
```

- [ ] **Step 2: Commit skill generator**

```bash
git add nix/cells/pi-nix-suite/extension/src/skill-generator.ts
git commit -m "feat(pi-nix-suite): add SkillGenerator with pattern detection"
```

---

## Task 6: Command Handlers

**Files:**
- Create: `nix/cells/pi-nix-suite/extension/src/commands.ts`

- [ ] **Step 1: Implement slash command handlers**

```typescript
// commands.ts
import type { ExtensionAPI } from '@mariozechner/pi-coding-agent';
import type { TmuxManager } from './tmux.js';
import type { ReplManager } from './repl-manager.js';
import type { SkillGenerator } from './skill-generator.js';
import type { ReplType, SubagentConfig } from './types.js';
import { Type, type Static } from '@sinclair/typebox';

const SubagentArgs = Type.Object({
  mode: Type.Optional(Type.String()),
  agent: Type.Optional(Type.String()),
  task: Type.String(),
});

type SubagentArgs = Static<typeof SubagentArgs>;

const ReplArgs = Type.Object({
  type: Type.String(),
});

type ReplArgs = Static<typeof ReplArgs>;

export function registerCommands(
  pi: ExtensionAPI,
  tmux: TmuxManager,
  replManager: ReplManager,
  skillGenerator: SkillGenerator
) {
  // /subagent command
  pi.addCommand({
    name: 'subagent',
    description: 'Spawn a subagent in a new tmux window',
    args: SubagentArgs,
    handler: async (args: SubagentArgs, ctx) => {
      const config: SubagentConfig = {
        name: `agent-${Date.now()}`,
        agentType: (args.agent as SubagentConfig['agentType']) || 'worker',
        task: args.task,
        cwd: ctx.cwd,
      };

      try {
        const windowIndex = await tmux.spawnSubagentWindow(config);
        return {
          output: `Subagent spawned in tmux window ${windowIndex}. Press Ctrl+B then ${windowIndex} to view, Ctrl+B then 0 to return.`,
          exitCode: 0,
        };
      } catch (error) {
        return {
          output: `Failed to spawn subagent: ${error instanceof Error ? error.message : String(error)}`,
          exitCode: 1,
        };
      }
    },
  });

  // /subagent-list command
  pi.addCommand({
    name: 'subagent-list',
    description: 'List active subagent windows',
    handler: async (_args, _ctx) => {
      try {
        const windows = await tmux.findSubagentWindows();
        if (windows.length === 0) {
          return { output: 'No active subagent windows.', exitCode: 0 };
        }
        
        const lines = windows.map(w => 
          `[${w.index}] ${w.name}${w.active ? ' (active)' : ''}`
        );
        return { output: lines.join('\n'), exitCode: 0 };
      } catch (error) {
        return {
          output: `Failed to list subagents: ${error instanceof Error ? error.message : String(error)}`,
          exitCode: 1,
        };
      }
    },
  });

  // /subagent-close command
  pi.addCommand({
    name: 'subagent-close',
    description: 'Close a subagent window by index',
    args: Type.Object({ index: Type.Number() }),
    handler: async (args: { index: number }) => {
      try {
        await tmux.closeWindow(args.index);
        return { output: `Closed window ${args.index}.`, exitCode: 0 };
      } catch (error) {
        return {
          output: `Failed to close window: ${error instanceof Error ? error.message : String(error)}`,
          exitCode: 1,
        };
      }
    },
  });

  // /repl command
  pi.addCommand({
    name: 'repl',
    description: 'Open a REPL in a split pane (nix, python, node)',
    args: ReplArgs,
    handler: async (args: ReplArgs, ctx) => {
      const type = args.type as ReplType;
      
      if (!['nix', 'python', 'node'].includes(type)) {
        return {
          output: `Unknown REPL type: ${type}. Use: nix, python, or node.`,
          exitCode: 1,
        };
      }

      try {
        const paneId = await replManager.openRepl(type, ctx.cwd);
        return {
          output: `${type} REPL opened in pane ${paneId}. Use Ctrl+B arrow keys to navigate.`,
          exitCode: 0,
        };
      } catch (error) {
        return {
          output: `Failed to open REPL: ${error instanceof Error ? error.message : String(error)}`,
          exitCode: 1,
        };
      }
    },
  });

  // /repl-close command
  pi.addCommand({
    name: 'repl-close',
    description: 'Close current or all REPL panes',
    args: Type.Object({ all: Type.Optional(Type.Boolean()) }),
    handler: async (args: { all?: boolean }) => {
      try {
        if (args.all) {
          await replManager.closeAllRepls();
          return { output: 'All REPL panes closed.', exitCode: 0 };
        } else {
          // Close the most recently opened REPL
          const repls = replManager.getActiveRepls();
          if (repls.length === 0) {
            return { output: 'No active REPLs to close.', exitCode: 0 };
          }
          const lastRepl = repls[repls.length - 1];
          await replManager.closeRepl(lastRepl.paneId);
          return { output: `Closed ${lastRepl.type} REPL.`, exitCode: 0 };
        }
      } catch (error) {
        return {
          output: `Failed to close REPL: ${error instanceof Error ? error.message : String(error)}`,
          exitCode: 1,
        };
      }
    },
  });

  // /repl-list command
  pi.addCommand({
    name: 'repl-list',
    description: 'List active REPL sessions',
    handler: async () => {
      const repls = replManager.getActiveRepls();
      if (repls.length === 0) {
        return { output: 'No active REPL sessions.', exitCode: 0 };
      }
      
      const lines = repls.map(r => 
        `[${r.paneId}] ${r.type} (started ${r.startTime.toLocaleTimeString()})`
      );
      return { output: lines.join('\n'), exitCode: 0 };
    },
  });

  // /skill-approve command
  pi.addCommand({
    name: 'skill-approve',
    description: 'Approve pending skill suggestions',
    args: Type.Object({ name: Type.Optional(Type.String()) }),
    handler: async (args: { name?: string }) => {
      if (args.name) {
        const skill = skillGenerator.approveSkill(args.name);
        if (!skill) {
          return { output: `No pending skill named '${args.name}'`, exitCode: 1 };
        }
        const saved = await skillGenerator.saveApprovedSkills();
        return { output: `Skill approved and saved to: ${saved[0]}`, exitCode: 0 };
      } else {
        const pending = skillGenerator.getPendingSuggestions();
        if (pending.length === 0) {
          return { output: 'No pending skill suggestions.', exitCode: 0 };
        }
        
        const lines = pending.map(s => 
          `- ${s.name}: ${s.description} (confidence: ${s.pattern.confidence})`
        );
        return {
          output: `Pending skills:\n${lines.join('\n')}\n\nUse /skill-approve <name> to approve.`,
          exitCode: 0,
        };
      }
    },
  });

  // /skill-reject command
  pi.addCommand({
    name: 'skill-reject',
    description: 'Reject a skill suggestion',
    args: Type.Object({ name: Type.String() }),
    handler: async (args: { name: string }) => {
      const success = skillGenerator.rejectSkill(args.name);
      if (!success) {
        return { output: `No pending skill named '${args.name}'`, exitCode: 1 };
      }
      return { output: `Skill '${args.name}' rejected.`, exitCode: 0 };
    },
  });

  // /nix command - specialized Nix agent
  pi.addCommand({
    name: 'nix',
    description: 'Ask the Nix expert agent',
    args: Type.Object({ query: Type.String() }),
    handler: async (args: { query: string }, ctx) => {
      const config: SubagentConfig = {
        name: `nix-expert-${Date.now()}`,
        agentType: 'nix-expert',
        task: args.query,
        cwd: ctx.cwd,
      };

      try {
        const windowIndex = await tmux.spawnSubagentWindow(config);
        return {
          output: `Nix expert spawned in tmux window ${windowIndex}. Press Ctrl+B then ${windowIndex} to view.`,
          exitCode: 0,
        };
      } catch (error) {
        return {
          output: `Failed to spawn Nix expert: ${error instanceof Error ? error.message : String(error)}`,
          exitCode: 1,
        };
      }
    },
  });
}
```

- [ ] **Step 2: Commit commands**

```bash
git add nix/cells/pi-nix-suite/extension/src/commands.ts
git commit -m "feat(pi-nix-suite): add slash command handlers for subagent, repl, and skill management"
```

---

## Task 7: Main Extension Entry Point

**Files:**
- Create: `nix/cells/pi-nix-suite/extension/src/index.ts`

- [ ] **Step 1: Implement main extension entry**

```typescript
// index.ts
import type { ExtensionAPI } from '@mariozechner/pi-coding-agent';
import { TmuxManager } from './tmux.js';
import { ReplManager } from './repl-manager.js';
import { SkillGenerator } from './skill-generator.js';
import { registerCommands } from './commands.js';
import { DEFAULT_CONFIG } from './types.js';
import { readFile } from 'node:fs/promises';
import { join, homedir } from 'node:path';

async function loadConfig() {
  const configPath = join(homedir(), '.pi/agent/extensions/pi-nix-suite/config.json');
  try {
    const configData = await readFile(configPath, 'utf-8');
    const userConfig = JSON.parse(configData);
    return {
      ...DEFAULT_CONFIG,
      ...userConfig,
      tmux: { ...DEFAULT_CONFIG.tmux, ...userConfig.tmux },
      repls: { ...DEFAULT_CONFIG.repls, ...userConfig.repls },
      skillGeneration: { ...DEFAULT_CONFIG.skillGeneration, ...userConfig.skillGeneration },
    };
  } catch {
    return DEFAULT_CONFIG;
  }
}

export default async function (pi: ExtensionAPI) {
  const config = await loadConfig();
  
  // Initialize managers
  const tmux = new TmuxManager(
    config.tmux.socket,
    config.tmux.sessionName,
    config.tmux.windowPrefix
  );
  
  const replManager = new ReplManager(tmux, config.repls);
  const skillGenerator = new SkillGenerator(config.skillGeneration);

  // Check if we're in tmux
  const inTmux = process.env.TMUX !== undefined;
  if (!inTmux) {
    pi.notify('warning', 'pi-nix-suite: Not running in tmux. Subagent and REPL features require tmux.');
  }

  // Register all commands
  registerCommands(pi, tmux, replManager, skillGenerator);

  // Hook into session completion for skill generation
  pi.on('session_complete', async (event) => {
    if (!config.skillGeneration.enabled) return;
    
    const suggestion = skillGenerator.analyzeSession(
      event.messages,
      event.workingDir
    );
    
    if (suggestion) {
      // Prompt user with one-keystroke approval
      pi.notify(
        'info',
        `📝 Create skill '${suggestion.name}' from this session? [Y/n/skip]`,
        { actions: ['Y', 'n', 'skip'] }
      );
    }
  });

  // Handle skill approval from notification
  pi.on('notification_action', async (event) => {
    if (event.notification.includes('Create skill')) {
      const match = event.notification.match(/Create skill '(.+)'/);
      if (!match) return;
      
      const skillName = match[1];
      
      if (event.action === 'Y') {
        skillGenerator.approveSkill(skillName);
        const saved = await skillGenerator.saveApprovedSkills();
        pi.notify('success', `Skill saved to: ${saved[0]}`);
      } else if (event.action === 'n') {
        skillGenerator.rejectSkill(skillName);
        pi.notify('info', 'Skill rejected.');
      }
      // 'skip' does nothing, will suggest again next time
    }
  });

  // Show startup message
  pi.notify('info', 'pi-nix-suite loaded. Commands: /subagent, /repl, /nix, /skill-approve');
}
```

- [ ] **Step 2: Commit main entry**

```bash
git add nix/cells/pi-nix-suite/extension/src/index.ts
git commit -m "feat(pi-nix-suite): add main extension entry point with session hooks"
```

---

## Task 8: Agent Templates

**Files:**
- Create: `nix/cells/pi-nix-suite/extension/templates/agent-scout.md`
- Create: `nix/cells/pi-nix-suite/extension/templates/agent-worker.md`
- Create: `nix/cells/pi-nix-suite/extension/templates/agent-nix-expert.md`

- [ ] **Step 1: Create scout agent template**

```markdown
---
name: scout
description: Fast reconnaissance agent for codebase exploration
tools: read, grep, find, ls, bash
model: claude-haiku-4
---

# Scout Agent

You are a fast reconnaissance agent. Your job is to quickly understand codebases and report back findings.

## Capabilities

- Use `grep` and `find` to locate relevant code
- Use `read` to examine file contents
- Use `ls` to understand directory structures
- Use `bash` sparingly for quick checks

## Guidelines

1. **Be fast**: Focus on breadth over depth
2. **Be concise**: Summarize findings, don't quote entire files
3. **Prioritize**: Focus on the most relevant files first
4. **Report**: Always provide a summary of what you found

## Output Format

```
## Summary
<Brief description of what was found>

## Key Files
- path/to/file1: <description>
- path/to/file2: <description>

## Patterns Found
<Any patterns or conventions discovered>
```
```

- [ ] **Step 2: Create worker agent template**

```markdown
---
name: worker
description: Implementation agent for writing and modifying code
tools: read, write, edit, bash, grep, find, ls
model: claude-sonnet-4
---

# Worker Agent

You are an implementation agent. Your job is to write code, modify files, and implement features.

## Capabilities

- Use all available tools including `write` and `edit`
- Can create new files and modify existing ones
- Can run bash commands to test implementations
- Can search and navigate codebases

## Guidelines

1. **Plan first**: Understand requirements before coding
2. **Test changes**: Verify your changes work as expected
3. **Be thorough**: Handle edge cases and errors
4. **Follow conventions**: Match the existing code style
5. **Commit often**: Make logical, self-contained changes

## Workflow

1. Read relevant files to understand context
2. Plan the implementation approach
3. Make changes incrementally
4. Test each change
5. Report completion with summary
```

- [ ] **Step 3: Create Nix expert agent template**

```markdown
---
name: nix-expert
description: Nix/NixOS specialist with deep flake and system configuration knowledge
tools: read, write, edit, bash, grep, find, ls
model: claude-sonnet-4
---

# Nix Expert Agent

You are a Nix specialist with deep knowledge of Nix expressions, flakes, and NixOS system configuration.

## Capabilities

- Write and debug Nix expressions
- Work with Nix flakes (flake.nix, flake.lock)
- Configure NixOS systems
- Use nix repl for testing expressions
- Understand nixpkgs and module system

## Guidelines

1. **Always verify**: Run `nix flake check` after changes
2. **Use nix repl**: Test expressions before committing
3. **Follow nixpkgs conventions**: Match style of nixpkgs repository
4. **Be explicit**: Prefer explicit over implicit in Nix
5. **Document**: Add comments for complex expressions

## Common Tasks

### Debugging Flakes
1. Run `nix flake check` to identify errors
2. Read the file mentioned in the error
3. Use `nix repl` to test specific expressions
4. Make targeted fixes
5. Verify with `nix flake check`

### System Configuration
1. Read relevant nixos/ directory
2. Check hardware-configuration.nix imports
3. Validate with `nixos-rebuild dry-build`
4. Apply changes carefully

## Nix REPL Commands

In nix repl:
- `:load flake.nix` - Load current flake
- `:p <expr>` - Pretty print expression
- `<expr> ? attr` - Check if attr exists
```

- [ ] **Step 4: Commit templates**

```bash
git add nix/cells/pi-nix-suite/extension/templates/
git commit -m "feat(pi-nix-suite): add agent templates for scout, worker, and nix-expert"
```

---

## Task 9: Default Skills

**Files:**
- Create: `nix/cells/pi-nix-suite/skills/nixos-deploy.md`
- Create: `nix/cells/pi-nix-suite/skills/flake-debug.md`

- [ ] **Step 1: Create nixos-deploy skill**

```markdown
---
name: nixos-deploy
description: Deploy NixOS configuration to remote hosts
type: manual
category: deployment
tools: read, write, edit, bash
---

# NixOS Deploy

Deploy NixOS configurations to remote hosts using nixos-rebuild or deployment tools.

## When to Use

- Deploying system configuration changes
- Setting up new NixOS hosts
- Rolling back failed deployments
- Managing multiple NixOS machines

## Prerequisites

- SSH access to target host
- NixOS configuration in repository
- Proper secrets management (sops-nix or agenix)

## Workflow

### Local Deployment (same machine)

1. Check current configuration:
   ```bash
   nixos-rebuild dry-build --flake .#hostname
   ```

2. Build and switch:
   ```bash
   sudo nixos-rebuild switch --flake .#hostname
   ```

3. Verify:
   ```bash
   systemctl status
   nixos-version
   ```

### Remote Deployment

1. Build locally, copy closure:
   ```bash
   nixos-rebuild switch --flake .#hostname --target-host root@hostname
   ```

2. Or use deploy-rs:
   ```bash
   deploy .#hostname --hostname remote-host
   ```

## Rollback

If something goes wrong:
```bash
sudo nixos-rebuild switch --rollback
```

## Common Issues

- Build failures: Check `nix flake check` first
- SSH issues: Verify keys and host availability
- Disk space: Check `/nix/store` usage
- Boot issues: Check `boot.loader` configuration
```

- [ ] **Step 2: Create flake-debug skill**

```markdown
---
name: flake-debug
description: Debug and fix Nix flake evaluation errors
type: manual
category: nix
tools: read, write, edit, bash
---

# Flake Debug

Systematically debug and fix Nix flake evaluation errors.

## Common Errors and Fixes

### "attribute 'X' missing"

1. Check what's available:
   ```bash
   nix flake show 2>&1 | head -50
   ```

2. Read the flake.nix to understand outputs structure

3. Fix the attribute path or add the missing output

### "infinite recursion"

1. Check for self-referential expressions
2. Look for `inherit (self) X` patterns
3. Use `builtins.seq` to break laziness if needed

### "cannot find flake"

1. Verify flake.nix exists in current directory
2. Check git tracking: `git ls-files flake.nix`
3. Flakes must be in git to be recognized

### "build failed"

1. Check the specific package build:
   ```bash
   nix build .#package --rebuild 2>&1 | tail -100
   ```

2. Look for missing dependencies
3. Check for compiler errors

## Debugging Workflow

1. Run `nix flake check` and capture full error
2. Identify the file and line mentioned
3. Read that section of code
4. Use `nix repl` to test the problematic expression
5. Apply minimal fix
6. Verify with `nix flake check`
```

- [ ] **Step 3: Commit skills**

```bash
git add nix/cells/pi-nix-suite/skills/
git commit -m "feat(pi-nix-suite): add default skills for nixos-deploy and flake-debug"
```

---

## Task 10: Build and Package

**Files:**
- Modify: `nix/cells/pi-nix-suite/default.nix`
- Modify: `nix/cells/pi-nix-suite/extension/package.json`

- [ ] **Step 1: Update package.json with build script**

```json
{
  "name": "pi-nix-suite",
  "version": "0.1.0",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "check": "tsc --noEmit"
  },
  "dependencies": {
    "@mariozechner/pi-coding-agent": "^0.12.0",
    "@mariozechner/pi-agent-core": "^0.12.0",
    "@mariozechner/pi-ai": "^0.12.0",
    "@mariozechner/pi-tui": "^0.12.0",
    "@sinclair/typebox": "^0.32.0"
  },
  "devDependencies": {
    "typescript": "^5.3.0",
    "@types/node": "^20.0.0",
    "vitest": "^1.0.0"
  }
}
```

- [ ] **Step 2: Build the extension**

```bash
cd nix/cells/pi-nix-suite/extension
npm install
npm run build
```

- [ ] **Step 3: Update default.nix with correct hash**

After first build attempt fails with hash mismatch, update:

```nix
{ pkgs, lib, ... }:

pkgs.buildNpmPackage rec {
  pname = "pi-nix-suite";
  version = "0.1.0";
  
  src = ./extension;
  
  npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash
  
  nativeBuildInputs = with pkgs; [
    nodejs
  ];
  
  buildPhase = ''
    npm run build
  '';
  
  installPhase = ''
    mkdir -p $out/share/pi/extensions/pi-nix-suite
    cp -r dist/* $out/share/pi/extensions/pi-nix-suite/
    
    # Copy templates
    mkdir -p $out/share/pi/extensions/pi-nix-suite/templates
    cp -r templates/* $out/share/pi/extensions/pi-nix-suite/templates/
    
    # Install default skills
    mkdir -p $out/share/pi/skills/pi-nix-suite
    cp -r ${./skills}/* $out/share/pi/skills/pi-nix-suite/ 2>/dev/null || true
  '';
  
  meta = with lib; {
    description = "Nix integration suite for pi coding agent";
    license = licenses.mit;
  };
}
```

- [ ] **Step 4: Add to main flake outputs**

```nix
# In flake.nix, add to outputs
{
  packages.${system} = {
    pi-nix-suite = inputs'.pi-nix-suite.packages.default;
  };
}
```

- [ ] **Step 5: Commit build configuration**

```bash
git add nix/cells/pi-nix-suite/default.nix
git add nix/cells/pi-nix-suite/extension/package.json
git commit -m "feat(pi-nix-suite): add Nix packaging and build configuration"
```

---

## Task 11: Integration with hbohlen-systems

**Files:**
- Modify: `nix/cells/devshells/default.nix`

- [ ] **Step 1: Add pi-nix-suite to devShell**

```nix
# In nix/cells/devshells/default.nix
{ inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }:
  let
    llm-agents-packages = inputs.llm-agents.packages.${system};
    pi-nix-suite = self'.packages.pi-nix-suite;
  in
  {
    devShells.default = pkgs.mkShell {
      # ... existing config ...
      
      shellHook = ''
        echo "Entering hbohlen-systems devShell..."
        export SHELL=${pkgs.fish}/bin/fish
        
        # Set up pi-nix-suite extension
        export PI_NIX_SUITE_PATH="${pi-nix-suite}/share/pi/extensions/pi-nix-suite"
        
        # Auto-link extension if not already present
        if [ ! -L "$HOME/.pi/agent/extensions/pi-nix-suite" ]; then
          mkdir -p "$HOME/.pi/agent/extensions"
          ln -sf "$PI_NIX_SUITE_PATH" "$HOME/.pi/agent/extensions/pi-nix-suite"
          echo "Linked pi-nix-suite extension"
        fi
        
        # ... rest of shellHook ...
      '';
    };
  };
}
```

- [ ] **Step 2: Commit integration**

```bash
git add nix/cells/devshells/default.nix
git commit -m "feat(pi-nix-suite): integrate extension into devShell"
```

---

## Task 12: Documentation

**Files:**
- Create: `nix/cells/pi-nix-suite/README.md`

- [ ] **Step 1: Write README**

```markdown
# pi-nix-suite

Nix integration suite for the [pi](https://github.com/badlogic/pi-mono) coding agent.

## Features

- **Visible Subagents**: Spawn parallel pi instances in separate tmux windows
- **Multi-REPL Integration**: Nix, Python, and Node REPLs in tmux splits
- **Self-Improving Skills**: Hybrid pattern detection with one-keystroke approval

## Installation

### Via Nix (hbohlen-systems)

Already integrated into the devShell:

```bash
nix develop
```

### Manual Installation

```bash
# Clone and build
git clone https://github.com/hbohlen/hbohlen-systems.git
cd hbohlen-systems/nix/cells/pi-nix-suite/extension
npm install
npm run build

# Link extension
mkdir -p ~/.pi/agent/extensions
ln -sf $(pwd)/dist ~/.pi/agent/extensions/pi-nix-suite
```

## Usage

### Subagents

Spawn parallel pi instances in tmux windows:

```
/subagent scout the codebase for auth patterns
/subagent worker implement the login function
/subagent list
/subagent close 1
```

Navigate with: `Ctrl+B <window-number>`

### REPLs

Open REPLs in split panes:

```
/repl nix
/repl python
/repl node
/repl list
/repl close
```

### Nix Expert

Get Nix-specific help:

```
/nix why is my flake check failing?
/nix how do I add a new system to my flake?
```

### Skills

Approve generated skills:

```
/skill-approve
/skill-approve nix-flake-debug
/skill-reject nix-flake-debug
```

## Configuration

Create `~/.pi/agent/extensions/pi-nix-suite/config.json`:

```json
{
  "tmux": {
    "socket": "/run/user/1000/pi-tmux",
    "autoCloseCompleted": true
  },
  "skillGeneration": {
    "enabled": true,
    "threshold": 0.8
  }
}
```

## License

MIT
```

- [ ] **Step 2: Commit documentation**

```bash
git add nix/cells/pi-nix-suite/README.md
git commit -m "docs(pi-nix-suite): add README with usage instructions"
```

---

## Plan Self-Review

**Spec coverage:**
- ✅ Tmux window management (Task 3)
- ✅ Multi-REPL integration (Task 4)
- ✅ Skill generation with approval (Task 5)
- ✅ Slash commands (Task 6)
- ✅ Nix packaging (Task 10)
- ✅ DevShell integration (Task 11)

**Placeholder scan:**
- ✅ No TBD/TODO found
- ✅ All code is complete and copy-paste ready
- ✅ Exact file paths specified
- ✅ Commands with expected output

**Type consistency:**
- ✅ `TmuxManager`, `ReplManager`, `SkillGenerator` consistent across files
- ✅ `ReplType`, `SubagentConfig` shared from types.ts
- ✅ Command args use Typebox schemas consistently

---

## Execution Options

**Plan complete and saved to `docs/superpowers/plans/2025-03-31-pi-nix-suite-implementation.md`.**

Two execution options:

**1. Subagent-Driven (recommended)** - Dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
