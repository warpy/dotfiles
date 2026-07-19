---
name: browser
description: Use ONLY when the user asks to browse a web page, take a screenshot, verify UI visually, export a PDF, dump rendered DOM, inspect a page after JS execution, render a URL, or use Chrome headless / headless-shell / Playwright / Puppeteer. Provides chrome-headless-shell commands for browser verification, screenshots, PDF export, and DOM inspection.
---

# Browser

`chrome-headless-shell` is pre-installed at `/usr/local/bin/chrome-headless-shell`.
Never install Playwright's bundled Chromium or download any browser binary -- use this shell directly.

## Content extraction (prefer these)

Use `node` with the bundled `browser-helpers.mjs` script for agent-friendly, token-efficient output.
It uses the Playwright SDK to control `chrome-headless-shell` and produces clean structured text
instead of raw HTML.

```bash
# visible page text (innerText -- concise, all readable content)
node ~/.config/opencode/skills/browser/browser-helpers.mjs text URL

# accessibility tree (structured JSON, only interactive/semantic elements)
node ~/.config/opencode/skills/browser/browser-helpers.mjs accessibility URL
```

## Screenshots and PDFs

```bash
# screenshot
chrome-headless-shell --no-sandbox --screenshot=/tmp/out.png --window-size=1920,1080 URL

# PDF export
chrome-headless-shell --no-sandbox --print-to-pdf=/tmp/out.pdf URL

# serve a local file
chrome-headless-shell --no-sandbox --screenshot=/tmp/out.png --window-size=1920,1080 file:///path/to/index.html
```

## Environment

`PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`, `PUPPETEER_EXECUTABLE_PATH` and `NODE_PATH` are already
set so Playwright/Puppeteer scripts will use the pre-installed `chrome-headless-shell` automatically.
