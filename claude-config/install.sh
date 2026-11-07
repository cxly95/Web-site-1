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
mkdir -p "$DEST/references" && cp -r "$SRC"/references/. "$DEST/references/"
mkdir -p "$DEST/ponytail-hooks" && cp -r "$SRC"/ponytail-hooks/. "$DEST/ponytail-hooks/"
# Merge the hooks into ~/.claude/settings.json without touching other settings
node -e '
const fs=require("fs");const [f,h]=process.argv.slice(1);
let s={};try{s=JSON.parse(fs.readFileSync(f,"utf8"))}catch{}
const add=JSON.parse(fs.readFileSync(h,"utf8")).hooks;s.hooks=s.hooks||{};
for(const [ev,list] of Object.entries(add)){const cur=s.hooks[ev]||[];
 for(const e of list){if(!cur.some(c=>JSON.stringify(c)===JSON.stringify(e)))cur.push(e)}s.hooks[ev]=cur}
const env=JSON.parse(fs.readFileSync(h,"utf8")).env||{};s.env=Object.assign(s.env||{},env);
fs.writeFileSync(f,JSON.stringify(s,null,2)+"\n");' "$DEST/settings.json" "$SRC/hooks-settings.json"
echo "everything-claude-code installed in $DEST"

# Motion design studio (HyperFrames + launch-film method): workspace in ~/motion-design-studio,
# its 12 skills in ~/.claude/skills with a note pointing them at the workspace.
if [ -d "$SRC/motion-design-studio" ]; then
  STUDIO="$HOME/motion-design-studio"
  mkdir -p "$STUDIO" && cp -r "$SRC"/motion-design-studio/. "$STUDIO/"
  [ -f "$STUDIO/.env" ] || cp "$STUDIO/.env.example" "$STUDIO/.env"
  (cd "$STUDIO" && npm ci --no-audit --no-fund --loglevel=error >/dev/null 2>&1) || echo "motion studio: npm ci failed"
  for d in "$STUDIO"/.claude/skills/*/; do
    n=$(basename "$d"); rm -rf "$DEST/skills/$n"; cp -r "$d" "$DEST/skills/$n"
    [ -f "$DEST/skills/$n/SKILL.md" ] && node -e '
const fs=require("fs");const f=process.argv[1];const s=fs.readFileSync(f,"utf8");
const note=fs.readFileSync(process.argv[2],"utf8");const m=s.match(/^---\n[\s\S]*?\n---\n/);
if(m&&!s.includes("motion-design-studio global install"))fs.writeFileSync(f,m[0]+"\n"+note+"\n"+s.slice(m[0].length));' "$DEST/skills/$n/SKILL.md" "$SRC/motion-design-studio-note.md"
  done
  cp "$STUDIO"/.claude/skills/LICENSE-HEYGEN-APACHE-2.0 "$DEST/skills/" 2>/dev/null || true
  echo "motion design studio installed in $STUDIO"
fi

# Graphify (knowledge graph of a project, /graphify): Python CLI + skill
GRAPHIFY_VERSION=0.9.103
if ! command -v graphify >/dev/null 2>&1 || ! graphify --version 2>/dev/null | grep -q "$GRAPHIFY_VERSION"; then
  if command -v uv >/dev/null 2>&1; then uv tool install -q --force "graphifyy==$GRAPHIFY_VERSION"
  else pip install -q "graphifyy==$GRAPHIFY_VERSION"; fi || echo "graphify: install failed"
fi
export PATH="$HOME/.local/bin:$PATH"
command -v graphify >/dev/null 2>&1 && graphify install --platform claude >/dev/null && echo "graphify skill installed"
exit 0
