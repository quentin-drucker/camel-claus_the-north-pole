# Camel Claus: The North Pole — Plan

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
| Enemies | 3 types: **chaser** (basic), **zoomer** (small, faster than Claus), **chonk** (slow, tanky); **elites** at 1:00/2:00/3:00/4:00; **final boss** ~4:30 | Ranged enemies |
| Weapons | 3: **Gift Toss** (shoots nearest enemy), **Candy Cane Orbit** (spins around Claus), **Jingle Pulse** (area burst); 1–2 **evolutions** (max weapon + matching item) | More weapons |
| Progression | XP → level-up pauses → pick 1 of 3. Global stat upgrades (apply to every weapon), **level cap 5**, **rarity rolls** (common/rare/epic). **Items** (~10–12, our own designs) from elite chests | Reroll/banish, luck, meta-progression |
| Run | 5:00 timer with designed beats (see "Five-minute arc"); survive = win, die = lose, restart | Endless mode, score |
| UI | Title, HUD (HP, XP bar, level, timer), level-up menu, win/lose screen | Settings, pause menu |
| Audio | ~5 SFX + 1 music loop (source TBD, see Open questions) | Adaptive music |
| Performance | **300 enemies on screen at 60 fps in Chrome** | 1000+ via MultiMesh |
| Ship | Web build playable from a public link | Desktop builds |

## Phases (hackathon budget ~42 h; leave the last ~20% for shipping)

### Five-minute arc (design target, from the 2026-11-11 research — see DEVLOG)

Short run = a deliberate strength: fast levels, few but strong choices, fixed beats, a climax.
Player power and enemy toughness should both roughly **double every ~90 s**.

| Time | Player | Enemies / events |
|------|--------|------------------|
| 0:00–0:45 | Level-ups every ~5–8 s | Chasers only, 1–2 hits to kill |
| 0:45–2:00 | Build takes shape; 2nd weapon offered | Zoomers join (outrun Claus); **elite 1:00 → chest** |
| 2:00–3:30 | Commit to a build | Chonks join; elites 2:00/3:00 |
| 3:30–4:30 | Power peak; evolution | Intensity music layer; elite 4:00 |
| 4:30–5:00 | Climax | Final boss + spawn surge; survive → sleigh arrives |

Rules: Megabonk / Vampire Survivors are **pattern references only** — no 1:1 copy of their item
roster, names or numbers (balance doesn't transfer to 5 min; IP). ~20 level-ups and ~5 items per run.

### Phase 0 — Pipeline smoke test (~2 h) ✅ (approved 2026-11-10)
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

### Phase 1 — Greybox core loop (~8 h) ✅ (Checkpoint 1 played 2026-11-11 → feedback drove Phase 1.5)
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

### Phase 1.5 — Balance & systems pass (~4 h) ✅ (added and done 2026-11-11; Quentin moved on to Phase 2)
Fix what Checkpoint 1 found before spending time on art. Still greybox.
1. Contact damage you can feel: discrete hits + short invulnerability, blink while hurt, HP numbers.
2. Enemies: zoomer + chonk as data (greybox colors), spawn table with unlock times; far-away
   enemies are recycled to the ring ahead of Claus.
3. Difficulty as curves: enemy HP doubles every ~90 s, spawn rate grows exponentially.
4. Upgrades: global stats (damage ×, attack speed %, +projectiles) shared by all weapons; level
   cap 5 (projectiles 2); rarity rolls on cards.
5. Headless **balance bot** (`tests/balance_sim.gd`) that plays a run and logs level/HP/enemies,
   to tune XP so a run gives ~20 level-ups.
- **Checkpoint 1.5:** you replay in the browser: can you get hit, does it ramp, do picks matter?

### Phase 2 — Visual target (~5 h) ✅ (approved 2026-11-11)
1. Blender: **Claus** (Santa hat + scarf), **one gift/XP ornament**, **chaser** enemy, **snow
   ground tile**, each baked to pixel textures within `ART_DIRECTION.md` budgets.
2. Swap them into the greybox; view at 1280×720 through the game camera.
- **Checkpoint 2:** you approve the look (or we iterate). Then fill in "Visual target" in
  `ART_DIRECTION.md`. **No more art until this is approved.**

### Phase 3 — Content + art families (~10 h) ✅ (Quentin moved on to Phase 4, 2026-11-11)
1. Systems, in order (greybox meshes first, art after):
   a. Weapons share a `Weapon` base (level 1–5, reads global stats); **Candy Cane Orbit** and
      **Jingle Pulse**; weapon cards in the level-up pool (new weapon / level up).
   b. **Elites** at 1:00/2:00/3:00/4:00 (bigger, gold crown, ×HP) drop a **gift chest** → pick 1 of 3
      **items** (11, our own designs; stats + on-hit procs + utility).
   c. **Evolutions**: Gift Toss + Santa's Sack → Present Barrage; Jingle Pulse + Sleigh Bells →
      Carol of the Bells (offered in a chest when the weapon is level 5 and you own the item).
   d. **Final boss** (Grumpy Yeti) at 4:15 with a charge attack and an HP bar; spawn surge from 4:30.
   Art: zoomer (ice bat), chonk (grumpy walking pine tree), elite crown, yeti, candy cane, chest.
2. Props: pine trees, snowdrifts, gift piles, candy-cane posts, a blue-and-white camel pennant (original art, no college logo).
3. Simple animation: bob/waddle vertex shader for enemies, squash-and-stretch tweens for Claus.
4. Balance pass: spawn curve, damage, XP so a run feels good across 5 minutes.
- **Checkpoint 3:** full run with all content; you playtest and list what feels off.

### Phase 4 — UI, juice, audio (~6 h) ✅ (2026-11-11, plus a polish pass: softer music, compact cards,
evolution visuals/feedback, pause menu with build + stats, main menu scene, fade transitions)
1. Title screen, HUD, level-up cards with upgrade icons, win/lose screens — using the palette.
2. Juice: hit flash, damage numbers, small screen shake, pickup pop, death poof particles.
3. SFX + music loop; audio buses (music / SFX volume).
- **Checkpoint 4:** feature freeze. From here, only bug fixes.

### Phase 5 — Ship (~6 h, the protected buffer) ☐ — 1 done, 2 prepared (`docs/ITCH_PAGE.md`; needs Quentin's itch login), 3 tagged `v1.0-demo`
1. Final web export; test in Chrome + one other browser; check load time and console errors.
2. Upload to the host (likely itch.io as an HTML5 game — free, playable in-browser), page with
   pitch, controls, screenshots, credits.
3. Submit to the hackathon **well before** the deadline. Tag the commit `v1.0-demo`.
- **Checkpoint 5:** you play the public link on a different device.

### Phase 6 — Roguelite expansion ✅ built 2026-11-11, checkpoints 6.1-6.4 open for Quentin (added from his expansion brief)

**Loop in one line:** *pick 3 weapons, grow them to Lv 5, call Santa to evolve them, bank coins for the next run.*
Megabonk / Vampire Survivors stay pattern references only (same rule as above).

**Design decisions (resolving the brief's open points)**
- **Evolution = weapon Lv 5 + a Santa's Sleigh present.** The item requirement (Santa's Sack, Sleigh Bells)
  is dropped: with a 3-weapon loadout the second key just adds luck. Those two items stay as normal items;
  "Sleigh Bells" is renamed **Silver Bells** so "Sleigh" only ever means Santa's ability.
- **Gift chests** (elites, boss) keep giving items only; evolutions leave chests in 6.2 (6.1 keeps the
  chest as the temporary evolution source so new evolutions are testable before Santa exists).
- **Max 3 weapons carried** (from 6.1). With loadouts (6.2) the run's pool *is* those 3 weapons.
- **Santa's Sleigh meter:** kills charge it; thresholds per activation are data (first 8 kills, then
  ~120 / 220 / 320, +100 after), tuned on the bot's kill curve (≈90 kills @1:00, 410 @3:00, 1000 @5:00)
  for **3–4 calls per run** (tuned to 8 / 180 / 300 / 420 in 6.2). A full meter **holds** (no stockpiling) until you press **Space**: use it now
  for a timed blessing, or save it for a Lv 5 weapon. The present lands next to Claus with a snow blast
  that clears space around it and homes to him after a few seconds, so it is never unreachable.
- **Santa's present:** Lv 5 weapons → pick which evolves. None → pick 1 of 3 **blessings** (timed, shown
  with a HUD timer): Hot Cocoa (×2 damage), Reindeer Rush (move + attack speed), Christmas Spirit (×2 XP),
  Mega Magnet (all XP now + bigger reach), Snow Angel (invulnerable), Blizzard (freeze + damage all on screen).
- **Ground pickups** (no menu): Christmas Magnet (all XP rushes to Claus), Cookies & Milk (heal 25%),
  Snow Bomb (pops normal enemies near Claus, freezes the rest, chips elites/boss). Rare, with a per-kind
  cooldown so they never clutter.
- **Currency: Christmas Coins**, earned from kills, time survived, elites/boss and a win bonus
  (scaled so a 2:30 loss still buys something). Shop upgrades are small, capped, multi-step.
- **Persistence:** one `Profile` autoload (meta: coins, shop levels, unlocks, loadout, achievements,
  lifetime stats, bests) saved as JSON in `user://profile.json` with a `version` field and defaults for
  missing keys. `GameState` stays per-run. Stats are counted once, at run end, from `GameState`'s run totals.

**Conflicts flagged (art direction / web)**
- *Value rule (no white on white snow):* enemy snowballs get a purple `#9B4FD1` core and a purple landing
  ring (purple = danger); Claus's snowballs are ice-blue `#7FD6F2`, the Snow Bomb is navy with an ice band.
- *Ornament Mines vs XP ornaments:* mines are green + gold, sit flat and blink; XP stays as it is.
- *Blizzard event "lower visibility" vs readability:* edge-only white vignette + denser (capped) snowfall,
  never over the play area's centre.
- *Web:* `user://` lives in the browser's IndexedDB (per site; clearing site data wipes progress — say so
  on the itch page). Single-threaded is fine. Space can scroll an itch page if the canvas loses focus, so
  **E** also calls Santa. New projectiles/mines are capped per weapon; enemy projectiles capped at 30.
- *Credits:* "Claude" removed from in-game credits (Quentin's call). The itch page keeps an "AI-assisted
  pipeline" line without the product name — itch.io asks creators to disclose AI-generated assets.

**6.1 — Combat variety (Priority 1)** ✅ built 2026-11-11 (awaiting Checkpoint 6.1; details in DEVLOG)
1. Credits cleanup. Evolution gate = Lv 5 (item requirement removed), 3-weapon cap.
2. **Candy Cane Orbit → Peppermint Cyclone:** wider, faster ring of big canes that fling outward as
   piercing projectiles every few seconds and regrow.
3. **Snowball Barrage** (lobbed arcs, splash on landing; Lv: damage/count/radius) **→ Avalanche**
   (bigger snowballs that burst into 4 hopping fragments that splash again).
4. **Ornament Mines** (dropped where Claus walks, blow up when enemies come close; Lv: damage/cap/radius)
   **→ Chain Reaction** (a blast sets off nearby mines + a second, wider ring).
5. **Snowball Lobber** enemy (from 1:15): keeps ~8 m away, winds up with a purple ring under Claus, lobs a
   slow arc you can sidestep; capped number alive.
6. Ground pickups: Christmas Magnet first, then Cookies & Milk, Snow Bomb.
7. Art (pixel_bake pipeline), icons, SFX; weapon-fires test; balance bot ×10.
- **Checkpoint 6.1:** play the web build: do the new weapons feel distinct, is the Lobber fair, do pickups pop?

**6.2 — Santa & builds (Priority 2)** ✅ built 2026-11-11 (awaiting Checkpoint 6.2; details in DEVLOG)
1. `Profile` autoload + save file (loadout first). Pre-run **Loadout** screen: 3 of the unlocked weapons,
   one marked as starter; only those 3 are offered as new weapons.
2. Santa's Sleigh: meter in the HUD, Space/E, sleigh fly-over (new model), present + snow blast, Santa
   present screen (evolutions or blessings, more festive than level-ups), blessing timers in the HUD.
3. Chests stop offering evolutions; texts say "call Santa's Sleigh" instead of "find a chest".
4. **Reroll** (2/run) and **Banish** (1/run, removes that card for the run) on the level-up screen.
5. XP + card weights re-tuned with a new bot mode `focus` (commits to its weapons, calls Santa) so a
   focused build evolves its first weapon around 2:30–3:30 and sometimes a second.
- **Checkpoint 6.2:** you play several runs with different loadouts.

**6.3 — Meta-progression (Priority 3)** ✅ built 2026-11-11 (awaiting Checkpoint 6.3; details in DEVLOG)
1. Christmas Coins + run-end payout; **Workshop** shop (Max HP, move, damage, XP, pickup reach, rerolls,
   banishes — 3–5 small steps each, rising prices).
2. Weapon unlocks: an achievement makes a weapon *buyable* for 150 coins (Snowball Barrage: 300 lifetime
   kills; Ornament Mines: defeat an elite; list in `resources/achievements/`).
3. Achievements (data resources: condition + target + reward), toast that doesn't pause, menu page.
4. Lifetime stats + personal bests (with the best run's build), statistics page, small best-run line on
   the main menu.
5. Main menu: Play (→ loadout) · Workshop · Achievements · Stats · Settings. Results screen: time, kills,
   damage, build with evolutions, coins earned, new records, new achievements.
- **Checkpoint 6.3:** progress survives a browser reload; a lost run still feels worth it.

**6.4 — Polish & extras (Priority 4)** ✅ built 2026-11-11 (Blizzard + Gingerbread Boomerang + perf/web check;
Hard/Endless stay in the backlog; awaiting Checkpoint 6.4)
1. Blizzard event (once per run, ~2:45: enemies slowed, snow thickens at the edges, music filter).
2. One more weapon if 6.1–6.3 are solid: **Gingerbread Boomerang** (returns; rewards movement) — picked
   over Snowflake Shurikens, which would be another straight projectile next to Gift Toss.
3. More achievements, audio polish, web performance check with every new weapon evolved.
- Deferred to the backlog: **Hard mode**, **Endless mode** (only after the 5-minute run is balanced).
- **Checkpoint 6.4:** release candidate; re-export, re-tag.

### Phase 7 — Living world + camel customization ✅ built 2026-11-11 (awaiting Checkpoint 7; details in DEVLOG)

**Design decisions**
- **Boundary = a snowbank ridge with a forest on it.** A continuous ring of overlapping snowbank pieces
  (varied size/rotation, so no visible repeat) sits right on the invisible wall (59 m), with 3 jittered
  rows of pines and some rocks behind it. The wall stays where it was, so collision matches the visuals.
  Enemies now spawn/recycle inside the arena (they used to be able to appear beyond the wall near edges).
- **Backdrop = one shared scene** (`scenes/world/backdrop.tscn`) in both the game and the main menu:
  2 layers of low-poly snowy mountains, a distant tree line (MultiMesh), a soft sky gradient, a moon and
  a slow aurora ribbon, plus distance fog so far layers fade (atmospheric perspective). The game camera
  mostly looks down, so it only peeks at it near the edges; the menu camera sees all of it.
- **Alive, not noisy**: pines and candy-cane posts sway with a vertex shader (phase from world position,
  so nothing moves in sync — same trick as the enemy waddle), pines near Claus now and then shed a small
  puff of snow, candy-cane posts glint, gift piles' lights twinkle; **footprints**: one pooled MultiMesh
  (64 prints), placed per step at the hooves' side, fading out over ~4 s — one draw call, no new nodes.
  Snow puffs at the hooves while running.
- **Fullscreen**: the checkbox mirrors the real window/browser state every frame it is visible (Esc in a
  browser leaves fullscreen without the game being told otherwise). Fullscreen isn't saved on the web
  (browsers only allow it after a click).
- **Customization** (cosmetic only, no stats): Claus is split into **body + hat + outfit** pieces; skins
  recolor the body and colors recolor a hat/outfit with one **palette-swap shader** (swaps palette swatches,
  so every variant stays inside ART_DIRECTION's palette and nothing needs re-baking). Items are data
  (`CosmeticData`), saved in Profile, shown in game and on the menu (the menu's Claus *is* the preview).
  Free from the start: 3 skins, Santa hat and beanie (any color), scarf; others cost 100-300 coins.
  **Art-direction flag**: no purple accessories (purple = danger) and no all-white skin (the value rule:
  Claus must pop off the snow) — "Frosty" is ice-blue instead.

**7.1** fullscreen sync · boundary ridge · backdrop · living props · footprints
**7.2** customization: split model, new hats/outfits, palette swap, Customize screen, coins, persistence
- **Checkpoint 7:** Quentin plays in the browser: does the edge read as "can't go there", does the menu
  have depth, is it alive but readable, do cosmetics feel worth earning?

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

## Backlog (noted, not scheduled yet — pull into a phase when it fits)

- Done (Phase 5): debug keys F2/F3/F4 + FPS readout work only in debug builds (`OS.is_debug_build()`);
  `addons/godot_mcp` and `tests/` excluded from the export. Still to do: performance on weaker hardware.
- Check by ear (Claude can't listen): music loop seam, SFX volumes/picks, jingles. Pitch variation uses
  `pitch_scale` per play (no AudioStreamRandomizer).
- Cosmetic: HUD timer shows 0:01 behind the win screen.
- Separation uses one radius for all enemies, so big chonks overlap small ones; use per-type radius if it looks bad with art.
- Bot win rate ~65–75% with random picks (deaths mostly 4:20–4:55 = the climax); re-check with Quentin's
  playtest. Boss is usually survived, rarely killed (4500 HP).
- Windowed Godot game launches crash on this PC (stack overflow even for an empty new project; the editor
  is fine) — environmental, likely driver/overlay; reboot. Web build unaffected. Use the web build to test.
- Stretch: luck stat, more items. (Reroll/banish done in 6.2.)
- Done after Phase 6: **Endless mode** (Keep going after a win), Settings "Reset progress", the rename.
- Phase 6 follow-ups (not built): **Hard mode**; a global
  "Area" stat card (would make Jingle/Snowball/Mines/Boomerang interact more with upgrades, but adds a 7th
  stat card to the pool); a 7th weapon (Snowflake Shurikens was skipped: too close to Gift Toss).
- Not checked by eye yet (Claude): the results screen and the music/SFX for Phase 6 (audio by ear).

## Open questions (decide before the phase that needs them)

- **Hackathon rules** (before Phase 5): exact deadline + timezone, where to submit, required
  format. AI-generated art is **assumed allowed** (Quentin, 2026-11-10) — re-check if rules say otherwise.
- ~~Audio source~~ **Decided** (2026-11-11): CC0 packs, cozy jingle-bell chiptune — see `ART_DIRECTION.md`.
- ~~Conn College branding~~ **Decided:** no official logo/wordmark; school colors and the Camel only.
- **Host** (before Phase 5): itch.io (default) vs the hackathon's own site.
