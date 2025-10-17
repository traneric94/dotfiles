# Minimal fzf-powered Git helpers inspired by junegunn/fzf-git.sh.
# Provides Ctrl-g key bindings plus standalone commands for quick pickers.

[[ -n "${__FZF_GIT_SH_LOADED:-}" ]] && return
__FZF_GIT_SH_LOADED=1

command -v git >/dev/null 2>&1 || return 0
command -v fzf >/dev/null 2>&1 || return 0

# Guard against non-interactive shells (no zle) where widgets should not load.
if ! command -v zle >/dev/null 2>&1; then
  return 0
fi

__fzf_git_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

__fzf_git_trim_status_line() {
  local line="$1"
  [[ -z "$line" ]] && return
  line="${line:3}"
  line="${line##* -> }"
  print -r -- "$line"
}

__fzf_git_append_to_buffer() {
  local data="$1"
  [[ -z "$data" ]] && return
  local -a parts
  parts=(${(f)data})
  local joined="${(j: :)parts}"
  [[ -z "$joined" ]] && return
  if [[ -n "$LBUFFER" && ${LBUFFER: -1} != ' ' ]]; then
    LBUFFER+=" "
  fi
  LBUFFER+="$joined"
  zle redisplay
}

__fzf_git_select_status() {
  local selection
  selection=$(git status --short --untracked-files=all | fzf --multi --prompt='git status> ')
  [[ -z "$selection" ]] && return 1

  local -a files
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    files+=("$(__fzf_git_trim_status_line "$line")")
  done <<< "$selection"

  (( ${#files[@]} )) || return 1
  print -l -- "${files[@]}"
}

__fzf_git_select_branches() {
  git for-each-ref \
    --sort=-committerdate \
    --format='%(refname:short)' \
    refs/heads refs/remotes |
    fzf --multi --prompt='git branches> '
}

__fzf_git_select_tags() {
  git tag --sort=-creatordate |
    fzf --multi --prompt='git tags> '
}

__fzf_git_select_commits() {
  local selection
  selection=$(git log --pretty=format:'%h %s (%cr) <%an>' | fzf --no-sort --multi --prompt='git commits> ')
  [[ -z "$selection" ]] && return 1

  local -a hashes
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    hashes+=("${line%% *}")
  done <<< "$selection"

  (( ${#hashes[@]} )) || return 1
  print -l -- "${hashes[@]}"
}

__fzf_git_select_stash() {
  local selection
  selection=$(git stash list | fzf --multi --prompt='git stash> ')
  [[ -z "$selection" ]] && return 1

  local -a entries
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    entries+=("${line%%:*}")
  done <<< "$selection"

  (( ${#entries[@]} )) || return 1
  print -l -- "${entries[@]}"
}

fzf_git_status() {
  __fzf_git_in_repo || return 1
  __fzf_git_select_status
}

fzf_git_branches() {
  __fzf_git_in_repo || return 1
  __fzf_git_select_branches
}

fzf_git_tags() {
  __fzf_git_in_repo || return 1
  __fzf_git_select_tags
}

fzf_git_commits() {
  __fzf_git_in_repo || return 1
  __fzf_git_select_commits
}

fzf_git_stash() {
  __fzf_git_in_repo || return 1
  __fzf_git_select_stash
}

_fzf_git_widget_status() {
  __fzf_git_in_repo || return
  local data="$(__fzf_git_select_status)" || return
  __fzf_git_append_to_buffer "$data"
}

_fzf_git_widget_branches() {
  __fzf_git_in_repo || return
  local data="$(__fzf_git_select_branches)" || return
  __fzf_git_append_to_buffer "$data"
}

_fzf_git_widget_tags() {
  __fzf_git_in_repo || return
  local data="$(__fzf_git_select_tags)" || return
  __fzf_git_append_to_buffer "$data"
}

_fzf_git_widget_commits() {
  __fzf_git_in_repo || return
  local data="$(__fzf_git_select_commits)" || return
  __fzf_git_append_to_buffer "$data"
}

_fzf_git_widget_stash() {
  __fzf_git_in_repo || return
  local data="$(__fzf_git_select_stash)" || return
  __fzf_git_append_to_buffer "$data"
}

zle -N fzf-git-status-widget _fzf_git_widget_status
zle -N fzf-git-branch-widget _fzf_git_widget_branches
zle -N fzf-git-tag-widget _fzf_git_widget_tags
zle -N fzf-git-commit-widget _fzf_git_widget_commits
zle -N fzf-git-stash-widget _fzf_git_widget_stash

bindkey '^G^S' fzf-git-status-widget
bindkey '^G^B' fzf-git-branch-widget
bindkey '^G^T' fzf-git-tag-widget
bindkey '^G^C' fzf-git-commit-widget
bindkey '^G^H' fzf-git-stash-widget
