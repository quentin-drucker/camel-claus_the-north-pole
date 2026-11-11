# Camel Claus — Devlog

Running notes, decisions, progress and reports. Newest entry on top.
Claude appends an entry after any meaningful work session; add your own thoughts anywhere.

Entry format: `## YYYY-MM-DD — short title`, then what changed, why, and what's next.

---

## 2026-11-11 — Phase 1.5: balance & systems pass

**Done**
- Contact damage is now discrete hits (chaser 10, zoomer 6, chonk 20) with 0.75 s invulnerability;
  Claus blinks while invulnerable. HUD shows HP numbers ("74 / 120") and kills.
- Enemy types as data: **zoomer** (teal, small, 6.2 m/s — faster than Claus, from 0:45) and
  **chonk** (green, big, 60 HP, 4 XP, from 2:00). Weighted spawn table. Enemies > 30 m away are
  recycled to the spawn ring ahead of Claus.
- Curves instead of straight lines: spawn rate (1.4/s start) and enemy HP both double every 150 s.
- Upgrades are global stats on the player that every weapon reads (Megabonk-tome style):
  damage +20%, attack speed +15% (percent, so no runaway), +1 projectile (cap 2), move +10%,
  pickup +30%, max HP +20. Level cap 5. Cards roll rarity: 75% common, 20% RARE ×1.5, 5% EPIC ×2.
- XP curve flattened: 5 + 3 per level (was +4). Gift Toss 12 damage vs chaser 10 HP, so early
  chasers die in one hit and damage picks extend that window.
- `tests/balance_sim.gd`: a bot that plays a full run headless in ~2 s. `mode=collect` walks to XP
  and dodges; `idle` stands still; `kite` circles. New `tests/test_upgrades.gd`.

**Balance results (collect bot, seeds 1–10)**: 10/10 win, 12–23 level-ups (median ~21), lowest HP
8–77% (median ~50%). Standing still dies at ~0:51; circling without collecting XP dies at ~2:42.
Web build: 300 enemies at ~210 fps in Chrome, 0 console errors.

**Learned**: `-s` test scripts can't use project class names as types (they compile before
autoloads). The editor's stale script cache dropped `max_hp = 10` from chaser.tres (it equalled
the old default) — caught by reading the file. Both added to CONVENTIONS.

**Next**: Checkpoint 1.5 — Quentin replays in the browser. Then Phase 2 (visual target).

## 2026-11-11 — Checkpoint 1 feedback, design research, audio direction

**Playtest findings (Quentin):** feels slow; never seemed to take damage; upgrades shallow
(fire rate runaway, damage weak); gifts are red cubes; no shadows/numbers/sound.
**Diagnosis:** contact damage works (idle test: 100 → 71.5 HP in 24 s) but enemies (3 m/s) can't
catch Claus (5 m/s), damage is a silent 10/s trickle, and the HP bar is easy to miss. Flat -0.12 s
cooldown compounds (5 picks = 4.7× fire rate); +5 damage does nothing until enemy HP > 15 (~1:15).
Enemy HP only ×3 over the run; no enemy recycling, types, elites or boss.
**Research:** Megabonk (weapons + tomes + 85 chest items, rarity-scaled offers) and Vampire
Survivors (capped passives, evolutions). Recommendation: no 1:1 re-skin of Megabonk's roster
(balance doesn't transfer to 5 min; IP); own ~12-20 item set using genre patterns, rarity rolls,
level caps, elite chests, 2 evolutions, final boss; curves that double roughly every 90 s.
**Decided:** audio = cozy jingle-bell chiptune from CC0 packs (`ART_DIRECTION.md`). Web build
plays audio as samples, so no bus effects; duck music by tweening a MusicDuck bus volume.
**Next:** Quentin to choose: balance pass before Phase 2? level-ups + elite-chest items +
evolutions structure? Then write `docs/GAME_DESIGN.md` and update `PLAN.md`.

## 2026-11-10 — Phase 1: greybox core loop playable

**Done**
- Full run loop with primitives: Claus (tan capsule, WASD/arrows), chaser enemies (purple capsules) spawning in a ring 18 m out, Gift Toss auto-firing red cubes at the nearest enemies, gold XP ornaments pulled in by pickup radius, XP bar, level-up menu (pauses, 3 random of 6 upgrades), HP bar, 5:00 countdown, win/lose screen, restart.
- No physics bodies: everything is distance checks. `EnemySpawner` moves all enemies in one loop with a spatial grid for separation (they form a crowd, not one blob) and applies contact damage.
- Data as Resources: `EnemyData` (`resources/enemies/chaser.tres`), `WeaponData` (`resources/weapons/gift_toss.tres`), `UpgradeData` x6 (`resources/upgrades/`). `GameState` autoload holds run time, XP/level, and the live player/enemy lists.
- Arena 120x120 m with two-tone pixel snow (noise texture, nearest filter) so movement reads; player clamped to it.
- **Performance gate passed:** F2 debug key spawns 300 enemies + god mode. Web build in Chrome: ~300 enemies at 240 fps (median frame 4.2 ms, p95 4.3 ms), 0 console errors. Measured on an RTX 5080 laptop; re-check on weaker hardware in Phase 5. MultiMesh not needed.
- Unit test `tests/test_game_state.gd` for XP/level math (multi-level grabs). Passing.
- First tuning pass: Gift Toss 10 dmg / 0.7 s (5 dmg felt hopeless: died at 0:16 at level 1); spawn ramp 0.7 → 8 enemies/s; enemy HP x1 → x3 over the run.

**Gotchas (now in `CONVENTIONS.md`)** — editor rescans only on focus; autoload must compile before it's added; set exported fields in a separate step from attaching the script.

**Known rough edges (later phases)**
- HUD timer shows 0:01 behind the win screen (cosmetic). F2 debug key and FPS label must go before ship. Balance is untested beyond the first minute.

**Next**
- Checkpoint 1: Quentin plays a full run in the browser and says if it's fun.

## 2026-11-10 — Phase 0: pipeline smoke test passed

**Done**
- Blender: throwaway gift box `GiftTest` (48 tris), procedural material (object-space masks: red body, dark-red base band, gold ribbon + bow), baked to 32×32 with Cycles Diffuse/Color, palette-snapped to `#D9343F #8E1F2E #F2B53B`. Source: `art_src/gift_test.blend`; bake output `assets/textures/gift_test_albedo.png`; game asset `assets/models/gift_test.glb` (5.7 KB, image node set to Closest → glTF sampler NEAREST).
- Godot: `scenes/main/main.tscn` (main scene) = `GameCamera` (pitch −55°, FOV 40°, 17 m from target), `Sun` (upper-left-front), `WorldEnvironment` (cool ambient), 40×40 m snow ground, gift instanced via wrapper `scenes/props/gift_test.tscn`. Viewport 1280×720, stretch `canvas_items` / `expand`. Gift reads ~25 px tall at 720p.
- Web export preset `Web` (single-threaded), output `build/web/` (git-ignored). Served with `python -m http.server`, checked in Chrome via Playwright: renders, 0 console errors/warnings, WebGL 2 Compatibility, "single-threaded" confirmed.

**Gotchas found (now in `CONVENTIONS.md`)**
- Godot MCP can't instance `.glb` directly → wrap each model in an inherited `.tscn`.
- Godot extracts the glb's embedded texture and imports it **VRAM-compressed with mipmaps** by default; switched to lossless, no mipmaps. Material comes in as `texture_filter = Nearest with mipmaps` (fine once no mipmaps exist).

**Next**
- Checkpoint 0: Quentin opens the local web build.
- Later: the pck includes `addons/godot_mcp`; exclude it from the export before shipping. Automate the extracted-texture import fix if it recurs for every model.

## 2026-11-10 — Art direction first draft

**Done**
- Fixed `.mcp.json` `GODOT_PATH` (Godot moved to `C:\Program Files\`); `godot_status` now finds the executable, so runs work.
- Filled `docs/ART_DIRECTION.md`: survivor-genre look (low-poly 3D, 32 px/m nearest-filtered pixel textures, full-res render), fixed high camera, North Pole theme with Christmas-gift warm accents, 16-swatch palette (cool = world, warm = player/rewards, purple = danger), poly/texture budgets.
- Tone locked: cute and all-ages. Player and enemies are chibi/plush-like; enemies read as hostile via purple accents, playful points and grumpy/"scary" faces, but bodies stay round and cute (angry plush toy, never frightening).
- **Changed pipeline:** dropped PBR normal/ORM maps; Blender procedural materials now bake to one small albedo PNG per asset.

**Why:** the genre look reads well with hundreds of enemies and stays cheap for the Web build.

- Wrote `docs/PLAN.md`: demo scope (1 map, 3 enemies, 3 weapons, 5-min run, web build) and 6 phases with checkpoints. Claus is the Connecticut College Camel.
- Web export templates installed (4.7.2, all 8 Web variants incl. single-threaded). Editor network mode had to be switched to online first.

**Next**
- Phase 0 of `docs/PLAN.md`: pipeline smoke test (Blender → .glb → Godot → web build in browser).
- Audio & UI style still TBD.

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
- Git LFS: not set up (low-poly assets should stay small). Add it before committing any file over ~50 MB; GitHub rejects files over 100 MB.
- Custom skill: Godot Web Release QA (export → host locally → Playwright check). Build it after the first successful web export.
