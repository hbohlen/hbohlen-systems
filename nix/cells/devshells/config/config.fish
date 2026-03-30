# hbohlen-systems devShell fish configuration
# This runs when entering the devShell

# Initialize starship prompt
if command -v starship > /dev/null
    starship init fish | source
end

# Initialize zoxide (smart cd)
if command -v zoxide > /dev/null
    zoxide init fish | source
end

# Initialize direnv
if command -v direnv > /dev/null
    direnv hook fish | source
end

# Abbreviations (expand on space, show full command)
# Git abbreviations
abbr -a g git
abbr -a gs 'git status'
abbr -a gd 'git diff'
abbr -a gds 'git diff --staged'
abbr -a ga 'git add'
abbr -a gaa 'git add -A'
abbr -a gc 'git commit'
abbr -a gcm 'git commit -m'
abbr -a gl 'git log --oneline -15'
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gco 'git checkout'
abbr -a gb 'git branch'

# Navigation abbreviations
abbr -a l 'eza --icons --group-directories-first'
abbr -a la 'eza -a --icons --group-directories-first'
abbr -a ll 'eza -la --icons --group-directories-first'
abbr -a lt 'eza --tree --icons'
abbr -a z 'z'

# Editor abbreviations
abbr -a n nvim
abbr -a v nvim

# Nix abbreviations
abbr -a ns 'nix develop'
abbr -a nb 'nix build'
abbr -a nr 'nix run'
abbr -a nf 'nix flake'

# Welcome message
echo "Welcome to hbohlen-systems devShell"
echo "Fish shell with starship, zoxide, and abbreviations ready"
echo "Type 'abbr -a' to see all abbreviations"
