import type { ExtensionAPI } from '@mariozechner/pi-coding-agent';
import { TmuxManager } from './tmux.js';
import { ReplManager } from './repl-manager.js';
import { SkillGenerator } from './skill-generator.js';
import { registerCommands } from './commands.js';
import { DEFAULT_CONFIG } from './types.js';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';

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

interface SessionCompleteEvent {
  messages: Message[];
  workingDir: string;
}

interface NotificationActionEvent {
  notification: string;
  action: string;
}

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
  
  // Resolve socket path with environment variable
  const socketPath = config.tmux.socket.replace('${XDG_RUNTIME_DIR}', process.env.XDG_RUNTIME_DIR || '/tmp');
  
  // Initialize managers
  const tmux = new TmuxManager(
    socketPath,
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
  pi.on('session_complete', async (event: SessionCompleteEvent) => {
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
  pi.on('notification_action', async (event: NotificationActionEvent) => {
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
