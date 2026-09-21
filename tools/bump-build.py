#!/usr/bin/env python3
"""Stamps hugelland.html and version.txt with the same build time.

Run this before deploying anything that changes how a map is dealt or scored:

    python3 tools/bump-build.py

A page keeps the stamp it loaded with and compares it against version.txt whenever it comes back into view.
A page behind the site reloads itself at the next town, so a tab left open across a release cannot play by an
older library — which would deal a different deck for the same day and be refused by the leaderboard.
"""

import datetime
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%MZ")

page = root / "hugelland.html"
text = page.read_text()
new, n = re.subn(r'const BUILD = "[^"]*";', f'const BUILD = "{stamp}";', text, count=1)
if n != 1:
    raise SystemExit("could not find the BUILD line in hugelland.html")
page.write_text(new)
(root / "version.txt").write_text(stamp + "\n")
print("build stamp:", stamp)
