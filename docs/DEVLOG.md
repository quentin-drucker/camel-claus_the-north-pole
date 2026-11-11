# Camel Claus — Devlog

Running notes, decisions, progress and reports. Newest entry on top.
Claude appends an entry after any meaningful work session; add your own thoughts anywhere.

Entry format: `## YYYY-MM-DD — short title`, then what changed, why, and what's next.

---

## 2026-11-10 — Tooling verified, repo on GitHub

**Done**
- Godot MCP connected to the live 4.7.2 editor.
- Blender MCP verified end-to-end (Blender 5.3, addon protocol 15): added `MCP_TestCube` with a procedural noise→ramp "sand" material and screenshotted it. Test object is unsaved scratch in the open Blender session; no `.blend` saved.
- Gamedev skills confirmed loaded: router, godot, workflows, disciplines.
- `git init` on `main`, first commit, pushed to private repo `quentin-drucker/camel-claus`. `.mcp.json` committed (machine-specific paths, no secrets).

**Next**
- Fill in `docs/ART_DIRECTION.md` together, then generate the first hero asset.
- Make the repo public at submission time if the hackathon requires it.

## 2026-11-10 — Tooling setup for the hackathon

**Goal:** test AI-driven Godot development, then ship a browser (Web export) build for hackathon submission.

**Done**
- Installed gamedev skill plugins from `awesome-gamedev-agent-skills`: `router`, `godot`, `workflows`, `disciplines` (skipped `genres` until a genre is chosen).
- Blender MCP (`mcp-for-blender`) chosen for AI asset generation, PBR texturing and material application. Blender 5.3 installed; MCP registered at user scope (telemetry off); addon installed to `%APPDATA%\Blender Foundation\Blender\5.3\scripts\addons\blender_mcp.py`.
- Created `docs/ART_DIRECTION.md` (style bible, mostly TBD), `docs/CONVENTIONS.md` (code/scene/asset rules), this devlog.
- Skill/plugin "why I have this" list lives globally at `~/.claude/MY-SKILLS.md`.

**Next**
- Verify Blender MCP end-to-end (enable addon, start server, test cube).
- Set up git + GitHub repo.
- Fill in the art direction brief; pick one hero asset as the visual target.

**Ideas / open questions**
- Asset vision: Claude models everything in Blender itself and builds custom procedural materials per model, baked to PBR textures for Godot. Poly Haven (CC0) as fallback. Track any non-CC0 asset in `docs/CREDITS.md`.
- Custom skill: Godot Web Release QA (export → host locally → Playwright check). Build it after the first successful web export.
