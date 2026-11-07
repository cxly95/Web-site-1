#!/usr/bin/env bash
# Installs everything-claude-code (skills, commands, agents, hooks) into ~/.claude
# so they are available in every session, whatever the repository.
set -e
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude"
mkdir -p "$DEST"/{skills,commands,agents,scripts}
cp -r "$SRC"/skills/. "$DEST/skills/"
cp -r "$SRC"/commands/. "$DEST/commands/"
cp -r "$SRC"/agents/. "$DEST/agents/"
cp -r "$SRC"/scripts/. "$DEST/scripts/"
mkdir -p "$DEST/ponytail-hooks" && cp -r "$SRC"/ponytail-hooks/. "$DEST/ponytail-hooks/"
# Merge the hooks into ~/.claude/settings.json without touching other settings
node -e '
const fs=require("fs");const [f,h]=process.argv.slice(1);
let s={};try{s=JSON.parse(fs.readFileSync(f,"utf8"))}catch{}
const add=JSON.parse(fs.readFileSync(h,"utf8")).hooks;s.hooks=s.hooks||{};
for(const [ev,list] of Object.entries(add)){const cur=s.hooks[ev]||[];
 for(const e of list){if(!cur.some(c=>JSON.stringify(c)===JSON.stringify(e)))cur.push(e)}s.hooks[ev]=cur}
fs.writeFileSync(f,JSON.stringify(s,null,2)+"\n");' "$DEST/settings.json" "$SRC/hooks-settings.json"
echo "everything-claude-code installed in $DEST"

# Graphify (knowledge graph of a project, /graphify): Python CLI + skill
GRAPHIFY_VERSION=0.9.103
if ! command -v graphify >/dev/null 2>&1 || ! graphify --version 2>/dev/null | grep -q "$GRAPHIFY_VERSION"; then
  if command -v uv >/dev/null 2>&1; then uv tool install -q --force "graphifyy==$GRAPHIFY_VERSION"
  else pip install -q "graphifyy==$GRAPHIFY_VERSION"; fi || echo "graphify: install failed"
fi
export PATH="$HOME/.local/bin:$PATH"
command -v graphify >/dev/null 2>&1 && graphify install --platform claude >/dev/null && echo "graphify skill installed"
exit 0
