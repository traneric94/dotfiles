---
name: standup
description: Generate a daily standup summary from recent git activity, open PRs, and Jira tickets
allowed-tools: Bash(git log*), Bash(git diff*), Bash(gh pr list*), Bash(gh pr view*), mcp__atlassian__atlassianUserInfo, mcp__atlassian__searchJiraIssuesUsingJql
context: fork
---

Generate a concise standup update. Collect data from all three sources before writing output.

## Step 1 — Recent commits

Recent commits by me across this repo:
!`git log --oneline --since="2 days ago" --author="$(git config user.email)" 2>/dev/null | head -20`

## Step 2 — Open PRs

My open pull requests:
!`gh pr list --author @me --json number,title,url,reviewDecision,isDraft --limit 10 2>/dev/null`

## Step 3 — Jira tickets

Call `mcp__atlassian__atlassianUserInfo` to get my account ID, then call `mcp__atlassian__searchJiraIssuesUsingJql` with:

```
assignee = currentUser() AND statusCategory in ("In Progress", "To Do") ORDER BY updated DESC
```

Limit 15 results, fields: summary, status, priority, updated.

## Output Format

Write a standup in this exact structure — terse, no filler:

**Yesterday**
- [what was shipped/completed based on commits and resolved Jira tickets]

**Today**
- [what's actively in progress from PRs + Jira in-progress tickets]

**Blockers**
- [PRs waiting on review, tickets blocked, or "None"]

Keep each bullet to one line. Max 8 bullets total across all sections. Skip any section with nothing to report. Do not explain your process or mention sources.
