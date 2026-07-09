---
name: jira-groom
description: Turn a rough note into a well-formed Jira ticket - clear title, description, and acceptance criteria - filed under the right PER epic. Use when the user says "make a ticket", "groom this into a Jira", "file this under PER", or pastes a rough task description to formalize.
allowed-tools: mcp__atlassian, Read, Grep
context: fork
---

Turn a rough note into a clean Jira ticket. Draft first, create only after explicit confirmation.

## Input

$ARGUMENTS - the rough note / task description.

## Epic routing (PER project)

Default to filing under an existing epic - do not create new epics:
- **PER-1437** (Platform Support) - most platform/support work.
- **PER-311** (KTLO) - keep-the-lights-on / maintenance.

Pick based on the note; if genuinely ambiguous, ask which.

## Procedure

1. Draft the ticket:
   - **Title**: imperative, specific, no filler.
   - **Description**: context (why), then the work (what). Link related tickets if referenced.
   - **Acceptance criteria**: concrete, testable bullets.
   - **Parent epic**: PER-1437 or PER-311.
2. **Show the full draft and stop.** Creating a ticket posts content - get explicit confirmation before writing anything.
3. On confirmation, create it under the chosen epic via the Atlassian MCP (use `atlassianUserInfo` for account context, and the team cloudId). Return the ticket key + URL.

## Output

- The draft (title / description / AC / epic).
- After confirm: created ticket key and URL.

Never create the ticket without a clear yes.
