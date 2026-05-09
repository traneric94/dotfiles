#!/usr/bin/env python3
"""
UserPromptSubmit hook: detect corrections and append to ## Learned Patterns in CLAUDE.md.
Never blocks Claude — all errors are swallowed.
"""
import json
import os
import re
import sys
from datetime import date
from pathlib import Path

CORRECTION_RE = re.compile(
    r'^(no[,\s!]|nope[,\s!]|wait[,\s]|stop[,\s!]|don\'t|do not|actually[,\s]|'
    r'instead[,\s]|wrong[,\s!]|incorrect|not like that|that\'s not|never |always |'
    r'you should(n\'t| not)|i said|i meant)',
    re.IGNORECASE,
)

CODEBASE_ROOT = os.path.expanduser(os.environ.get('CODEBASE_ROOT', '~/codebase'))
GLOBAL_MD = os.path.expanduser('~/.claude/CLAUDE.md')
CODEBASE_MD = os.path.join(CODEBASE_ROOT, 'CLAUDE.md')


def read_recent_messages(transcript_path, n=6):
    try:
        lines = Path(transcript_path).read_text().strip().splitlines()
        messages = []
        for line in reversed(lines):
            try:
                msg = json.loads(line)
                if msg.get('role') in ('user', 'assistant'):
                    messages.insert(0, msg)
                    if len(messages) >= n:
                        break
            except Exception:
                continue
        return messages
    except Exception:
        return []


def had_assistant_activity(messages):
    return any(m.get('role') == 'assistant' for m in messages)


def is_correction(prompt, messages):
    if not had_assistant_activity(messages):
        return False
    stripped = prompt.strip()
    if len(stripped) > 250:
        return False
    return bool(CORRECTION_RE.match(stripped))


def target_md(cwd):
    if cwd and cwd.startswith(CODEBASE_ROOT) and Path(CODEBASE_MD).exists():
        return CODEBASE_MD
    return GLOBAL_MD


def append_correction(target_path, prompt):
    content = Path(target_path).read_text()
    entry = f'- [{date.today()}] {prompt.strip()}'
    section = '## Learned Patterns'

    if section not in content:
        content = content.rstrip() + f'\n\n{section}\n\n{entry}\n'
    else:
        idx = content.index(section) + len(section)
        next_section = content.find('\n## ', idx)
        if next_section == -1:
            content = content.rstrip() + f'\n{entry}\n'
        else:
            content = content[:next_section].rstrip() + f'\n{entry}' + content[next_section:]

    Path(target_path).write_text(content)


def main():
    try:
        data = json.load(sys.stdin)
        prompt = data.get('prompt', '')
        transcript_path = data.get('transcript_path', '')
        cwd = data.get('cwd', '')

        if not prompt or not transcript_path:
            sys.exit(0)

        messages = read_recent_messages(transcript_path)
        if is_correction(prompt, messages):
            append_correction(target_md(cwd), prompt)
    except Exception:
        pass

    sys.exit(0)


if __name__ == '__main__':
    main()
