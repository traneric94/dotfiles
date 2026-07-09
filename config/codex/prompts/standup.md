# Standup

Generate a concise standup update. Gather from all three sources before writing.

1. **Recent commits**: run `git log --oneline --since="2 days ago" --author="$(git config user.email)" | head -20`
2. **Open PRs**: run `gh pr list --author @me --json number,title,url,reviewDecision,isDraft --limit 10`
3. **Jira** (only if an Atlassian MCP server is configured in Codex; otherwise skip this source): my tickets where `assignee = currentUser() AND statusCategory in ("In Progress", "To Do") ORDER BY updated DESC`, limit 15.

## Output

Write exactly this structure - terse, no filler, no process narration:

**Yesterday**
- what was shipped/completed (from commits and resolved tickets)

**Today**
- what is actively in progress (from open PRs and in-progress tickets)

**Blockers**
- PRs awaiting review, blocked tickets, or "None"

One line per bullet, max 8 bullets total, skip any section with nothing to report.
