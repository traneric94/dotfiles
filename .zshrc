# Keep $PATH entries unique for the shell's lifetime (dedups retroactively and on
# every add), so re-sourcing this file and the pyenv/rbenv init evals never bloat
# $PATH. All PATH dirs are defined in one block below, after the brew bootstrap.
typeset -U path PATH

# Bootstrap Homebrew — .zprofile already runs `brew shellenv` for login shells;
# fall through to the loop only for non-login subshells (e.g. tmux panes when
# default-command isn't a login shell).
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  BREW_PREFIX="$HOMEBREW_PREFIX"
else
  for _bp in /opt/homebrew /home/linuxbrew/.linuxbrew /usr/local; do
    if [[ -x "$_bp/bin/brew" ]]; then
      eval "$("$_bp/bin/brew" shellenv)"
      BREW_PREFIX="$_bp"
      break
    fi
  done
  unset _bp
fi

# Determine dotfiles directory for sourcing helper scripts
if [[ -z "${DOTFILES_DIR:-}" ]]; then
  DOTFILES_DIR="$HOME/codebase/dotfiles"
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    # Fall back to resolving this rc's real location (it is symlinked from the repo).
    DOTFILES_DIR="${${(%):-%N}:a:h}"
  fi
fi

# ── PATH (single source of truth) ────────────────────────────────────────────
# Every static PATH dir is defined here and nowhere else. `typeset -U path`
# (top of file) keeps entries unique, so this survives re-sourcing and the
# pyenv/rbenv init evals later. Front of the list = highest priority.
path=(
  "$HOME/go/bin"                          # Go binaries (gopls, etc.)
  "$PYENV_ROOT/bin"                       # pyenv itself (version shims added by its init eval)
  "$HOME/.local/share/nvim/mason/bin"     # Mason-managed LSPs / formatters / linters
  /usr/sbin
  $path
  "$HOME/.local/bin"                      # pipx (appended: lowest priority, as before)
)

# Homebrew opt-keg bins — only when the keg is installed (BREW_PREFIX from the
# bootstrap above). Absent on this machine; kept for portability to hosts that
# have them. rbenv/pyenv shims (added later) still win for ruby/python.
if [[ -n "${BREW_PREFIX:-}" ]]; then
  [[ -d "$BREW_PREFIX/opt/ruby@3.3/bin" ]] && path=("$BREW_PREFIX/opt/ruby@3.3/bin" $path)
  [[ -d "$BREW_PREFIX/opt/php@7.4/bin"  ]] && path=("$BREW_PREFIX/opt/php@7.4/bin" "$BREW_PREFIX/opt/php@7.4/sbin" $path)
fi

# ── Completions ────────────────────────────────────────────────────────────────
# Rebuild the completion dump (and run the insecure-dir security scan) at most
# once per 24h; otherwise load cached with -C. Saves ~100-200ms per shell.
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Completion behaviour (compinit builds the engine; zstyle drives the UX).
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{green}-- %d --%f'

# ── Prompt (robbyrussell-style, pure zsh) ─────────────────────────────────────
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats '%F{cyan}(%b)%f '
zstyle ':vcs_info:git:*' actionformats '%F{yellow}(%b|%a)%f '
precmd_functions+=(vcs_info)
setopt prompt_subst
PROMPT='%(?:%F{green}%B➜%b%f :%F{red}%B➜%b%f ) %F{cyan}%1~%f ${vcs_info_msg_0_}'

# LANG / locale is set in .zshenv (applies to all shells, not just interactive).

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
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

# ── Shell behaviour ──────────────────────────────────────────────────────────
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT   # `cd` builds a dir stack (cd -<Tab>)
DIRSTACKSIZE=20
setopt COMPLETE_IN_WORD ALWAYS_TO_END AUTO_MENU AUTO_PARAM_SLASH
setopt INTERACTIVE_COMMENTS      # allow # comments at the interactive prompt
setopt EXTENDED_GLOB
WORDCHARS=${WORDCHARS//[\/]/}    # Ctrl-W / word motions stop at path separators

alias awsume=". awsume"


# functions
function aoc() {
  local year="${AOC_YEAR:-$(date +%Y)}"
  mkdir -p "$HOME/codebase/aoc/$year"
  touch "$HOME/codebase/aoc/$year/day_${1}.py"
  touch "$HOME/codebase/aoc/$year/day_${1}_input.txt"
  if [ -z "${AOC_SESSION:-}" ]; then echo "Set AOC_SESSION env var with your Advent of Code session cookie." >&2; return 1; fi
  curl -b "session=${AOC_SESSION}" "https://adventofcode.com/${year}/day/${1}/input" > "$HOME/codebase/aoc/$year/day_${1}_input.txt"
}

# longer aws sessions
# awsume PROFILENAME -a
# awsume PROFILENAME --role-duration 14400

# profiles per window
# awsume --config set console.browser_command "\"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome\" -incognito \"{url}\" --user-data-dir=/tmp/{profile} --no-first-run"

# Source external function definitions
[ -f "$HOME/.config/zsh/functions" ] && source "$HOME/.config/zsh/functions"

# bat is guaranteed by the Brewfile; no presence check needed.
BAT_CMD="bat"

### Quality of Life Aliases
# ==============================================================================
alias vim=nvim
alias cat=bat
alias mkdir='mkdir -p'  # Create parent directories as needed
alias c='clear'          # Clear terminal screen
alias reload='source ~/.zshrc'  # Reload ZSH Configuration
alias ssh-target='echo "${USER}@$(_local_ip)"'
alias sb='nvim "$(ls -t /tmp/ghostty-* 2>/dev/null | head -1)"'  # Open most recent ghostty scrollback dump in nvim

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
alias gf='git fetch --all --prune'
# NOTE: was 'git push origin HEAD:refs/for/develop' (Gerrit magic-ref). This repo's
# workflow is GitHub + Graphite (gt submit), so plain push is the sane default.
alias gp='git push'
alias gr='git rebase'
alias grc='git rebase --continue'
# Untracked-file cleaning: ge defaults to a DRY RUN (was 'git clean -fd', which
# irreversibly deleted with no confirmation). Use gef for the real thing.
alias ge='git clean -nd'   # dry run: show what WOULD be removed
alias gei='git clean -id'  # interactive
alias gef='git clean -fd'  # force (destructive, deliberate)
alias gm='git mergetool'
alias gb="git for-each-ref --format='%(color:cyan)%(authordate:format:%m/%d/%Y %I:%M %p)    %(align:25,left)%(color:yellow)%(authorname)%(end) %(color:reset)%(refname:strip=3)' --sort=authordate refs/remotes"
alias hlog='git log --date-order --all --graph --format="%C(green)%h %Creset%C(yellow)%an%Creset %C(blue bold)%ar%Creset %C(red bold)%d%Creset %s"'
alias gitb="git branch | grep '^\*' | cut -d' ' -f2 | _clipboard"

# ==============================================================================
# Custom Functions
# ==============================================================================

# Cross-platform clipboard write
_clipboard() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    pbcopy
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    clip.exe
  else
    xclip -selection clipboard 2>/dev/null || xsel --clipboard --input 2>/dev/null
  fi
}

# Local IP address (cross-platform)
_local_ip() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null
  else
    ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d/ -f1 | head -1
  fi
}

# Fuzzy man page picker
fman() {
  command -v fzf >/dev/null 2>&1 || { echo "fzf is required for fman" >&2; return 1; }
  local selection
  selection=$(printf '%s\n' ${(k)commands} | sort -u | fzf --prompt='man> ' --height=70% --ansi) || return 1
  [[ -n "$selection" ]] && man "$selection"
}

# Auto-create .ruby-version from Gemfile when entering Ruby projects
auto_ruby_version() {
  if [[ -f "Gemfile" && ! -f ".ruby-version" ]]; then
    local ruby_req=$(grep '^ruby ' Gemfile 2>/dev/null)
    if [[ -n "$ruby_req" ]]; then
      local version=$(echo "$ruby_req" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
      if [[ -n "$version" ]]; then
        local available=$(rbenv versions --bare | grep "^${version}" | head -1 2>/dev/null)
        if [[ -n "$available" ]]; then
          echo "$available" > .ruby-version
          echo "📝 Created .ruby-version with Ruby $available"
        fi
      fi
    fi
  fi
}

# Auto-tidy after go get
go() {
  if [[ "$1" == "get" ]]; then
    command go "$@" && go mod tidy
  else
    command go "$@"
  fi
}

# gnhf: scoped wrapper around the autonomous agent loop.
#   - mutes Claude notification hooks for the run (GNHF_RUN, see notify-*.sh)
#   - blocks --push (never push un-reshaped WIP; reshape with gt, submit manually)
#   - refuses to run inside a Chime/1debit repo (org guardrail: no unattended
#     agent on work repos)
gnhf() {
  local arg
  for arg in "$@"; do
    if [[ "$arg" == "--push" ]]; then
      echo "gnhf: --push is blocked. Reshape with 'gt branch create' and submit manually." >&2
      return 1
    fi
  done
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local remote
    remote="$(git remote get-url origin 2>/dev/null)"
    if [[ "$remote" == *1debit* || "$remote" == *chime* ]]; then
      echo "gnhf: refusing to run inside a Chime/1debit repo ($remote)." >&2
      return 1
    fi
  fi
  GNHF_RUN=1 command gnhf "$@"
}

# Ripgrep + fzf interactive search with syntax highlighting
# Usage: rgf "search_term"
function rgf() {
  local bat_cmd="${BAT_CMD:-bat}"
  rg --line-number --no-heading --color=always --with-filename "$1" | \
  awk -F: -v OFS=: '{printf "%-50s %4s: %s\n", $1, $2, substr($0, index($0, $3))}' | \
  fzf --ansi \
      --delimiter : \
      --nth 1,2 \
      --preview "FILE=\$(printf '%s\n' {} | awk '{print \$1}' | sed 's/[[:space:]]*$//'); LINE=\$(printf '%s\n' {} | awk '{print \$2}' | tr -d ':'); ${bat_cmd} --color=always --style=numbers --highlight-line \$LINE \"\$FILE\"" \
      --preview-window up:60% \
      --layout=reverse \
      --info=inline
}

# Function to find and open files using zoxide and fzf
# Usage: search_with_zoxdie [search_term] or nzo [search_term]
function search_with_zoxdie() {
    local bat_cmd="${BAT_CMD:-bat}"
    local preview_cmd="${bat_cmd} --color=always -n --line-range :500 {+2..}"
    if [ -z "$1" ]; then
        # Use fd with fzf to select & open a file when no args are provided
        file=$(fd --type f --strip-cwd-prefix -I -H -E .git -E .git-crypt -E .cache -E .backup | xargs -I {} eza --icons=always --color=always {} | fzf --height=70% --ansi --preview "$preview_cmd")
        if [ -n "$file" ]; then
            # Extract the actual filename (everything after the icon and space)
            actual_file=$(echo "$file" | sed 's/^[^ ]* //')
            nvim "$actual_file"
        fi
    else
        # Handle when an argument is provided - only search within current directory and subdirectories
        lines=$({ fd --type f -I -H -E .git -E .git-crypt -E .cache -E .backup -E .vscode "$1" .; zoxide query -l | while read -r dir; do if [ -d "$dir" ]; then case "$dir" in "$(pwd)"*) rel_dir="${dir#$(pwd)/}"; if [ "$rel_dir" != "$dir" ]; then fd --type f -I -H -E .git -E .git-crypt -E .cache -E .backup -E .vscode "$1" "$dir" | sed "s|^$dir/|$rel_dir/|" 2>/dev/null; fi ;; esac; fi; done; } | sort -u | xargs -I {} eza --icons=always --color=always {} | fzf --no-sort --height=70% --ansi --preview "$preview_cmd")
        line_count="$(echo "$lines" | wc -l | xargs)"

        if [ -n "$lines" ] && [ "$line_count" -eq 1 ]; then
            actual_file=$(echo "$lines" | sed 's/^[^ ]* //')
            nvim "$actual_file"
        elif [ -n "$lines" ]; then
            file=$(echo "$lines" | fzf --query="$1" --height=70% --ansi --preview "$preview_cmd")
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
    local bat_cmd="${BAT_CMD:-bat}"
    local preview_cmd="${bat_cmd} --color=always -n --line-range :500 {+2..}"
    if [ -z "$1" ]; then
        file=$(fd --type f --strip-cwd-prefix --no-ignore -H | xargs -I {} eza --icons=always --color=always {} | fzf --height=70% --ansi --preview "$preview_cmd")
        if [ -n "$file" ]; then
            actual_file=$(echo "$file" | sed 's/^[^ ]* //')
            nvim "$actual_file"
        fi
    else
        lines=$({ fd --type f --no-ignore -H "$1" .; zoxide query -l | while read -r dir; do if [ -d "$dir" ]; then case "$dir" in "$(pwd)"*) rel_dir="${dir#$(pwd)/}"; if [ "$rel_dir" != "$dir" ]; then fd --type f --no-ignore -H "$1" "$dir" | sed "s|^$dir/|$rel_dir/|" 2>/dev/null; fi ;; esac; fi; done; } | sort -u | xargs -I {} eza --icons=always --color=always {} | fzf --no-sort --height=70% --ansi --preview "$preview_cmd")
        line_count="$(echo "$lines" | wc -l | xargs)"
        if [ -n "$lines" ] && [ "$line_count" -eq 1 ]; then
            actual_file=$(echo "$lines" | sed 's/^[^ ]* //')
            nvim "$actual_file"
        elif [ -n "$lines" ]; then
            file=$(echo "$lines" | fzf --query="$1" --height=70% --ansi --preview "$preview_cmd")
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

# pyenv / rbenv are guaranteed by the Brewfile. PATH dirs for these live in the
# consolidated PATH block near the top; here we just load the version shims.
_cache_eval() { # $1=cache file, rest=command to memoize
  local cache="$1"; shift
  mkdir -p "${cache:h}"
  if [[ ! -s "$cache" || -n "$cache"(#qN.mh+24) ]]; then "$@" >| "$cache"; fi
  source "$cache"
}
_cache_eval "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/pyenv-init.zsh" pyenv init - zsh
_cache_eval "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/rbenv-init.zsh" rbenv init - zsh

# Source local, untracked overrides
[ -f "$HOME/.chime.sh" ] && source "$HOME/.chime.sh"
if [ -f "$HOME/.zshrc.chime" ]; then
  source "$HOME/.zshrc.chime"
fi

# Interactive-only enhancements
if [[ -t 1 ]]; then
  if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
  fi
  # Load order matters: vi-mode first, then syntax-highlighting, then
  # autosuggestions LAST (autosuggestions must wrap the highlighter's ZLE widgets).
  [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]] && source "$BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
  [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

  # zsh-vi-mode re-applies its keymaps at first prompt, clobbering any bindkey
  # set during rc sourcing. Do the interactive keybindings HERE so they survive
  # vi-mode init, then source fzf-git (which binds its own Ctrl-G chords).
  function zvm_after_init() {
    bindkey -e
    bindkey '^F' autosuggest-accept   # Ctrl-F accepts the autosuggestion
    bindkey '^I' expand-or-complete   # keep Tab for real completion
    bindkey -r '^G'                       # free Ctrl-G prefix for fzf-git chords
    local fzf_git="$DOTFILES_DIR/scripts/fzf-git.sh"
    [[ -f "$fzf_git" ]] && source "$fzf_git"
  }

  # Ctrl-S is XOFF (terminal flow control) by default and swallows the fzf-git
  # Ctrl-G Ctrl-S chord — disable flow control so the key reaches zle.
  stty -ixon 2>/dev/null

  if command -v fzf >/dev/null 2>&1; then
    [[ -n "${BREW_PREFIX:-}" ]] && eval "$($BREW_PREFIX/bin/fzf --zsh 2>/dev/null)"
  fi
fi
export FZF_DEFAULT_COMMAND="${BREW_PREFIX:-/opt/homebrew}/bin/fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="${BREW_PREFIX:-/opt/homebrew}/bin/fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Catppuccin Mocha theme for FZF
export FZF_DEFAULT_OPTS="--height 50% --layout=default --border \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6ac,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6ac,hl+:#f38ba8 \
--bind=ctrl-u:preview-up,ctrl-d:preview-down,ctrl-b:preview-page-up,ctrl-f:preview-page-down"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200' --preview-window=right:60%:wrap"

export FZF_TMUX_OPTS="-p 90%,70%"

# Set FZF previews
export FZF_CTRL_T_OPTS="--preview '${BAT_CMD} --color=always -n --line-range :500 {}'"

export GPG_TTY=$TTY
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

# OSC 7 sequence to report current directory to terminal (zsh sets $HOST, not $HOSTNAME)
_osc7_cwd() {
  printf '\e]7;file://%s%s\e\\' "${HOST}" "$PWD"
}
precmd_functions+=(_osc7_cwd)

# Hook auto Ruby version detection into directory changes (fires on cd, not every prompt)
chpwd_functions+=(auto_ruby_version)
