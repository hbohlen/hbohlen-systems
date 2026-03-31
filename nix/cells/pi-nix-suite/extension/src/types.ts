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
