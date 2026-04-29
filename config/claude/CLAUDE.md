# Global Claude Code Configuration

## Communication Style

- No emojis, filler, hype, soft asks, conversational transitions, call to action, appendixes
- Blunt, directive phrasing aimed at cognitive rebuilding, not tone matching
- Terminate reply immediately after delivering info
- No closures, satisfaction scores, emotional softening, continuation bias
- Never mirror user diction/mood/affect
- Restore independent high fidelity thinking — outcome is user self-sufficiency

## Response Format

- Direct answers without preamble
- Command examples with brief explanation
- Code references using `file:line` format
- Tradeoff analysis when multiple approaches exist

## Code Quality

- NEVER add comments unless explicitly asked
- No hardcoded secrets or API keys
- Follow existing code patterns, libraries, and conventions — never assume a library is available
- Security best practices always; never expose or log secrets

## Task Execution

**For reading files, never ask permission** — read any file directly.

**For code changes, make them directly** — read, edit, run tests. No permission needed for existing files.

**For git operations, execute directly:**
- Run git add, commit, push, status, diff, log freely
- Never use `--amend` — always create a new commit for follow-up changes
- Never use `--force` or `--force-with-lease`

**For new files** — create implementation/test files directly when part of a task. Ask before creating migrations or schemas.

**For repository exploration** — use local filesystem tools (Read, Bash with rg/ls). Never use GitHub API tools for repos that exist locally.

**GitHub comments and PR replies** — always prefix with `Claude:` on the first line.

## Workflow Patterns

**Explore → Plan → Code → Commit**: For non-trivial tasks, read relevant files first and plan before writing any code. Use the word "think" to trigger extended thinking when tradeoffs need deeper analysis.

**TDD when applicable**: Write tests first, commit them, then write code to make them pass without modifying the tests.

**Checklists for complex tasks**: For large migrations, lint sweeps, or multi-step tasks — write all errors/steps to a markdown scratchpad first, then work through them one by one checking each off.

**Course-correct early**: Don't let Claude go far down the wrong path. Interrupt with Escape, adjust, and redirect. Better results come from active collaboration than letting it run.

**Use `/clear` between unrelated tasks** to keep context focused and prevent earlier work from polluting new tasks.

**Always run lint and typecheck** before considering a task complete. If the command isn't known, ask and suggest writing it to the project's CLAUDE.md.

## Git Worktrees

Default isolation strategy for working on multiple branches simultaneously. Never stash or context-switch mid-task; create a worktree instead.

Standard path convention: `/tmp/<branch-name>`

```bash
git worktree add /tmp/branch-name branch-name
git worktree list
git worktree remove /tmp/branch-name
# or: rm -rf /tmp/branch-name && git worktree prune
```

- Each Claude Code session operates in its own worktree to avoid conflicts
- Worktrees share refs with the main repo — no separate clone needed

## Dotfiles & Editor Configuration

- **Dotfiles location**: `/Users/eric.tran/codebase/dotfiles/`
- **Neovim config**: Symlinked from `dotfiles/config/nvim/` → `~/.config/nvim/`
- **Other configs**: tmux, alacritty, git, etc. all symlinked from dotfiles directory
- **CoC extensions**: `~/.config/coc/extensions/`
- **Language servers**: Protocol buffers, GraphQL, TypeScript, Go, Ruby, Python via CoC

## Learning & Memory

Claude has no persistent memory between sessions. To persist corrections:

- **Mid-session**: Press `#` to give an instruction Claude will incorporate into the relevant CLAUDE.md automatically
- **Manual**: Add rules directly to `~/.claude/CLAUDE.md` (global) or the project's `CLAUDE.md` (project-scoped)
- **Routing**: Generic behaviors → `~/.claude/CLAUDE.md`. Project-specific patterns → project's `CLAUDE.md`

When correcting Claude during a session, that correction only lasts the session. If it should persist, update CLAUDE.md immediately.

Periodically prompt-tune entries — use "IMPORTANT" or "YOU MUST" on rules where adherence is weak. Keep entries concise; bloated CLAUDE.md degrades instruction following.

## Learned Patterns

_Global corrections and behavioral adjustments accumulated over time. Add via `#` mid-session or manually._
- if you dont see a branch, git fetch to make sure
- use constants for strings

**Use constants for metric/tag name strings** — declare `const` blocks for metric names and tag key templates rather than inline string literals. This prevents typos and makes names grep-able.
- with three or more parameters, opts for new lines

**Graceful degradation needs a warn log AND a dedicated metric** — when handling an expected failure (not-found, model unavailable, etc.) that degrades gracefully, always emit both: a warn log with context fields (strategy ID, type, etc.) AND a dedicated metric (e.g., `*_not_found`). Never reuse the generic error metric for expected degradation paths — it inflates error counts and triggers false alerts.

**PR description behavioral contracts must match the code** — if the PR description says "items without predictions get score 0", the code must do that, not silently drop them. Before finalizing, re-read the stated behavior and verify the implementation matches it literally.

**Every new domain field must be wired through the full convert layer** — when adding a field to the domain model, immediately add it to both directions of the proto ↔ domain (or DB ↔ domain) converter. Missing one direction silently drops config with no error.

**Type check is not value validation — also check the zero value** — after a type assertion, proto getter, or nil check, also validate domain bounds: `GetStringValue() != ""`, multipliers `> 0`, collections non-empty. The type proving the shape doesn't mean the value is valid.

**Metrics need all dimensional tags from day one** — distribution/histogram metrics should include every tag you'll want to slice by (variant, strategy type, banner definition, etc.) from the first commit. Adding tags later requires backfilling dashboards and invalidates historical data.

**Stub every side-effecting dependency in every test that exercises that path** — in Ruby specs, if a code path calls `Chime::Dog.distribution`, every test reaching that path needs `allow(Chime::Dog).to receive(:distribution)`, even tests asserting on something else. Missing stubs cause order-dependent failures.

**Verify what the test framework actually resets between examples** — don't assume global state resets because docs say so. Read the actual `after` hooks. In this codebase, `Chime::Atlas::Tuner.reset_overrides!` and `Chime::Tuner.reset_overrides!` reset different singletons — only the atlas one was being called, leaving Tuner overrides to leak across tests.