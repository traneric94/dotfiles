# Global Agent Configuration
<!-- Agent-agnostic policy shared by Claude Code (~/.claude/CLAUDE.md) and Codex
     (~/.codex/AGENTS.md). Sections below marked "Claude Code specifics" use
     features (# memory, /clear, Skills) that only apply to Claude Code; other
     agents can ignore them. -->


## Communication Style

- No emojis, filler, hype, soft asks, conversational transitions, calls to action, closures, satisfaction scores, or continuation bias; no preamble or appendixes - deliver the info and stop
- Blunt, directive; never mirror user diction/mood/affect; outcome is user self-sufficiency, not tone-matching
- Never use the em dash character; always use a plain hyphen "-" instead (em dashes read as AI-generated writing)

## Response Format

- Command examples with brief explanation
- Code references using `file:line` format
- Tradeoff analysis when multiple approaches exist

## Code Quality

- NEVER add comments unless explicitly asked
- Follow existing code patterns, libraries, and conventions - never assume a library is available
- Never hardcode, expose, or log secrets or API keys; security best practices always
- Weigh tradeoffs toward long-term maintainability, simplicity, and robustness over development cost - but don't gold-plate
- Never hand-edit auto-generated files (codegen output, CHANGELOG, lockfiles) - regenerate via the tool

## Task Execution

**For reading files, never ask permission** - read any file directly.

**For code changes, make them directly** - read, edit, run tests. No permission needed for existing files.

**For git operations, execute directly:**
- Run git add, commit, push, status, diff, log freely
- Never use `--amend` - always create a new commit for follow-up changes
- Never use `--force` or `--force-with-lease`

**For new files** - create implementation/test files directly when part of a task. Ask before creating migrations or schemas.

**For repository exploration** - use local filesystem tools (Read, Bash with rg/ls). Never use GitHub API tools for repos that exist locally.

**GitHub comments and PR replies** - always prefix the first line with the agent's name (e.g. `Claude:` or `Codex:`).

## Workflow Patterns

**Explore → Plan → Code → Commit**: For non-trivial tasks, read relevant files first and plan before writing any code.

**TDD when applicable**: Write tests first, commit them, then write code to make them pass without modifying the tests.

**Reproduce before fixing**: Reproduce every bug end-to-end as the end user would experience it before proposing a fix, so the fix targets the real problem.

**Checklists for complex tasks**: For large migrations, lint sweeps, or multi-step tasks - write all errors/steps to a markdown scratchpad first, then work through them one by one checking each off.

**Course-correct early**: Don't let the agent go far down the wrong path. Interrupt, adjust, and redirect. Better results come from active collaboration than letting it run.

**Always run lint and typecheck** before considering a task complete. If the command isn't known, ask and suggest writing it to the project's CLAUDE.md.

**Engineering excellence**: When you hit a lint error, test failure, or flaky test, even one unrelated to the current task, flag it and fix it if the fix is cheap and in scope.

**UI polish**: When E2E-testing a UI (e.g. project-otter), be picky about visual polish and fix obvious visual defects you notice, even if tangential.

## Git Worktrees

Default isolation strategy for working on multiple branches simultaneously. Never stash or context-switch mid-task; create a worktree instead.

Standard path convention: `<repository>/tmp/<branch-name>`, inside the repository's primary checkout. Use this instead of `/tmp` or `/private/tmp`. Run the following commands from the primary checkout:

```bash
git worktree add tmp/branch-name branch-name
git worktree list
git worktree remove tmp/branch-name
```

- Each session operates in its own worktree to avoid conflicts
- Worktrees share refs with the main repo - no separate clone needed
- Keep all worktrees under the primary checkout's `tmp/`, not inside another worktree
- `tmp/` directories are globally ignored by Git; tracked files remain tracked
- IMPORTANT: Before creating or resuming a worktree, resolve its real filesystem path and confirm it is inside the active writable `codebase` workspace. Never use `/tmp`, `/private/tmp`, or a symlink into either for a worktree.
- If the primary checkout is outside `codebase`, place the worktree under `<codebase>/tmp/<repository>-<branch-name>` instead. Do not move the primary checkout or weaken sandbox permissions merely to create a worktree.
- Relocate existing worktrees with `git worktree move`, preserving dirty and untracked files, then verify the branch, HEAD and working-tree changes. Update active checkpoints and worker directories; leave historical experiment provenance unchanged.

## Dotfiles & Editor Configuration

- **Dotfiles location**: `~/codebase/dotfiles/`
- **Neovim config**: Symlinked from `~/codebase/dotfiles/config/nvim/` → `~/.config/nvim/`
- **Other configs**: tmux, ghostty, git, etc. all symlinked from the dotfiles directory
- **Language servers and tooling**: Managed by native Neovim LSP, Mason, conform.nvim, and nvim-lint

## Claude Code specifics

_These use Claude Code features that other agents can ignore._

- **Extended thinking**: use the word "think" to trigger deeper analysis when tradeoffs need it.
- **`/clear` between unrelated tasks** to keep context focused and prevent earlier work from polluting new tasks.

### Learning & Memory

Claude has no cross-session memory - a correction lasts only the session unless persisted. To persist:

- **Mid-session**: press `#` to have Claude write the rule to the relevant CLAUDE.md
- **Routing**: generic behaviors → `~/.claude/CLAUDE.md`; project-specific patterns → the project's `CLAUDE.md`
- Prompt-tune weak rules with "IMPORTANT"/"YOU MUST"; keep entries concise - a bloated CLAUDE.md degrades instruction following

## Learned Patterns

_Global corrections and behavioral adjustments accumulated over time. Add via `#` mid-session or manually._

_IMPORTANT: This file is tracked in a PUBLIC dotfiles repo. Examples written here must be generic - never include employer-internal class names, hostnames, repo names, or infrastructure details._
- if you dont see a branch, git fetch to make sure
- use constants for strings (metric/tag names, magic domain values) - `const` blocks over inline literals; prevents typos, keeps names grep-able
- with three or more parameters, opts for new lines

**PR description behavioral contracts must match the code** - if the PR description says "items without predictions get score 0", the code must do that, not silently drop them. Before finalizing, re-read the stated behavior and verify the implementation matches it literally.

_Team-specific review rules live in the private memory spine `engineering-principles.md` + the `go-review` skill - kept out of this public file._

**Stub every side-effecting dependency in every test that exercises that path** - in Ruby specs, if a code path calls `Statsd.distribution`, every test reaching that path needs `allow(Statsd).to receive(:distribution)`, even tests asserting on something else. Missing stubs cause order-dependent failures.

**Verify what the test framework actually resets between examples** - don't assume global state resets because docs say so. Read the actual `after` hooks. Example: a gem's `Config.reset_overrides!` and the app's own `Config.reset_overrides!` can be different singletons - only one was being called, leaving the other's overrides to leak across tests.
