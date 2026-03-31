// types.ts
export const DEFAULT_CONFIG = {
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
//# sourceMappingURL=types.js.map