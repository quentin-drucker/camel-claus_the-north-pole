# Camel Claus — Demo Plan

The build plan for the hackathon demo. Claude works through it phase by phase and stops at each
**Checkpoint** for Quentin's review. Tick boxes as phases finish; log details in `DEVLOG.md`.
Look and feel rules live in `ART_DIRECTION.md`; code rules in `CONVENTIONS.md`.

## The demo in one sentence

You steer **Claus, the Connecticut College Camel lost at the North Pole**, to **survive 5 minutes**
of swarming cute-grumpy winter critters while your gift-powered weapons fire automatically and you
**pick upgrades** each level-up.

Roles: **Quentin** = creative director and playtester (approves art, tests feel, makes calls).
**Claude** = builds everything (Blender models, Godot scenes and code, exports, tests).

## Demo scope (MVP) — everything else is a stretch goal

| Area | Demo has | Stretch (only after the demo ships) |
|------|----------|--------------------------------------|
| Map | 1 snowfield arena (~120×120 m), tiled snow ground, scattered props, invisible walls | More maps, day/night |
| Player | Claus: WASD/arrows move, HP, pickup radius | Character select, dash |
| Enemies | 3 types: **chaser** (basic), **zoomer** (small, fast), **chonk** (slow, tanky) | Mini-boss at 4:00, ranged enemies |
| Weapons | 3: **Gift Toss** (shoots nearest enemy), **Candy Cane Orbit** (spins around Claus), **Jingle Pulse** (area burst) | Weapon evolutions/synergies |
| Progression | XP ornaments drop → XP bar → level-up pauses game → pick 1 of 3 upgrades (weapon levels + speed / max HP / pickup radius) | Meta-progression, unlocks |
| Run | 5:00 timer, spawns ramp up; survive = win, die = lose, restart | Endless mode, score |
| UI | Title, HUD (HP, XP bar, level, timer), level-up menu, win/lose screen | Settings, pause menu |
| Audio | ~5 SFX + 1 music loop (source TBD, see Open questions) | Adaptive music |
| Performance | **300 enemies on screen at 60 fps in Chrome** | 1000+ via MultiMesh |
| Ship | Web build playable from a public link | Desktop builds |

## Phases (hackathon budget ~42 h; leave the last ~20% for shipping)

### Phase 0 — Pipeline smoke test (~2 h) ☐ — steps 1–5 done, awaiting Checkpoint 0
Prove the **entire** workflow once with throwaway content before building anything real.
1. ✅ **[Quentin]** Install export templates: Godot → *Editor → Manage Export Templates → Download
   and Install* (~1 GB, one time).
2. Blender: model a tiny test prop (a gift box), build a procedural material, bake it to a 32×32
   pixel albedo PNG, export `.glb` into `assets/models/`.
3. Godot: create `scenes/main/main.tscn` with the fixed game camera, a light, the test gift and a
   ground plane; set it as the main scene. Confirm nearest filtering (crisp pixels).
4. Create a **Web export preset** (single-threaded, so it runs on any host without special server
   headers), export to `build/web/` (git-ignored), serve locally, open it in a browser with
   Playwright, screenshot, check the browser console for errors.
5. Commit + push.
- **Checkpoint 0:** you open the local web build yourself and see the gift box. Workflow proven.

### Phase 1 — Greybox core loop (~8 h) ☐ — steps 1–7 done, awaiting Checkpoint 1
Primitives only (capsules, boxes, spheres) — fun first, art later.
1. Player moves on the ground plane; camera follows at the fixed angle.
2. Enemy spawner rings the player off-screen; enemies walk toward Claus; contact damages.
3. Gift Toss weapon auto-fires at the nearest enemy; enemies have HP and die.
4. Dead enemies drop XP ornaments; pickup radius pulls them in; XP bar fills; level-up shows
   3 upgrade choices (game paused).
5. 5:00 timer + spawn ramp; win/lose screen; restart.
6. Data as Resources (`.tres`): `EnemyData`, `WeaponData`, `UpgradeData` (per `CONVENTIONS.md`).
7. **Performance gate:** stress test 300 enemies in the *web build*. Enemies use simple code
   movement and distance checks (no physics body per enemy). If it misses 60 fps, switch enemies
   to MultiMesh before adding art.
- **Checkpoint 1:** you play a full greybox run in the browser and say if it's fun.

### Phase 2 — Visual target (~5 h) ☐
1. Blender: **Claus** (Santa hat + scarf), **one gift/XP ornament**, **chaser** enemy, **snow
   ground tile**, each baked to pixel textures within `ART_DIRECTION.md` budgets.
2. Swap them into the greybox; view at 1280×720 through the game camera.
- **Checkpoint 2:** you approve the look (or we iterate). Then fill in "Visual target" in
  `ART_DIRECTION.md`. **No more art until this is approved.**

### Phase 3 — Content + art families (~10 h) ☐
1. Remaining enemies (zoomer, chonk) and weapons (Candy Cane Orbit, Jingle Pulse) — as data + art.
2. Props: pine trees, snowdrifts, gift piles, candy-cane posts, a blue-and-white camel pennant (original art, no college logo).
3. Simple animation: bob/waddle vertex shader for enemies, squash-and-stretch tweens for Claus.
4. Balance pass: spawn curve, damage, XP so a run feels good across 5 minutes.
- **Checkpoint 3:** full run with all content; you playtest and list what feels off.

### Phase 4 — UI, juice, audio (~6 h) ☐
1. Title screen, HUD, level-up cards with upgrade icons, win/lose screens — using the palette.
2. Juice: hit flash, damage numbers, small screen shake, pickup pop, death poof particles.
3. SFX + music loop; audio buses (music / SFX volume).
- **Checkpoint 4:** feature freeze. From here, only bug fixes.

### Phase 5 — Ship (~6 h, the protected buffer) ☐
1. Final web export; test in Chrome + one other browser; check load time and console errors.
2. Upload to the host (likely itch.io as an HTML5 game — free, playable in-browser), page with
   pitch, controls, screenshots, credits.
3. Submit to the hackathon **well before** the deadline. Tag the commit `v1.0-demo`.
- **Checkpoint 5:** you play the public link on a different device.

## Godot structure (follows `CONVENTIONS.md`)

```
scenes/main/main.tscn           world, camera, spawner, HUD — the main scene
scenes/player/player.tscn       Claus
scenes/enemies/enemy.tscn       one enemy scene, configured by an EnemyData resource
scenes/weapons/<weapon>.tscn    one scene per weapon behavior
scenes/pickups/xp_ornament.tscn
scenes/ui/                      hud, level_up_menu, title, end_screen
scripts/game_state.gd           autoload: run timer, XP, level, signals (level_up, run_ended)
resources/enemies|weapons|upgrades/*.tres
assets/models|textures|audio/   imported art;  art_src/ Blender sources
```

## Quentin's glossary (Godot/Blender in Maya/Unreal terms)

| Term | What it is | Closest thing you know |
|------|-----------|------------------------|
| Node | A single building block (mesh, camera, timer, script holder) | Unreal Component |
| Scene (`.tscn`) | A saved tree of nodes; reusable and nestable (a player, an enemy, a level) | Unreal Blueprint class / Level |
| Instancing | Placing a copy of a scene inside another | Placing a Blueprint actor |
| GDScript (`.gd`) | Godot's Python-like scripting language | Blueprint graph / C++ |
| Signal | An event a node emits; others connect to it | Event Dispatcher |
| Autoload | A script that's always loaded, globally reachable | GameInstance / Subsystem |
| Resource (`.tres`) | A saved data object (enemy stats, weapon data) | Data Asset |
| MultiMesh | Draw thousands of copies of one mesh in one call | Instanced Static Mesh |
| Renderer: Compatibility | Godot's simpler OpenGL renderer, required for web | Mobile/ES3 preview |
| Export template | Prebuilt engine runtime per platform, used when exporting | Platform SDK for Packaging |
| Export preset | Saved export settings for one platform | Packaging settings |
| `.glb` | Single-file 3D model format (mesh + material + texture) | FBX |
| Object / Edit mode (Blender) | Move whole objects / edit vertices | Maya Object / Component mode |
| Bake (Blender) | Render a procedural material into a flat image texture | Maya Transfer Maps / Arnold bake |
| Nearest filtering | Texture pixels stay sharp squares instead of blurred | Unreal texture filter "Nearest" |

## Open questions (decide before the phase that needs them)

- **Hackathon rules** (before Phase 5): exact deadline + timezone, where to submit, required
  format. AI-generated art is **assumed allowed** (Quentin, 2026-11-10) — re-check if rules say otherwise.
- **Audio source** (before Phase 4): CC0 packs (e.g. Kenney), generated chiptune SFX, or AI audio?
- ~~Conn College branding~~ **Decided:** no official logo/wordmark; school colors and the Camel only.
- **Host** (before Phase 5): itch.io (default) vs the hackathon's own site.
