> **motion-design-studio global install.** This skill belongs to the motion design studio installed at
> `~/motion-design-studio`. Before any command, `cd ~/motion-design-studio`: every relative path in this skill
> (`AGENTS.md`, `patterns/`, `templates/`, `examples/`, `.claude/skills/...`, `<project>/`, `../hyperframes/...`)
> is relative to that folder, and films are created there. Before the voice step, run
> `bash ~/motion-design-studio/install-prereqs.sh` once per session (Whisper and Playwright, about 2-3 minutes).
> If the FLORA connector is available, the voice can be generated with FLORA's `Eleven v4` model (quote the USD
> cost and get the user's approval first) instead of the ElevenLabs web app; save it as `<project>/assets/audio/voix.mp3`.
> The studio is erased when the session ends: send finished films with SendUserFile and, if the user wants to keep
> a project, copy its folder into the repository the session is working on.
