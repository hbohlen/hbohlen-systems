# Initialize tools
starship init fish | source
zoxide init fish | source
direnv hook fish | source

# Git abbreviations
abbr -a g git
abbr -a gs 'git status'
abbr -a gd 'git diff'
abbr -a ga 'git add'
abbr -a gc 'git commit'
abbr -a gl 'git log --oneline -15'

# Navigation abbreviations
abbr -a l 'eza --icons --group-directories-first'
abbr -a ll 'eza -la --icons --group-directories-first'
abbr -a lt 'eza --tree --icons'

# Editor abbreviations
abbr -a n nvim

# Welcome message
echo "Welcome to {{PROJECT_NAME}} devShell"
