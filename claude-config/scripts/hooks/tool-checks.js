#!/usr/bin/env node
/**
 * Port of the inline tool hooks from everything-claude-code's hooks.json.
 * Usage: node tool-checks.js <pre|post|stop>   (hook JSON arrives on stdin)
 * Exit 2 = block the tool call (message on stderr is shown to Claude).
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const phase = process.argv[2];
let raw = '';
process.stdin.on('data', c => (raw += c));
process.stdin.on('end', () => {
  let input = {};
  try { input = JSON.parse(raw || '{}'); } catch { /* ignore */ }
  const tool = input.tool_name || '';
  const ti = input.tool_input || {};
  const cmd = ti.command || '';
  const file = ti.file_path || '';
  const warn = m => console.error(m);
  const block = m => { console.error(m); process.exit(2); };

  // Only use binaries installed in the project (never download via npx).
  const localBin = (start, name) => {
    let dir = start;
    while (true) {
      const p = path.join(dir, 'node_modules', '.bin', name);
      if (fs.existsSync(p)) return p;
      if (dir === path.dirname(dir)) return null;
      dir = path.dirname(dir);
    }
  };

  if (phase === 'pre' && tool === 'Bash') {
    if (/(npm run dev|pnpm( run)? dev|yarn dev|bun run dev)/.test(cmd) && !/tmux/.test(cmd)) {
      block('[Hook] BLOCKED: Dev server must run in tmux for log access\n[Hook] Use: tmux new-session -d -s dev "npm run dev"\n[Hook] Then: tmux attach -t dev');
    }
    if (/(npm (install|test)|pnpm (install|test)|yarn (install|test)?|bun (install|test)|cargo build|make|docker|pytest|vitest|playwright)/.test(cmd) && !process.env.TMUX) {
      warn('[Hook] Consider running in tmux for session persistence');
    }
    if (/git push/.test(cmd)) warn('[Hook] Review changes before push...');
  }

  if (phase === 'pre' && tool === 'Write' && /\.(md|txt)$/.test(file) &&
      !/(README|CLAUDE|AGENTS|CONTRIBUTING|SKILL)\.md$/.test(file) && !/[\\/]\.claude[\\/]/.test(file)) {
    block(`[Hook] BLOCKED: Unnecessary documentation file creation\n[Hook] File: ${file}\n[Hook] Use README.md for documentation instead`);
  }

  if (phase === 'post' && tool === 'Edit' && /\.(ts|tsx|js|jsx)$/.test(file) && fs.existsSync(file)) {
    const dir0 = path.dirname(path.resolve(file));
    const prettier = localBin(dir0, 'prettier');
    if (prettier) { try { execSync(`"${prettier}" --write "${file}"`, { stdio: 'pipe', timeout: 20000 }); } catch { /* ignore */ } }

    if (/\.(ts|tsx)$/.test(file)) {
      let dir = dir0;
      while (dir !== path.dirname(dir) && !fs.existsSync(path.join(dir, 'tsconfig.json'))) dir = path.dirname(dir);
      const tsc = localBin(dir, 'tsc');
      if (tsc && fs.existsSync(path.join(dir, 'tsconfig.json'))) {
        let out = '';
        try { out = execSync(`"${tsc}" --noEmit --pretty false`, { cwd: dir, encoding: 'utf8', stdio: 'pipe', timeout: 60000 }); }
        catch (e) { out = e.stdout || ''; }
        const lines = out.split('\n').filter(l => l.includes(path.basename(file))).slice(0, 10);
        if (lines.length) warn(lines.join('\n'));
      }
    }

    const matches = fs.readFileSync(file, 'utf8').split('\n')
      .map((l, i) => (/console\.log/.test(l) ? `${i + 1}: ${l.trim()}` : null)).filter(Boolean);
    if (matches.length) warn(`[Hook] WARNING: console.log found in ${file}\n${matches.slice(0, 5).join('\n')}\n[Hook] Remove console.log before committing`);
  }

  if (phase === 'stop') {
    try {
      const files = execSync('git diff --name-only HEAD', { encoding: 'utf8', stdio: 'pipe' })
        .split('\n').filter(f => /\.(ts|tsx|js|jsx)$/.test(f) && fs.existsSync(f));
      for (const f of files) if (fs.readFileSync(f, 'utf8').includes('console.log')) warn(`[Hook] WARNING: console.log found in ${f}`);
    } catch { /* not a git repo */ }
  }
  process.exit(0);
});
