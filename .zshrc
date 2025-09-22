# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
#PATH=/usr/bin:/bin:/usr/sbin:/sbin
#export PATH

# Add Homebrew to PATH (if not already present)
[[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# add custom, local installations to PATH
#PATH=/usr/local/bin:/usr/local/sbin:"$PATH"

# add MacPorts to PATH
#PATH=/opt/local/bin:/opt/local/sbin:"$PATH"
#export GOPATH=/Users/erictran/codebase/golang
# export PATH=~/Library/Python/2.7/bin:$PATH

# Path to your oh-my-zsh installation.
ZSH_DISABLE_COMPFIX=true
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"


alias awsume=". awsume"

alias gitb="git branch | grep '^\*' | cut -d' ' -f2 | pbcopy"
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"

# functions
function aoc() {
  touch ~/codebase/aoc/2021/day_${1}.py
  touch ~/codebase/aoc/2021/day_${1}_input.txt
  if [ -z "${AOC_SESSION:-}" ]; then echo "Set AOC_SESSION env var with your Advent of Code session cookie." >&2; return 1; fi
  curl -b "session=${AOC_SESSION}" "https://adventofcode.com/2021/day/${1}/input" > "$HOME/codebase/aoc/2021/day_${1}_input.txt"
}

function test() {
  if [ $1 == "hi" ];
  then echo "what";
  else echo "ahh";
  fi
}

# longer aws sessions
# awsume PROFILENAME -a
# awsume PROFILENAME --role-duration 14400

# profiles per window
# awsume --config set console.browser_command "\"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome\" -incognito \"{url}\" --user-data-dir=/tmp/{profile} --no-first-run"

# Source external function definitions
[ -f "$HOME/.config/zsh/functions" ] && source "$HOME/.config/zsh/functions"

# Prefer Homebrew (ARM) PHP if available; otherwise fallback to Intel path
if [ -d "/opt/homebrew/opt/php@7.4/bin" ]; then
  export PATH="/opt/homebrew/opt/php@7.4/bin:/opt/homebrew/opt/php@7.4/sbin:$PATH"
elif [ -d "/usr/local/opt/php@7.4/bin" ]; then
  export PATH="/usr/local/opt/php@7.4/bin:/usr/local/opt/php@7.4/sbin:$PATH"
fi

export PATH="/usr/sbin:$PATH"

### Quality of Life Aliases
# ==============================================================================
alias vim=nvim
alias cat=bat
alias cd=z
alias mkdir='mkdir -p'  # Create parent directories as needed
alias c='clear'          # Clear terminal screen
alias reload='source ~/.zshrc'  # Reload ZSH Configuration
alias fman="compgen -c | fzf | xargs man"
alias ssh-target='echo "eric.tran@$(ifconfig en0 | grep "inet " | grep -v 127.0.0.1 | awk "{print \$2}")"'  # Print SSH target with current IP

# ==============================================================================
# File System Aliases (using eza)
# ==============================================================================

# Enhanced eza commands (modern ls replacement)
alias ls='eza --icons=always --color=always'                    # Basic listing with icons
alias ll='eza --long --all --icons=always --no-user'            # Long format, all files, no user column
alias la='eza --all --icons=always'                             # All files including hidden
alias l='eza --icons=always'                                    # Same as ls (simple)
alias lt='eza --tree --icons=always --level=2'                  # Tree view (2 levels deep)

# ==============================================================================
# Git Aliases
# ==============================================================================

# Git operations
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gs='git status'
alias gl='git log'
alias gco='git checkout'
alias gd='git diff --color -b'
alias gdc='git diff --color -b --cached'
alias gdh='git diff --color -b HEAD~1 HEAD'
alias gf='git fetch origin'
alias gp='git push origin HEAD:refs/for/develop'
alias gr='git rebase'
alias grc='git rebase --continue'
alias grd='git rebase origin/develop-stable'
alias gfr='git fetch origin; git rebase origin/develop-stable'
alias ge='git clean -fd'
alias gm='git mergetool'
alias gb="git for-each-ref --format='%(color:cyan)%(authordate:format:%m/%d/%Y %I:%M %p)    %(align:25,left)%(color:yellow)%(authorname)%(end) %(color:reset)%(refname:strip=3)' --sort=authordate refs/remotes"
alias hlog='git log --date-order --all --graph --format="%C(green)%h %Creset%C(yellow)%an%Creset %C(blue bold)%ar%Creset %C(red bold)%d%Creset %s"'
alias gitb="git branch | grep '^\*' | cut -d' ' -f2 | pbcopy"

# ==============================================================================
# Custom Functions
# ==============================================================================

# Auto-tidy after go get
go() {
  if [[ "$1" == "get" ]]; then
    command go "$@" && go mod tidy
  else
    command go "$@"
  fi
}

# Ripgrep + fzf interactive search with syntax highlighting
# Usage: rgf "search_term"
function rgf() {
  rg --line-number --no-heading --color=always --with-filename "$1" | \
  awk -F: -v OFS=: '{printf "%-50s %4s: %s\n", $1, $2, substr($0, index($0, $3))}' | \
  fzf --ansi \
      --delimiter : \
      --nth 1,2 \
      --preview 'FILE=$(echo {} | awk "{print \$1}" | sed "s/[[:space:]]*$//"); LINE=$(echo {} | awk "{print \$2}" | tr -d ":"); /opt/homebrew/bin/bat --color=always --style=numbers --highlight-line $LINE "$FILE"' \
      --preview-window up:60% \
      --layout=reverse \
      --info=inline
}

# Function to find and open files using zoxide and fzf
# Usage: search_with_zoxdie [search_term] or nzo [search_term]
function search_with_zoxdie() {
    if [ -z "$1" ]; then
        # Use fd with fzf to select & open a file when no args are provided
        file="$(fd --type f --strip-cwd-prefix -I -H -E .git -E .git-crypt -E .cache -E .backup | xargs -I {} eza --icons=always --color=always {} | fzf --height=70% --ansi --preview='/opt/homebrew/bin//opt/homebrew/bin/bat -n --color=always --line-range :500 {+2..}')"
        if [ -n "$file" ]; then
            # Extract the actual filename (everything after the icon and space)
            actual_file=$(echo "$file" | sed 's/^[^ ]* //')
            nvim "$actual_file"
        fi
    else
        # Handle when an argument is provided - only search within current directory and subdirectories
        lines=$({ fd --type f -I -H -E .git -E .git-crypt -E .cache -E .backup -E .vscode "$1" .; zoxide query -l | while read -r dir; do if [ -d "$dir" ]; then case "$dir" in "$(pwd)"*) rel_dir="${dir#$(pwd)/}"; if [ "$rel_dir" != "$dir" ]; then fd --type f -I -H -E .git -E .git-crypt -E .cache -E .backup -E .vscode "$1" "$dir" | sed "s|^$dir/|$rel_dir/|" 2>/dev/null; fi ;; esac; fi; done; } | sort -u | xargs -I {} eza --icons=always --color=always {} | fzf --no-sort --height=70% --ansi --preview='/opt/homebrew/bin/bat -n --color=always --line-range :500 {+2..}')
        line_count="$(echo "$lines" | wc -l | xargs)"

        if [ -n "$lines" ] && [ "$line_count" -eq 1 ]; then
            actual_file=$(echo "$lines" | sed 's/^[^ ]* //')
            nvim "$actual_file"
        elif [ -n "$lines" ]; then
            file=$(echo "$lines" | fzf --query="$1" --height=70% --ansi --preview='/opt/homebrew/bin/bat -n --color=always --line-range :500 {+2..}')
            if [ -n "$file" ]; then
                actual_file=$(echo "$file" | sed 's/^[^ ]* //')
                nvim "$actual_file"
            fi
        else
            echo "No matches found." >&2
        fi
    fi
}

# Alias for zoxide file opener
alias nzo='search_with_zoxdie'

# Bypass version that shows ALL files (including ignored)
function search_with_zoxdie_bypass() {
    if [ -z "$1" ]; then
        file="$(fd --type f --strip-cwd-prefix --no-ignore -H | xargs -I {} eza --icons=always --color=always {} | fzf --height=70% --ansi --preview='/opt/homebrew/bin/bat -n --color=always --line-range :500 {+2..}')"
        if [ -n "$file" ]; then
            actual_file=$(echo "$file" | sed 's/^[^ ]* //')
            nvim "$actual_file"
        fi
    else
        lines=$({ fd --type f --no-ignore -H "$1" .; zoxide query -l | while read -r dir; do if [ -d "$dir" ]; then case "$dir" in "$(pwd)"*) rel_dir="${dir#$(pwd)/}"; if [ "$rel_dir" != "$dir" ]; then fd --type f --no-ignore -H "$1" "$dir" | sed "s|^$dir/|$rel_dir/|" 2>/dev/null; fi ;; esac; fi; done; } | sort -u | xargs -I {} eza --icons=always --color=always {} | fzf --no-sort --height=70% --ansi --preview='/opt/homebrew/bin/bat -n --color=always --line-range :500 {+2..}')
        line_count="$(echo "$lines" | wc -l | xargs)"
        if [ -n "$lines" ] && [ "$line_count" -eq 1 ]; then
            actual_file=$(echo "$lines" | sed 's/^[^ ]* //')
            nvim "$actual_file"
        elif [ -n "$lines" ]; then
            file=$(echo "$lines" | fzf --query="$1" --height=70% --ansi --preview='/opt/homebrew/bin/bat -n --color=always --line-range :500 {+2..}')
            if [ -n "$file" ]; then
                actual_file=$(echo "$file" | sed 's/^[^ ]* //')
                nvim "$actual_file"
            fi
        else
            echo "No matches found." >&2
        fi
    fi
}
alias nzo-all='search_with_zoxdie_bypass'

# Created by `pipx` on 2023-05-09 16:45:58
export PATH="$PATH:$HOME/.local/bin"

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Smart directory jumping (zoxide)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Source local, untracked overrides
[ -f "$HOME/.chime.sh" ] && source "$HOME/.chime.sh"
if [ -f "$HOME/.zshrc.chime" ]; then
  source "$HOME/.zshrc.chime"
fi

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-vi-mode hook to load fzf-git after vi-mode initializes
function zvm_after_init() {
  source ~/codebase/dotfiles/fzf-git.sh/fzf-git.sh
}

# Key bindings for autosuggestions
bindkey -e
bindkey '^I' autosuggest-accept

# FZF
eval "$(/opt/homebrew/bin/fzf --zsh)"
export FZF_DEFAULT_COMMAND="/opt/homebrew/bin/fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="/opt/homebrew/bin/fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Catppuccin Mocha theme for FZF
export FZF_DEFAULT_OPTS="--height 50% --layout=default --border \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6ac,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6ac,hl+:#f38ba8 \
--bind=ctrl-u:preview-up,ctrl-d:preview-down,ctrl-b:preview-page-up,ctrl-f:preview-page-down"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200' --preview-window=right:60%:wrap"

export FZF_TMUX_OPTS=" -p90%, 70% "

# Set FZF previews
export FZF_CTRL_T_OPTS="--preview '/opt/homebrew/bin/bat --color=always -n --line-range :500 {}'"
export FZF_ATC_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Remove broken list-expand binding to allow fzf-git Ctrl+G prefix to work
bindkey -r "^G"

set rtp+=/opt/homebrew/opt/fzf
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
export MAX_THINKING_TOKENS=2048
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=8192

# OSC 7 sequence to report current directory to terminal
precmd () {
  printf "\e]7;file://%s%s\e\\" "$HOSTNAME" "$PWD"
}
