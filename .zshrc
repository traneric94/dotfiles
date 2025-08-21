# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
#PATH=/usr/bin:/bin:/usr/sbin:/sbin
#export PATH

# add custom, local installations to PATH
#PATH=/usr/local/bin:/usr/local/sbin:"$PATH"

# add MacPorts to PATH
#PATH=/opt/local/bin:/opt/local/sbin:"$PATH"
#export GOPATH=/Users/erictran/codebase/golang
# export PATH=~/Library/Python/2.7/bin:$PATH

# Path to your oh-my-zsh installation.
ZSH_DISABLE_COMPFIX=true
export ZSH="/Users/erictran/.oh-my-zsh"

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

alias ls='ls -G'
alias ll='ls -a1F'
alias la='ls -A'
alias l='ls -CF'
alias sl='ls'

alias ga='git add'
alias gb="git for-each-ref --format='%(color:cyan)%(authordate:format:%m/%d/%Y %I:%M %p)    %(align:25,left)%(color:yellow)%(authorname)%(end) %(color:reset)%(refname:strip=3)' --sort=authordate refs/remotes"
alias gc='git commit'
alias gca='git commit --amend'
alias gd='git diff --color -b'
alias gdc='git diff --color -b --cached'
alias gdh='git diff --color -b HEAD~1 HEAD'
alias ge='git clean -fd'
alias gf='git fetch origin'
alias gfr='git fetch origin; git rebase origin/develop-stable'
alias gh='git checkout'
alias ghb='git checkout -b'
alias gl='git log'
alias gm='git mergetool'
alias gp='git push origin HEAD:refs/for/develop'
alias gr='git rebase'
alias grc='git rebase --continue'
alias grd='git rebase origin/develop-stable'
alias gs='git status'
alias hlog='git log --date-order --all --graph --format="%C(green)%h %Creset%C(yellow)%an%Creset %C(blue bold)%ar%Creset %C(red bold)%d%Creset %s"'

alias awsume=". awsume"

#ugh so nested
alias golang='cd ~/codebase/golang/src/github.com/crunchyroll/'

alias gitb="git branch | grep '^\*' | cut -d' ' -f2 | pbcopy"
eval $(thefuck --alias)

# functions
function aoc() {
  touch ~/codebase/aoc/2021/day_${1}.py
  touch ~/codebase/aoc/2021/day_${1}_input.txt
  curl -b 'session=53616c7465645f5fd14f47a45fed814749ba7a359568a7b50210c90eedc0fa76e36d358b716143ca9bb37ef98107397d' "https://adventofcode.com/2021/day/${1}/input" > ~/codebase/aoc/2021/day_${1}_input.txt
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


function jt() {
    python -mwebbrowser https://jira.tenkasu.net/browse/$(git branch | grep '*' | sed -E 's/\* draft-//;s/([a-zA-Z]+-[0-9]+).*/\1/')
}
source "$HOME/.config/zsh/functions"
export PATH="/usr/local/opt/php@7.4/bin:$PATH"
export PATH="/usr/local/opt/php@7.4/sbin:$PATH"

export PATH="/usr/sbin:$PATH"
export PATH="/usr/local/opt/php@7.4/bin:$PATH"

# Created by `pipx` on 2023-05-09 16:45:58
export PATH="$PATH:/Users/erictran/.local/bin"

export PATH="${PATH}:${HOME}/.pyenv/versions/2.7.18/bin"
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export PATH="/opt/homebrew/opt/php@7.4/bin:$PATH"
export PATH="/opt/homebrew/opt/php@7.4/sbin:$PATH"

# Source local, untracked overrides
[ -f "$HOME/.chime.sh" ] && source "$HOME/.chime.sh"
if [ -f "$HOME/.zshrc.chime" ]; then
  source "$HOME/.zshrc.chime"
fi
