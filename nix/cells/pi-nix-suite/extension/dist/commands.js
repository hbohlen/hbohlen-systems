export function registerCommands(pi, tmux, replManager, skillGenerator) {
    // /subagent command
    pi.addCommand({
        name: 'subagent',
        description: 'Spawn a subagent in a new tmux window',
        args: {
            agent: { type: 'string', required: false },
            task: { type: 'string', required: true },
        },
        handler: async (args, ctx) => {
            const config = {
                name: `agent-${Date.now()}`,
                agentType: args.agent || 'worker',
                task: args.task,
                cwd: ctx.cwd,
            };
            try {
                const windowIndex = await tmux.spawnSubagentWindow(config);
                return {
                    output: `Subagent spawned in tmux window ${windowIndex}. Press Ctrl+B then ${windowIndex} to view, Ctrl+B then 0 to return.`,
                    exitCode: 0,
                };
            }
            catch (error) {
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
                const lines = windows.map(w => `[${w.index}] ${w.name}${w.active ? ' (active)' : ''}`);
                return { output: lines.join('\n'), exitCode: 0 };
            }
            catch (error) {
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
        args: {
            index: { type: 'number', required: true },
        },
        handler: async (args) => {
            try {
                await tmux.closeWindow(args.index);
                return { output: `Closed window ${args.index}.`, exitCode: 0 };
            }
            catch (error) {
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
        args: {
            type: { type: 'string', required: true },
        },
        handler: async (args, ctx) => {
            const type = args.type;
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
            }
            catch (error) {
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
        args: {
            all: { type: 'boolean', required: false },
        },
        handler: async (args) => {
            try {
                if (args.all) {
                    await replManager.closeAllRepls();
                    return { output: 'All REPL panes closed.', exitCode: 0 };
                }
                else {
                    // Close the most recently opened REPL
                    const repls = replManager.getActiveRepls();
                    if (repls.length === 0) {
                        return { output: 'No active REPLs to close.', exitCode: 0 };
                    }
                    const lastRepl = repls[repls.length - 1];
                    await replManager.closeRepl(lastRepl.paneId);
                    return { output: `Closed ${lastRepl.type} REPL.`, exitCode: 0 };
                }
            }
            catch (error) {
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
            const lines = repls.map(r => `[${r.paneId}] ${r.type} (started ${r.startTime.toLocaleTimeString()})`);
            return { output: lines.join('\n'), exitCode: 0 };
        },
    });
    // /skill-approve command
    pi.addCommand({
        name: 'skill-approve',
        description: 'Approve pending skill suggestions',
        args: {
            name: { type: 'string', required: false },
        },
        handler: async (args) => {
            if (args.name) {
                const skill = skillGenerator.approveSkill(args.name);
                if (!skill) {
                    return { output: `No pending skill named '${args.name}'`, exitCode: 1 };
                }
                const saved = await skillGenerator.saveApprovedSkills();
                return { output: `Skill approved and saved to: ${saved[0]}`, exitCode: 0 };
            }
            else {
                const pending = skillGenerator.getPendingSuggestions();
                if (pending.length === 0) {
                    return { output: 'No pending skill suggestions.', exitCode: 0 };
                }
                const lines = pending.map(s => `- ${s.name}: ${s.description} (confidence: ${s.pattern.confidence})`);
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
        args: {
            name: { type: 'string', required: true },
        },
        handler: async (args) => {
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
        args: {
            query: { type: 'string', required: true },
        },
        handler: async (args, ctx) => {
            const config = {
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
            }
            catch (error) {
                return {
                    output: `Failed to spawn Nix expert: ${error instanceof Error ? error.message : String(error)}`,
                    exitCode: 1,
                };
            }
        },
    });
}
//# sourceMappingURL=commands.js.map