import type { DetectedPattern, SkillSuggestion, ReplType } from './types.js';
import { writeFile, mkdir, readdir } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';

// Simplified message type for pattern detection
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

interface ToolCall {
  name: string;
  arguments: Record<string, unknown>;
}

export class SkillGenerator {
  private config: {
    enabled: boolean;
    threshold: number;
    autoSave: boolean;
    maxSuggestionsPerSession: number;
    categories: string[];
  };
  private pendingSuggestions: SkillSuggestion[] = [];
  private savedSkillsDir: string;

  constructor(config: SkillGenerator['config']) {
    this.config = config;
    this.savedSkillsDir = join(homedir(), '.pi/agent/skills/auto');
  }

  analyzeSession(messages: Message[], workingDir: string): SkillSuggestion | null {
    if (!this.config.enabled) return null;
    if (this.pendingSuggestions.length >= this.config.maxSuggestionsPerSession) return null;

    const pattern = this.detectPattern(messages, workingDir);
    if (!pattern || pattern.confidence < this.config.threshold) return null;

    // Check if we already have a pending or saved suggestion for this pattern
    const existingPending = this.pendingSuggestions.find(s => s.pattern.name === pattern.name);
    if (existingPending) return null;

    // Check if skill already exists
    const alreadySaved = this.checkSkillExists(pattern.name);
    if (alreadySaved) return null;

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

  private async checkSkillExists(name: string): Promise<boolean> {
    try {
      const files = await readdir(this.savedSkillsDir);
      return files.some(f => f === `${name}.md`);
    } catch {
      return false;
    }
  }

  detectPattern(messages: Message[], workingDir: string): DetectedPattern | null {
    const toolCalls: ToolCall[] = [];
    const filesTouched = new Set<string>();
    const keywords = new Set<string>();

    // Extract tool calls and file patterns from messages
    for (const msg of messages) {
      if (msg.role === 'assistant') {
        for (const part of msg.content) {
          if (part.type === 'toolCall' && part.name) {
            toolCalls.push({
              name: part.name,
              arguments: part.arguments || {}
            });
            keywords.add(part.name);
            
            // Extract file paths from tool arguments
            const args = part.arguments || {};
            if (args.file_path) filesTouched.add(args.file_path as string);
            if (args.path) filesTouched.add(args.path as string);
          }
          if (part.type === 'text' && part.text) {
            // Extract keywords from text
            const text = part.text.toLowerCase();
            if (text.includes('nix')) keywords.add('nix');
            if (text.includes('flake')) keywords.add('flake');
            if (text.includes('deploy')) keywords.add('deploy');
            if (text.includes('python')) keywords.add('python');
            if (text.includes('node') || text.includes('npm')) keywords.add('node');
            if (text.includes('build')) keywords.add('build');
            if (text.includes('test')) keywords.add('test');
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

    // Pattern: General build/test workflow
    if (keywords.has('build') || keywords.has('test')) {
      return {
        name: 'build-and-test',
        description: 'Build project and run tests',
        toolSequence: [...new Set(toolSequence)],
        filePatterns: [...new Set(filePatterns)],
        keywords: ['build', 'test', 'check'],
        confidence: 0.75,
        category: 'general',
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
          if (part.type === 'text' && part.text) {
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
    
    await mkdir(this.savedSkillsDir, { recursive: true });
    
    for (const skill of approved) {
      const filePath = join(this.savedSkillsDir, `${skill.name}.md`);
      await writeFile(filePath, skill.content, 'utf-8');
      savedPaths.push(filePath);
    }
    
    // Clear saved suggestions
    this.pendingSuggestions = this.pendingSuggestions.filter(s => s.approved !== true);
    
    return savedPaths;
  }
}
