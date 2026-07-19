---
name: browser
description: Use ONLY when the user asks to browse a web page, take a screenshot, verify UI visually, export a PDF, dump rendered DOM, inspect a page after JS execution, render a URL, or use Chrome headless / headless-shell / Playwright / Puppeteer. Provides chrome-headless-shell commands for browser verification, screenshots, PDF export, and DOM inspection.
---

# Browser (chrome-headless-shell)

`chrome-headless-shell` is pre-installed at `/usr/local/bin/chrome-headless-shell`.
Never install Playwright's bundled Chromium or download any browser binary -- use this shell directly.

## Common patterns

```bash
# screenshot
chrome-headless-shell --no-sandbox --screenshot=/tmp/out.png --window-size=1920,1080 URL

# PDF export
chrome-headless-shell --no-sandbox --print-to-pdf=/tmp/out.pdf URL

# dump rendered DOM (after JS execution)
chrome-headless-shell --no-sandbox --dump-dom URL

# serve a local file
chrome-headless-shell --no-sandbox --screenshot=/tmp/out.png --window-size=1920,1080 file:///path/to/index.html
```

## Environment

`PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH` and `PUPPETEER_EXECUTABLE_PATH` are already
set to point to this binary, so Playwright/Puppeteer scripts will use it automatically.
