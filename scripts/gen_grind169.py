#!/usr/bin/env python3
import csv
import os
import re
import sys
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError

URL = "https://www.techinterviewhandbook.org/grind75?hours=10&weeks=15"
OUTPUT = os.path.join(os.path.dirname(os.path.dirname(__file__)), "anki", "grind169.tsv")

# Very basic extraction: look for table rows with link, topic, difficulty in the HTML.
# The site is statically generated; this heuristic aims to be resilient enough without external deps.

A_TAG_RE = re.compile(r'<a[^>]+href="(https://leetcode\.com/problems/[^\"]+)"[^>]*>([^<]+)</a>', re.IGNORECASE)
DIFF_RE = re.compile(r'>(Easy|Medium|Hard)<')
TOPIC_RE = re.compile(r'>\s*([A-Z][A-Za-z ]+?)\s*<')


def fetch(url: str) -> str:
    req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8", errors="ignore")


def parse(html: str):
    # Find all problem links first
    items = []
    for m in A_TAG_RE.finditer(html):
        url = m.group(1).strip()
        title = m.group(2).strip()
        # Find nearby difficulty and topic by scanning a small window after the link
        end = m.end()
        window = html[end:end+600]
        diff_match = re.search(r'(Easy|Medium|Hard)', window)
        diff = diff_match.group(1) if diff_match else ""
        # Topic often appears before diff in same row; grab the first capitalized word group before diff
        topic_match = None
        # Limit to within the same row by cutting at </tr>
        row_end = window.find("</tr>")
        row_window = window if row_end == -1 else window[:row_end]
        # Look for topics by common set
        topic_candidates = re.findall(r'>(Array|String|Stack|Queue|Linked List|Binary Tree|Binary Search Tree|Binary Search|Graph|Heap|Trie|Matrix|Recursion|Dynamic Programming|Greedy|Two Pointers|Sliding Window|Interval|Backtracking|Math|Bit Manipulation)<' , row_window)
        topic = topic_candidates[0] if topic_candidates else ""
        items.append((title, url, topic, diff))
    # Deduplicate while preserving order
    seen = set()
    deduped = []
    for t in items:
        key = (t[0], t[1])
        if key in seen:
            continue
        seen.add(key)
        deduped.append(t)
    return deduped


def write_tsv(rows):
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter='\t')
        for title, url, topic, diff in rows:
            tags = " ".join(x for x in [topic.replace(" ", "_") if topic else "", diff.lower() if diff else ""] if x)
            writer.writerow([title, url, tags])


def main():
    try:
        html = fetch(URL)
    except (URLError, HTTPError) as e:
        print(f"Fetch error: {e}", file=sys.stderr)
        sys.exit(1)
    rows = parse(html)
    # Heuristic: expect >= 150 entries
    if len(rows) < 140:
        print(f"Parsed only {len(rows)} entries; site layout may have changed.", file=sys.stderr)
    write_tsv(rows)
    print(f"Wrote {len(rows)} cards to {OUTPUT}")


if __name__ == "__main__":
    main() 