import { chromium } from 'playwright-core';

const cmd = process.argv[2];
const url = process.argv[3];

if (!cmd || !url) {
  console.error('Usage: browser-helpers.mjs <cmd> <url>');
  console.error('Commands: text, accessibility');
  process.exit(1);
}

const browser = await chromium.launch({
  channel: undefined,
  args: ['--no-sandbox'],
});

const context = await browser.newContext();
const page = await context.newPage();

try {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 });

  switch (cmd) {
    case 'text':
      console.log(await page.innerText('body'));
      break;
    case 'accessibility':
      console.log(JSON.stringify(await page.accessibility.snapshot({ interestingOnly: true }), null, 2));
      break;
    default:
      console.error(`Unknown command: ${cmd}`);
      console.error('Available: text, accessibility');
      process.exit(1);
  }
} finally {
  await browser.close();
}
