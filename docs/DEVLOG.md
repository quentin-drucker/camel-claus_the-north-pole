# Camel Claus — Devlog

Running notes, decisions, progress and reports. Newest entry on top.
Claude appends an entry after any meaningful work session; add your own thoughts anywhere.

Entry format: `## YYYY-MM-DD — short title`, then what changed, why, and what's next.

---

## 2026-11-13 — New Frost Imp shipped as the production Chaser

- Replaced `assets/models/chaser.glb` with the approved sculpted Frost Imp while preserving its UID,
  wrapper scene, gameplay scale, collision/data and shared GPU waddle animation.
- Re-rendered `assets/ui/renders/chaser.png` as a transparent 96x96 portrait from the same baked model;
  this updates the Snowball Fight achievement stamp and the HUD bonk icon together.
- Refreshed Godot imports: one baked 512x512 lossless albedo with mipmaps, no imported animation or
  light baking. Removed the old extracted Chaser texture.
- Verified the GLB buffers (3,450 triangles, one mesh/surface/material, valid packed UVs, no rig), then
  ran the review scene and live main scene through Godot 4.7.2 Compatibility with zero runtime errors
  or warnings. Release Web export and GitHub Pages publication follow in this change.


## 2026-11-13 — Sculpted Frost Imp model and baked asset review

- Built the user's approved furry Frost Imp concept as a new asset, preserving the current Chaser.
  Continuous remeshed/decimated body, shaped muzzle, curved horns, swept fur locks and expressive eyes.
- Export: 3,450 triangles, one surface/material, one packed 512x512 albedo, 0.70 m height,
  ground-center origin, Blender +Y / Godot -Z forward, no rig. Procedural painted-color and
  occlusion source materials are baked into a real UV atlas; none are required at runtime.
- Added source/rebuild script, editable Blender files, UV layout, GLB validation and rendered previews.
- Created the standalone `frost_imp_review.tscn` using Godot MCP scene/node tools. It compares front,
  elevated and small views and offers a 100-instance view with the existing waddle shader.
- Checked through `godot_run_start` in process mode and `godot_run_output` at error level:
  zero errors/warnings in the successful review. 100 instances rendered with the Compatibility
  renderer: 346,058 total primitives and 207 draw calls including shadows and review UI.
  This is a local render check, not a Web gameplay FPS claim.
- Updated ART_DIRECTION with the user's expanded palette/gradient permission and provisional
  higher-detail enemy budget. Model acceptance and live-game replacement remain for user review.


## 2026-11-13 — Loadout clarity, one look per cosmetic, settings toggles, title hat

- **Loadout:** players didn't know what to do there. Now two numbered steps ("1. Pack up to 3 weapons" with
  a packed counter; "2. Choose your starting weapon"), each with one help line; cards wear Starter /
  Packed / Locked tags on their border, slots say "Starts with you" / "Joins at level-ups", and a sentence
  by Start run says what will happen.
- **Customize:** picking a hat/outfit color left the default color showing (the baked shading has more
  shades than the two-swatch swap). Removed recolors: every hat and outfit has one look; skins still
  recolor the body (every fur shade is in their swap list). Old saves drop `hat_color` / `outfit_color`.
- **Settings:** the On/Off switches showed Godot's default grey toggles (right-to-left CheckButtons use the
  `*_mirrored` icons, which the theme didn't set); now the sweater-button switch like the hybrid, plus
  chevron arrows on Interface size and the knit plate (`PlateTightKnit`).
- **Title:** the menu's Santa hat sits 10 px higher, on top of the C.
- Guide (`art_reference/GUI_Style_Guide`) updated: loadout layout, keycap hints, toggle/selector details,
  one look per cosmetic, new roles/helpers, and lessons (prototype parity check, mirrored icons, recolors).
- Checks: all suites 0 failed; text fit 122 screens, 0 problems.

## 2026-11-13 — Phase 8 pass 2: the game now matches the approved A+ hybrid screen by screen

Quentin played the GitHub Pages build and found many gaps against the approved HTML hybrid (settings,
menu controls, no Credits, trophy icons everywhere). Every screen was cross-checked against
`design_prototypes/` (`showcase.js` concept "h") and the guide's `screens/` captures, then rebuilt:
- **Main menu:** Credits button + Credits page (Godot, Blender, art/music made with Claude Opus 5.5, Kenney
  CC0 sounds, OFL fonts); "Best runs" top-3 table (`Profile.data.top_runs`, seeded from old bests); red
  Workshop badge (affordable upgrades); controls as snow keycaps on a dark bar (`Tin.key_hint`); version
  bottom right; goal cards use each achievement's own stamp picture.
- **Data:** `AchievementData.icon` + `category`, `CosmeticData.picture` + `description` (renders from the
  prototype, `assets/ui/renders/`, 96 px).
- **Settings:** header band + close X; Sound / Display / Gameplay sections; % values; new options
  Interface size (scales the HUD corners), Screen shake, Damage numbers, Reduce motion
  (`Audio.options`, saved in `settings.cfg`).
- **Achievements:** count + bar + coins earned in the header, category tabs with progress, per-goal
  stamps, coin rewards, "Delivered" + tick.
- **Customize:** picture tiles (renders, skin swatch rings, price), detail panel with Equip / Buy /
  Equipped and colors, the camera moves in so Claus is the live preview.
- **Level up:** rarity tags, `old → new` numbers, 1-3 keys + keycaps, Reroll/Banish with keycaps and
  uses left above.
- **HUD:** coin + bonk counters, objectives checklist (survive 5:00, defeat the Yeti), Santa count +
  Space keycap, achievement toasts show the goal's own picture.
- **Pause:** three plates (Your build with level pips / Paused with run numbers + buttons / Stats).
- **Results:** postcard with pills, Damage table (new `GameState.damage_by`, every `deal_damage` names
  its source), Summary, Unlocked (+ next goal); the HUD hides behind it.
- Stats page as two tables, Loadout with the header band; new theme roles (CloseButton, KeyCap,
  HintBar, Badge, Pill, SubLabel, NameLabel, TabName, BadLabel...).
- Checks: all suites 0 failed; text fit 122 screens, 0 problems; balance bot seeds 3 and 4 WIN; web
  release: loader -> intro -> menu with 0 console errors.
- Next: Quentin replays the live build (Checkpoint 8).

## 2026-11-13 — Phase 8 built: "Workshop Tin" A+ hybrid UI in the game (awaiting Checkpoint 8)

- **Style guide / template** for this game and future ones (hackathon): `art_reference/GUI_Style_Guide/`
  (`Camel_Claus_GUI_Style_Guide.md` = tokens, every component, layouts, motion, intro, Godot recipe, file map,
  lessons; `screens/` = 13 captures of the approved prototype). Title font **New Rocker** (Quentin's pick),
  body/numbers **Tiny5**, logo **Bowlby One** (all OFL). ART_DIRECTION's UI section now points to it.
- **Foundation:** UI textures generated by `art_src/tools/make_ui_textures.py` (`assets/ui/tin/`); one theme
  generated by `art_src/tools/build_ui_theme.gd` with type variations for every role (replaces ~90 per-node
  font-size overrides tuned for Kenney Pixel); `Tin` helper (`scripts/ui/tin.gd`); `FocusBrackets` autoload
  (corner brackets on hover/focus); `Transition` now drops a **knitted curtain** instead of fading.
- **Screens:** main menu in Megabonk's layout (logo + hat, centered slabs, knit goal cards with stamps, best run,
  coins, postmark); level up as rarity rows (knit, rays, luggage tag, counted Reroll/Banish); bare outlined
  HUD with an airmail achievement toast; pause with knit build tiles; settings with sewn sweater-button
  sliders/toggles; Workshop knit cards; **Achievements as a postcard** (stamps, postmarks, "Delivered");
  Customize with tabs and knit nameplates; loadout; **results as a "Greetings from the North Pole!" postcard**
  with a Claus stamp. Damage numbers now Tiny5. Old `cozy_pixel_theme.tres` and the Kenney fonts removed.
- **Startup:** `scenes/ui/splash.tscn` is the main scene (Knit + Tin intro: needles knit the logo in 12 rows,
  yarn ball, pine plate, Claus pops in, hat drops on the C; any key skips; full once, then a 2x sting via
  Profile `seen_intro`; editor runs skip it unless `camel_claus/always_show_intro`). Boot splash: no image,
  knit-red background. Web: custom shell `web/shell.html` (generated by `art_src/tools/make_web_shell.py`):
  the scarf loader grows with Godot's real download progress and fades into the identical red.
- **Fixes found on the way:** earned run-only achievements showed 0/target; Settings toggles were shrunk by
  Button's icon cap; achievement toast and boss banner could leave the screen (toast also froze while paused);
  three scenes had lost their UID header after the headless migration (restored, `--import`).
- **Checks:** all suites pass (game_state, profile, upgrades, weapons, santa) and **text fit: 136 screens, 0
  problems** (rule update: meta `decor` for deliberate overhangs; the old "shrunk below 48 px" rule went with
  the pixel font). Balance bot runs. Release web export played in a browser: loader -> intro -> curtain ->
  menu -> loadout -> run -> pause, 0 console errors.
- **Open:** in the headless test browser, Enter didn't confirm "Start run" on the web build (Space and clicks
  did; Enter works natively): please check with a real keyboard at Checkpoint 8. `scenes/ui/title_screen.tscn`
  is still an untracked orphan (points at a deleted script); safe to delete.
- Next: Checkpoint 8 (Quentin plays the web build), then publish (`docs/PUBLISHING.md`).

## 2026-11-12 — A+ hybrid prototype + readable title font (HTML only)

- Quentin chose **A Workshop Tin** as the base, with touches of B (sweater) and D (postal). New concept
  **A+ Hybrid** in the UI showcase (first tab): A's rules are untouched (`ui/concept_a.css`), and
  `ui/concept_h.css` layers on top only for the hybrid stage:
  - from B: knit texture behind cards (offers, goals, customize tiles), a Fair Isle camel trim under every
    panel header, sewn wooden sweater buttons as slider/toggle knobs, and the knitted-curtain screen wipe;
  - from D: stamp-framed reward icons, postmarks (finished achievements, picked upgrades, menu), an airmail
    toast, a luggage-tag level badge, a postcard achievements list and a "Greetings from the North Pole"
    postcard on the results screen. HUD stays plain A.
- **Font**: the pixel blackletter (Jacquarda Bastarda 9) was hard to read. Titles/buttons now default to
  **Germania One** (blackletter flavor, clean shapes); a switcher under the stage compares Grenze Gotisch,
  New Rocker and the original. Body text stays Tiny5 (pixel).
- Splash: new **Knit + Tin** (default tab): B's knitting intro rebuilt with A's logo and riveted plate,
  ending on the A+ menu through the same knitted curtain.
- Next: Quentin confirms the font and the hybrid; then plan the Godot implementation.

## 2026-11-12 — UI overhaul + splash exploration (HTML prototypes only, awaiting direction)

- **No game files changed.** Everything lives in `design_prototypes/` (has a `.gdignore`, 2.4 MB):
  `camel_claus_ui_showcase.html` (5 concepts × 9 screens, compare-all mode) and
  `camel_claus_splash_showcase.html` (5 intros, each paired with a UI concept, playing web loader →
  engine boot → intro → that concept's live menu). Open either file directly in a browser.
- Concepts: **A Workshop Tin** (Megabonk-style riveted plates, slab buttons, corner-bracket focus),
  **B Ugly Sweater** (knit + Fair Isle camel band, hanging/swaying), **C Northern Lights** (bevelled ice
  panels, aurora, night diorama), **D Polar Expedition** (paper field kit, slanted buttons, signal
  tape), **E 8-Bit Holiday** (9-slice pixel frames, arcade cursor, stepped motion; uses our Kenney fonts).
  All keep Megabonk's information design (rarity rows with before → after stats, counted reroll/banish,
  panel-free HUD, quest rows, two-column stats).
- Research: Megabonk's Steam store + community screenshots (main menu, upgrade offers, quests, stats,
  HUD, results) plus Quentin's references. Notes are in the showcase's "What we took from Megabonk".
- Assets: backdrops are fresh in-game captures (menu diorama, gameplay) with UI hidden; sprites are the
  game's own models rendered in Godot to transparent PNGs by a throwaway script (not in the repo).
  Fonts are OFL (Google Fonts) or our Kenney CC0 fonts, stored locally.
- Startup recommendation (in the splash page): custom HTML shell loader driven by Godot's real
  progress → `boot_splash/show_image = false` with matching `bg_color` → `splash.tscn`
  (AnimationPlayer, skippable, skipped in the editor via `OS.has_feature("template")`) → menu via
  `Transition`.
- Next: Quentin picks/mixes a direction; then refine the HTML, then implement in Godot.
- Noticed: `scenes/ui/title_screen.tscn` is untracked and points at a deleted `title_screen.gd`
  (left over from the Phase 5 menu change); left untouched.

## 2026-11-11 — Published on GitHub Pages (v1.1)

- Repo made public by Quentin (now `quentin-drucker/camel-claus_survivors_workflow-test`). Phases 6-7
  committed as `4ec0df0`, tagged **v1.1**, pushed. Release web build pushed to a `gh-pages` branch
  (build files only + `.nojekyll`); GitHub Pages serves it at
  **https://quentin-drucker.github.io/camel-claus_survivors_workflow-test/**. Checked live: all files
  200 (`index.wasm` 39.5 MB as `application/wasm`), the game boots to the main menu, title "Camel Claus:
  The North Pole", 0 console errors. Update steps in `docs/PUBLISHING.md`. itch.io: later (Quentin).

## 2026-11-11 — Esc vs browser fullscreen, demo code, livelier menu scene

- **Esc in browser fullscreen** (Quentin: Esc both paused and left fullscreen). Browsers own Esc in
  fullscreen; two layers now:
  1. **Keyboard Lock API** (`Transition._lock_escape()`, web only, once at boot): in Chrome/Edge, when the
     game is the top-level page (GitHub Pages, own site), Esc reaches the game while fullscreen (pause)
     and the browser shows "Press and hold Esc to exit full screen". Verified: lock granted in Chrome on
     localhost. Not possible inside an iframe (itch.io's embed) or in Firefox/Safari — the promise just
     rejects quietly.
  2. Everywhere: **leaving fullscreen mid-run opens the pause menu** (PauseMenu watches the window
     mode), with a 0.4 s guard so the Esc that left fullscreen can't immediately close it again.
     Verified in the release build: browser exits fullscreen during a run -> paused.
  Menu hint now "Pause: Esc / P" (P never touches fullscreen). Settings also closes on Esc on the main
  menu now (it only did inside the pause menu).
- **Secret demo code** (`scripts/demo_code.gd`, autoload `DemoCode`): typing **hohoho** anywhere —
  release builds too — unlocks every weapon, cosmetic, Workshop level and achievement and sets 99,999
  coins (`Profile.unlock_everything()`); mid-run it also puts every loadout weapon at Lv 5 and fills
  Santa's meter, so an evolution is one Space away. Gold toast "Ho ho ho!" + evolve jingle. H and O have
  no bindings, so typing it mid-fight doesn't move/pause/call Santa. Writes the real save: Settings >
  Reset progress undoes it. Covered by test_santa (typed through the real input handler).
- **Livelier menu scene** (Quentin: add the Yeti behind the cast): the **Grumpy Yeti** looms back-left
  (breathes, and every 6.5 s a heavy little stomp with a snow burst), a **Snowball Lobber** on the right
  winds up now and then, the **ice bat** circles overhead instead of standing still, and **Santa's
  Sleigh** sweeps across the back of the scene every 12 s with its gold trail. Composed so Claus's
  silhouette stays clear (the Yeti first stood right behind him and swallowed his hat).
- Checks: all suites pass, text-fit 136 screens; release web build: demo code, keyboard lock,
  fullscreen auto-pause and the menu scene checked in Chrome, 0 console errors.

## 2026-11-11 — Phase 7: living world, camel customization, fullscreen fix (awaiting Checkpoint 7)

**World**
- **Boundary ridge** (`prop_scatter.gd`, shared by the game and the menu diorama): a continuous ring of
  overlapping snowbanks (drift model, 2.4-3.4x, flattened, random turn) whose foot sits on the invisible
  wall (59 m), snowy rocks every ~9 m (new `rock` model), then 3 jittered rows of pines (64 / 67.5 /
  71.5 m) that get taller outward. In game it reads as "the snow and forest stop you here".
- **Enemy spawns near edges**: the spawn ring used to be clamped onto the wall, dropping imps right on
  Claus when he hugged it (seen in the browser). Now it tries other angles around him first and only
  clamps as a last resort (`EnemySpawner.arena_limit` 58 m).
- **Backdrop** (`scenes/world/backdrop.tscn`, in both scenes): 450 distant pines (one MultiMesh), two rings
  of low-poly snowy mountains (new `mountain` model, 54 tris), a pixel moon, 70 stars, a slow pixelated
  aurora (`aurora.gdshader`, additive, faint). One shared `assets/materials/world_environment.tres`: a sky
  gradient (deep blue top -> snow-blue horizon) and **depth fog from 60 m** so far layers fade into the
  horizon while the play area stays crisp. Ground planes grew to 700 m. Ambient light is still the fixed
  colour, so the approved look of Claus and the critters is unchanged. Menu camera aimed a bit higher so
  the sky, mountains and aurora show above the forest.
- **Alive** (`prop_sway.gdshader` on the prop MultiMeshes): pines sway, candy-cane posts wobble, pennants
  flutter, each with a phase from its position so nothing moves in sync; gift-pile gold ribbons twinkle.
  Pines shed a little snow now and then near Claus, and whenever he brushes past one.
  **Footprints** (`scenes/player/footprints.gd`): one pooled MultiMesh of 64 prints (one draw call), a print
  every 0.42 m alternating left/right, turned to his heading, fading over 4 s; pale snow-shadow blue so
  it never competes with gameplay. A tiny snow puff at the hooves every 5 prints.

**Fullscreen**: the Settings checkbox now mirrors the real window state every frame it is open
(`set_pressed_no_signal`), so leaving fullscreen with the browser's Esc unticks it. Verified in Chrome:
toggle on -> browser exits fullscreen -> box shows off. Fullscreen isn't saved on the web (browsers only
allow it after a click). Esc while fullscreen is eaten by the browser to exit fullscreen; P also pauses.

**Customization** (main menu > Customize Camel; cosmetic only)
- Claus's model was split (no visual change) into **body**, **Santa hat** and **scarf** loose parts
  (`art_src/claus_parts.blend`); new pieces modelled in the same space: **elf hat, bobble beanie, reindeer
  antlers (+ red nose), Christmas sweater, elf collar, Santa coat**. `claus_model.tscn` is now the
  `ClausLook` node that dresses Claus from the Profile; the player and the menu both instance it, so the
  look shows in game and the menu's Claus is the live preview.
- **One palette-swap shader** (`palette_swap.gdshader`) recolors exact palette swatches: skins swap the
  camel swatches on the body, colors swap a hat's/outfit's main pair. Every variant stays inside the
  ART_DIRECTION palette, nothing is re-baked, adding a color is one line.
- Data: `CosmeticData` + `resources/cosmetics/*.tres`, listed in `Profile.COSMETICS`. 6 skins (Classic Tan,
  Cocoa, Cream free; Frosty 120, Evergreen 150, Golden 300), 5 hats (none, Santa, Beanie free; Elf 100,
  Antlers 150), 5 outfits (none, Scarf free; Elf Collar 100, Sweater 120, Santa Coat 180). Hats/outfits
  have 2-5 colors (red, green, blue, gold, ice; no purple = danger). Saved in the profile (`look`,
  `cosmetics_owned`); a stale or unowned piece falls back per slot. Buying asks first ("Buy for 120?").
  "Default look" restores tan + red Santa hat + blue scarf and keeps purchases.
- Customize screen: Skin / Hat / Outfit tabs, 2-column list (Wearing in gold, Owned, padlock + price),
  color swatches for the worn piece, Default look, Back; Esc closes.

**Checks**: all suites pass. `test_profile` adds cosmetics (free/paid ownership, buy once, colors limited
to the item's options, stale look fallback after reload, default look keeps purchases). **The text-fit
audit was measuring a square 1280x1280 headless window**; it now letterboxes to the real 1280x720 canvas
and that exposed a real bug: the pause menu ran 4 px off-screen with a huge Endless build (fixed: build
slots 80 px tall, tighter spacing). 136 screens, 0 problems, incl. the Customize tabs fresh and fully owned.
Debug web build in Chrome: menu depth, Customize (Cocoa skin + blue beanie recolor live), the look in the
run, footprints, the ridge at the north edge, fullscreen sync, look persists across a page reload; 0
console errors, ~180 fps.

**Balance (final pass)**: after the edge-spawn fix runs got easier (random picks 9/10). Enemy HP now
doubles every **115 s** (was 120; 110 was too harsh at 2/10): random picks **10/15 wins, every loss at
4:38-4:53** (the climax); focused builds win nearly always and evolve 2-3 weapons; Endless adds ~2-3 min
for a strong build.

## 2026-11-11 — Feedback round: Lobbers, Santa HUD, Endless mode, reset, rename "Camel Claus: The North Pole"

**Quentin's feedback**: Lobbers died before ever throwing; the Santa bar overlapped its label; suggested
lowering Gift Toss damage; asked for Endless mode, a reset-progress button and the new name.

- **Lobbers** (measured first: the bot now logs snowballs thrown every 30 s): they walked into Gift Toss's
  14 m range before their own 11 m throw range and waited a random 1-3 s, while 2 gifts killed them in
  ~1.4 s. Fixed on the Lobber side: throw range 14 m (= on screen), hold at 10 m, first throw ready
  0.3-1 s after arriving, HP 16 -> 26. Throws by 2:00 went from avg 10 to 16, by 2:30 from 34 to 48.
  **Gift Toss damage kept at 12**: it one-shots the 10 HP imps of the first minute (they gain HP over
  time), which is most of the opening's feel; at 10 every imp would need two hits within seconds.
- **Santa HUD**: label and bar sat in a container with -4 px separation; now +4.
- **Endless mode**: after surviving 5:00 the results screen offers **Keep going** (gold). Same run, no
  time limit, clock counts up in gold, banner "ENDLESS! HOW LONG CAN CLAUS LAST?". Past 5:00 enemy HP also
  doubles every 60 s and enemy hits grow +100% per minute (`GameState.enemy_damage_mult`); an elite every
  40 s and a Yeti every 2 min with double the HP of the last (each gets its banner). When it ends the
  results screen shows again with what the Endless part added: `Profile.record_run()` records only the
  part since the last record (`GameState.record_base`), so no second run, win bonus or double stats.
  New best "Longest Endless run", new achievement **Endless Night** (reach 8:00, 100 coins).
  Once every card is maxed, level-ups skip the menu and heal 2% (a first try gave a 25% heal card, and
  late Endless makes ~230 level-ups/min: immortal and a menu every quarter second).
- **Reset progress**: Settings (main menu only, hidden mid-run), two presses ("Really erase all progress?
  Press again"), then `Profile.reset()`; the main menu's best line and coins refresh.
- **Renamed** to **Camel Claus: The North Pole** (project name = window and browser tab title; main menu
  "CAMEL CLAUS" + ice-blue "THE NORTH POLE" subtitle; new tagline). Note: on desktop builds Godot's
  user folder follows the project name, so old desktop settings don't carry over (web saves are unaffected).
- Balance bot now **steps out of purple rings** like a player (it ignored them, which made Lobbers look
  far deadlier than they are). Results: random picks 8/10 wins (deaths 3:39, 4:28); focused + Endless
  9/10 win 5:00 and then last until 7:18-8:33.
- Test fix: a freed node compares equal to `null` in Godot 4, so the Lobber dodge test re-grabbed later
  snowballs; it tracks "seen" with a flag now.

## 2026-11-11 — Phase 6.4: Blizzard, Gingerbread Boomerang, ship build (awaiting Checkpoint 6.4)

**Built**
- **Blizzard event** (`scenes/main/blizzard_event.gd`, once per run at 2:45 for 20 s, 2 s fades): critters
  walk 35% slower (`GameState.enemy_speed_mult`, read by the spawner) but snow hides ornaments, so pickup
  reach is 30% shorter: a breather that rewards walking to your XP. Banner "BLIZZARD! CRITTERS SLOW DOWN -
  GRAB YOUR XP", white frost at the screen edges only, faster snowfall, music dips 5 dB. Changes are applied
  as deltas (picks made during it stay correct) and the music dip resets if you leave mid-blizzard.
  Santa's Sleigh stays the main special; this is the only random-feeling beat (it's actually fixed).
- **Gingerbread Boomerang** (6th weapon): throws gingerbread men in a fan toward the nearest critter; each
  eases out 6 m (+6%/Lv) and flies back to wherever Claus is, hitting everything once each way — moving
  sideways while they return sweeps a fresh line. 12 dmg, 1.5 s, +1 cookie at Lv 3/5. **Gingerbread
  Rampage**: +2 cookies, x1.6 hitbox, 40% further, crumb trails, x1.5 damage. Unlock: new achievement
  **Sweet Tooth** (survive 3:00 in a run), then 150 coins. Collector now needs 6 weapons.
  Damage trimmed 14 -> 12 after the bot won 8/10 with it as starter (now ~6/10 like the others).
- Achievement toast moved to the bottom-right corner (under the timer it overlapped menu titles).
- Loadout cards narrowed to fit 6 weapons in a row; long names wrap.
- Release web build re-exported to `build/web/` and `build/camel-claus-web.zip` (13 MB, pck 3.5 MB).
  `docs/ITCH_PAGE.md` updated: loadout, Santa, reroll/banish, Lobbers, pickups, Workshop/achievements,
  new controls, and a note that progress lives in the browser.

**Checks**: all suites pass (test_weapons now 6 weapons; its dodge check judges only the dodged ball, since
a later throw can aim at Claus's new spot; test_santa covers the Blizzard), text-fit 130 screens 0 problems
(it caught the Gingerbread card text overflowing by 14 px). Debug web build: all 6 weapons Lv 5 + the
300-enemy stress wave at ~182 fps, 0 console errors; the achievement toast shows and reads well.
Learned: headless `--import` runs while the editor is open can leave the UID cache stale ("Unrecognized
UID" for every autoload, `Profile` null in tests) — rerun `--import`.

**Phase 6 summary for Quentin's playtest**: pick a loadout -> level up (reroll/banish) -> fill Santa's
meter -> evolve a Lv 5 weapon or take a blessing -> survive Lobbers, elites, the Blizzard and the Yeti ->
results screen pays coins -> Workshop / unlock weapons / achievements -> next run. Open questions are in
PLAN.md's backlog (Hard/Endless mode, reset-progress button, Area stat).

## 2026-11-11 — Phase 6.3: meta-progression (awaiting Checkpoint 6.3)

**Built**
- **Christmas Coins**: every run pays 1 coin per 10 kills + 1 per 10 s survived + 15 per elite + 60 for
  the Yeti + 50 for surviving (`Profile.run_coins`). A win is ~300 coins, a loss at 2:30 ~75, so losing
  still buys something and a win isn't required to progress. Achievements pay extra.
- **Workshop** (main menu): 7 permanent upgrades as `WorkshopData` resources (`resources/workshop/`), small
  steps with rising prices: Cozy Sweater +10 max HP x5 (40-320), Hoof Wax +4% move x4 (50-260), Sharper
  Bows +5% damage x5 (60-420), Shiny Baubles +5% XP x4 (50-290), Long Scarf +10% pickup x3 (40-160),
  Second Wish +1 reroll x3 (80-320), Naughty Eraser +1 banish x2 (100-240). All maxed: +50 HP, +16% move,
  +25% damage, +20% XP, +30% reach, 5 rerolls, 3 banishes, about 4,300 coins (~15-20 runs). Applied at
  run start (`Profile.apply_workshop`, `GameState.start_run`). Names differ from in-run cards on purpose.
- **Weapon unlocks**: Snowball Barrage and Ornament Mines start locked. An achievement makes each
  *buyable* for 150 coins in the Workshop: Critter Control (300 lifetime kills) and Crown Collector
  (defeat one elite) — both usually within the first 1-2 runs, so new weapons come quickly.
- **Achievements**: 16 `AchievementData` resources (`resources/achievements/`): a stat key, a target, a
  coin reward and an optional weapon unlock. Mix of combat (100 / 1000 kills in a run, elite, Yeti),
  progression (evolve 1 / 2 / 3, carry 3 weapons, call Santa 4x), survival (survive 5:00, survive without
  being hit), collection (3 loadouts, 5 Workshop levels, every weapon). Checked live once a second during a
  run (toast under the timer: trophy, title, reward; doesn't pause; queued if several) and at run end.
  Lifetime goals count the run in progress until it is recorded, so nothing is counted twice.
- **Lifetime stats and personal bests** (`Profile.record_run()`, once per run via the results screen):
  runs, wins, deaths, kills, damage dealt/taken, time, coins earned, evolutions, Santa calls, elites,
  Yetis, XP; bests for longest run, kills, damage, evolutions, level, plus the build of the most-kills run.
- **Main menu**: best-run line under the tagline, Play (> loadout) and a compact row Workshop (with the
  coin count) / Achievements (n/16) / Stats; controls line mentions Space for Santa. The three pages are one
  `MetaPanel` script with a `page` setting (title, coins, scrolling list, Back/Esc).
- **Results screen**: result + build icons (evolved icons) + a two-column summary: damage, Santa calls,
  evolved weapons | coins earned with the breakdown, new records, achievements earned, coin total.
- `Profile.save_path` is a variable: tests, the text-fit audit and the balance bot use
  `user://test_scratch_profile.json`, so they never touch the player's real progress.

**Checks**: new `tests/test_profile.gd` on a scratch save: fresh defaults, loss payout (75), a run is
recorded once, stats added once, first-run goals and their coins, goals earned once, unlock -> buy (150) ->
can't buy twice / without coins, Workshop price sum and cap (Cozy Sweater 800 total, +50 HP), records and
bests, save/load round trip, an old save missing keys with a removed weapon, a corrupt save kept aside.
All other suites pass; test_text_fit 122 screens incl. the three pages fresh and with huge numbers, 0
problems (content inside a ScrollContainer is no longer flagged as off-screen: it is clipped, not cut).
Debug web build: after a run and a **full page reload** the menu still shows the best run and the coins
(IndexedDB persistence works); Workshop and Achievements pages checked in Chrome.
Not checked by eye: the results screen and the achievement toast (covered by the text-fit audit only).

**Next**: 6.4 polish & extras (Blizzard event, Gingerbread Boomerang, audio/visual polish, perf check).

## 2026-11-11 — Phase 6.2: Santa's Sleigh, loadouts, reroll/banish (awaiting Checkpoint 6.2)

**Built**
- **`Profile` autoload** (`scripts/profile.gd`): everything that survives between runs, one JSON file
  `user://profile.json` (IndexedDB on the web) with a `version`, defaults for missing keys, unknown weapon
  ids dropped on load, atomic save (write `.tmp`, then rename), an unreadable save kept as
  `profile.corrupt.json` instead of silently lost. `data` starts as the defaults so `-s` tests that run
  before autoload `_ready()` still work. It also owns the **weapon catalog** (`WEAPON_CARDS`; a weapon's id
  is its scene file name) used by the loadout, the level-up pool and (6.3) unlocks.
- **Loadout** (main menu > Play > `LoadoutPanel`): up to 3 unlocked weapons, one marked as starter (gold
  border, "START" slot); Esc/Back returns. Claus starts with only the starter (`player.tscn` no longer has
  a hard-wired Gift Toss); the other two appear as "new weapon" cards. Locked weapons show a padlock and
  how they unlock. Saved in the profile, so the last loadout is preselected.
- **Level-up pool rules** (`LevelUpMenu.level_up_pool()`): not maxed, not banished, new weapons only from
  the run's loadout and only while Claus has a free hand (3). Weapon cards weigh 1.2 vs 1 for stat cards.
- **Reroll** (2 per run, R) and **Banish** (1 per run, B: arm it, then click the card; it leaves the run's
  pool and the level-up stays open with fresh cards). Level-ups only; the row hides on chests and Santa.
- **Santa's Sleigh**: `GameState.register_kill()` charges a meter (kills per charge **8 / 180 / 300 / 420**,
  then +100 each). A full meter **holds** (extra kills don't bank) until Space/E. HUD bottom-left: sleigh
  icon + bar + "Santa's Sleigh 23/180", gold pulsing "SANTA READY! [Space]" and a one-time teaching banner,
  plus a chime. The sleigh (new model: red sleigh, gold runners, gift sack, one reindeer) sweeps over Claus
  in 2.2 s with a gold trail and a sleigh-bell + Jingle Bells cue, drops **Santa's present** (new model: green
  box, red ribbon, gold star) 2.5 m from Claus inside the arena; it lands with a snow blast (pushes normal
  enemies out to 4.5 m, freezes 1.5 s, 10 dmg) and flies to Claus after 3 s, so it is never lost.
- **Santa's present menu** (warm wood-brown backdrop, its own title): every Lv 5 weapon offers its
  evolution (up to 3 cards); otherwise 3 of 6 **blessings** (`BlessingData`, `resources/blessings/`):
  Hot Cocoa x2 damage 20 s, Reindeer Rush +50% move & attack speed 20 s, Christmas Spirit x2 XP 30 s,
  Mega Magnet (all XP now + triple reach 25 s), Snow Angel (can't be hurt 8 s, ice rings), Blizzard
  (instant: freeze all within 18 m for 4 s, -30% HP to normal enemies, -5% to elites/boss). Timed blessings
  apply reversible deltas (so stat picks during one stay correct), refresh instead of stacking, and show
  icon + seconds in the HUD. **Gift chests no longer offer evolutions** (items only).
- `GameState` now holds the run's loadout, rerolls/banishes, the XP multiplier (fractional XP carries
  over), Santa state, and central run totals: damage dealt/taken, elites/bosses killed, evolutions, XP
  collected (for the results screen and lifetime stats in 6.3). Evolutions go through
  `GameState.evolve_weapon()`.
- Icons: 6 blessings, sleigh, Santa's present, reroll, banish (+ coin, trophy, lock for 6.3).

**Bugs found and fixed while testing**
- The run's starting weapon was read before the run started (`Player._ready` runs before `main._ready`), so
  runs started with the previous loadout's starter. `main.gd` now starts the run in `_enter_tree()`.
- The sleigh flew 7 m up, outside the narrow camera; now 3.2 m, offset toward the camera so it crosses
  the middle of the screen right over Claus.
- Loadout details were empty until a card got focus; the starter's details show on open.
- Test harness: scene tests now fail after 180 s instead of hanging when a script error stops them.

**Balance (bot, 10 seeds each; `focus` = new bot mode that builds on purpose, holds a full meter while a
weapon is Lv 4 and rerolls when no weapon card is offered)**
- First tuned at 8/120/220/320 kills with weapon-card weight 1.6: focused builds evolved at ~1:20 and often
  evolved all three. Now 8/180/300/420 + weight 1.2; late pressure raised (enemy HP doubles every 120 s
  instead of 130, final surge x2.5 instead of x2, Yeti 6000 HP instead of 4500 - it died in 15-20 s).
- Results: random picks (`collect`, default loadout) **5-6/10 wins**, 3-4 Santa calls, an evolution in
  about half the runs (first at 1:48-4:45). `focus` default loadout **7/10**, first evolution 1:45-2:50,
  usually 2-3 evolutions. Area loadout (Snowball starter + Mines + Jingle) **5/10** focused, after buffing
  Snowball (cooldown 1.6 -> 1.3 s, splash 1.6 -> 1.8 m). Mines starter with random picks **5/10** after
  buffing Mines (cap 3 -> 4, cooldown 1.1 -> 0.9 s, trigger 1.0 -> 1.3 m; it was 3/10). Deaths cluster at
  4:20-4:50. A fresh profile at ~55-65% leaves room for the 6.3 permanent upgrades.

**Checks**: new `tests/test_santa.gd` (meter thresholds + holding, the full call -> sleigh -> present ->
menu flow with two presents, blessings undo exactly, evolution vs blessing choice, chests items-only,
loadout-only weapon cards, rerolls run out, banish removes a card and keeps the level-up open);
test_weapons, test_game_state, test_upgrades pass; test_text_fit 116 screens (now incl. loadout details,
blessing cards, banish prompt, HUD with all blessings), 0 problems. Debug web build in Chrome: loadout
screen, Santa ready -> sleigh fly-over -> landing blast -> Santa's present screen, 0 console errors.

**Next**: 6.3 meta-progression (coins, Workshop, unlocks, achievements, stats, results screen).

## 2026-11-11 — Phase 6 planned; 6.1 combat variety built (awaiting Checkpoint 6.1)

**Why**: Quentin's expansion brief (Vampire Survivors / Megabonk-style progression: more weapons, an
evolution for every weapon, Santa's Sleigh, loadouts, reroll/banish, meta-progression). The full design
and its decisions live in `PLAN.md` → Phase 6; this log records what got built and why.

**Done (6.1)**
- Credits: "Claude" removed from the main-menu credits line and the itch page (the itch page keeps an
  "AI-assisted pipeline" line without the product name; itch asks creators to disclose AI assets).
- **Evolution rule**: a weapon at Lv 5 can evolve; the item requirement is gone (`WeaponData.evolution_item`
  deleted). Reason: with a 3-weapon loadout the second key only adds luck. Santa's Sack is now a plain
  +1 projectile item; **Sleigh Bells → Silver Bells** so "Sleigh" only ever means Santa's ability.
  Until Santa's Sleigh exists (6.2) a gift chest still offers the evolution.
- `WeaponData.level_area_bonus` + `radius_at(level, evolved)`: area weapons grow a little per level
  (orbit/pulse +5%/Lv, snowball splash +10%/Lv, mine blast +8%/Lv). `radius_label` names it in UI text.
- **Peppermint Cyclone** (Candy Cane Orbit evolution): +2 canes, orbit x1.5, spins x1.5, canes get
  red trails and every 2.5 s each cane flings straight out (pierces 3) and regrows in 0.7 s.
  Flung canes reuse `GiftProjectile` (new `body_scene`, `trail_color`, `hit_burst`); the sparkle trail
  moved to `Poof.trail()` for reuse.
- **Snowball Barrage**: every 1.6 s lobs snowballs (1, +1 at Lv 3/5) in a 0.65 s arc at the nearest ~8
  enemies (shuffled, leading their walk) — splash 1.6 m, 10 dmg. The blob shadow under the flying
  snowball marks where it lands. **Avalanche**: +1, 40% wider, x1.5 dmg, each splash bursts into 4
  fragments that hop 2.4 m and splash again (40% dmg, 55% radius).
- **Ornament Mines**: every 1.1 s drops a mine a step behind Claus, up to 3 on the ground (+1 at Lv 3/5);
  arms in 0.35 s, blinks, blows up (26 dmg, 2 m) when an enemy gets within 1 m, or after 14 s.
  **Chain Reaction**: +2 mines, blast x1.2, a blast sets off mines within 2.2x its radius (0.12 s ripple)
  and rings a second blast 0.18 s later (x1.6 radius, 50% dmg).
- Art (pixel_bake pipeline, all palette-only): `snowball` (ice-blue, 172 tris), `enemy_snowball` (snow
  with purple bands = danger), `ornament_mine` (green + gold studs, clearly not the gold XP bauble),
  `magnet` (red horseshoe, white tips), `cookies_milk` (on a red plate so it pops off the snow),
  `snow_bomb` (navy + ice band, gold fuse spark), `lobber` enemy (456 tris, 64 px: navy imp, purple eyes,
  holds a purple-banded snowball overhead — the silhouette says "ranged").
- Icons: Snowball Barrage / Avalanche, Ornament Mines / Chain Reaction, Peppermint Cyclone.
- SFX generated in `make_audio.py` (appended after the existing renders, so music/jingles are
  byte-identical — checked with md5): splash, mine drop, magnet sweep, heal chime, enemy lob.

- **Snowball Lobber** (`resources/enemies/lobber.tres`, from 1:15, weight 0.15, **max 6 alive**, 16 HP,
  3 XP): `EnemyData` got a Ranged group (`keep_distance` 8 m, `throw_interval` 3.2 s, `throw_range` 11 m,
  `throw_damage` 12, `throw_windup` 0.6 s, `throw_flight` 1.0 s) and `max_alive`. The spawner holds ranged
  types at their distance (backs off at 60% speed when Claus walks within keep − 2 m). `EnemySnowball`:
  purple ring grows at Claus's feet during the wind-up while the Lobber stops and wobbles, then a 1 s arc;
  it only hits if Claus is still in the ring (1 m), so any movement dodges it. Killing the Lobber during
  the wind-up cancels the throw. At most 30 enemy snowballs alive.
- **Ground pickups** (`PickupData` + `resources/pickups/*.tres`, one `Pickup` scene): Christmas Magnet
  (0.4%/kill, 30 s cooldown — every XP ornament on the map rushes in), Cookies & Milk (0.5%, 25 s — heals
  25% max HP; waits on the ground while HP is full), Snow Bomb (0.3%, 35 s — pops normal enemies within
  7 m, freezes everything within 10.5 m for 2 s, deals 10% max HP to elites/boss). At most one pickup per
  kill; they live 40 s and blink for the last 5. XP ornaments now accelerate (8 → 34 m/s) when pulled,
  which turns a magnet into a satisfying stream.
- **3-weapon cap** (`Player.MAX_WEAPONS`): new-weapon cards stop once Claus carries 3.
- Fixes found by testing: freed mines crashed the typed `filter` lambda in `OrnamentMines` (now a plain
  validity loop); mines dropped under a standing Claus were hidden (now a random side step); Avalanche
  fragments drew one ice ring each and blanketed the screen (fragments now only puff).

**Checks**
- New `tests/test_weapons.gd` (`--fixed-fps 60`): each weapon alone vs 14 still tough enemies for 4 s, Lv 1
  then evolved — Gift Toss 72 → 3024, Candy Cane 99 → 648, Jingle 210 → 1386, Snowball 90 → ~3050,
  Mines 624 → 4633 dmg (evolved > Lv 1 for all). Also magnet / cookies / snow bomb behaviour, Lobber hits a
  still Claus and misses one who steps out of the ring. All pass; test_game_state, test_upgrades and
  test_text_fit (101 screens) pass.
- Balance bot, 10 seeds, random picks: **6/10 wins**, deaths at 3:15–4:39, 23–28 level-ups, evolutions
  reached in 4/10 runs even with random picks (Present Barrage ×2, Avalanche, Chain Reaction). Boss now
  dies in 14–22 s when reached (was usually survived) — revisit with Santa/blessings in 6.2.
- Debug web build in Chrome: 0 console errors, ~240 fps with all five weapons evolved + boss (more than
  a real run's 3). Screens checked: credits line, evolution card, Peppermint Cyclone ring + flung canes,
  Carol of the Bells, mines, Lobber ring at Claus's feet.
- "N resources still in use at exit" in headless runs predates 6.1 (same on a stash of the old code).

**Next**: 6.2 (Santa's Sleigh, loadouts, reroll/banish). Checkpoint 6.1 is open for Quentin's playtest.

## 2026-11-11 — Card titles cut off; text-fit test

- Bug: long card names ("Faster Wrapping", "Candy Cane Orbit", "Christmas Cracker") were clipped because
  the "Lv1>2" label sat beside the name. The level now shares the small top row with the tag, and a name
  that still doesn't fit at 48 px drops to 32 px (pixel font stays crisp at multiples of 16).
- New `tests/test_text_fit.gd`: puts every screen in its wordiest state (every upgrade/item/evolution card
  at common and Epic, fresh and full build, all banners, HUD with a full build, every pause-menu slot,
  settings, win/lose screens) and fails if a label's text is wider than the label, or a control sticks out
  of the screen or its card. 86 screens, 0 problems after the fix. Release web build and zip re-exported.
- Next: Quentin uploads to itch.io (docs/ITCH_PAGE.md).

## 2026-11-11 — Polish pass + Phase 5 (ship prep)

**Polish (Quentin's request, done while he was away)**
- **Music** rewritten (`make_audio.py`): warm music box / soft lead / pads / round bass, light reverb,
  low-passed (energy >2 kHz down from 9% to ~0.1%), 112 BPM, 2:09 arrangement with the verse + chorus,
  seamless loop; plays continuously across menu, runs and restarts; ducks while paused. New evolve jingle.
- **Icons**: 1 px navy outline (readable on snow), evolved variants for Gift Toss / Jingle Pulse,
  clearer Chimney Draft.
- **Level-up / chest cards**: compact header (icon, type tag, name, level), effect with real before >
  after numbers from the game formulas, evolution hint with progress; borders by type (new weapon gold,
  weapon upgrade ice, item tan, evolution gold on wood-brown); focus pops the card.
- **Evolutions**: Present Barrage = gold-wrapped gifts with a star, sparkle trail, gold pop on hit;
  Carol of the Bells = golden bell over Claus that swings, double gold+ice ring. Acquisition: banner
  with the evolved icon, evolve jingle, gold/ice burst, shake. "READY" badge + banner when requirements
  are met. Weapon formulas moved into `WeaponData` (single source for gameplay and UI).
- **Pause menu** (Esc/P): build grid (icons, level/EVO/READY, details + evolution progress on focus) and
  stats vs base (green better / red worse / white unchanged, tooltip lists sources); Resume, Settings,
  Restart run, Main menu.
- **Main menu scene** (snowy diorama, Claus + critters, snowfall, swaying camera), shared Settings panel
  (music, sounds, fullscreen), `Transition` fade for every scene change; end screen freezes, fades in,
  shows the build and offers Play again / Main menu. Snowfall during runs too.
- F2 "can't take damage" = the stress test's intended god mode; the HUD now says "GOD MODE (F2 debug)".

**Phase 5**
- Debug keys + FPS readout are debug-build only; export excludes `addons/godot_mcp` and `tests/`
  (pck 3.6 -> 3.0 MB). Boot splash navy, project name "Camel Claus".
- Release web build tested in **Chrome and Firefox**: engine up in ~2.2 s locally, 0 console errors,
  menu -> run -> pause identical in both. Upload zip `build/camel-claus-web.zip` (12.9 MB).
- `docs/ITCH_PAGE.md`: upload steps + page text; screenshots in `docs/media/`. Tagged `v1.0-demo`.

**Blocked on Quentin**: itch.io upload (needs his account), hackathon submission (deadline/site unknown),
listening check of music/SFX, test on a weaker machine.

## 2026-11-11 — Phase 4: UI, juice, audio (awaiting Checkpoint 4)

**Done**
- UI style decided (Quentin): **cozy pixel**. Project theme `assets/ui/cozy_pixel_theme.tres`: Kenney Pixel
  font (CC0), navy panels, gold trim, palette rarity borders. Canvas textures default to nearest.
- **Title screen** over the paused world (Play, Music/Sounds sliders saved to `user://settings.cfg`, credits);
  "Play again" skips it. Bigger HUD: HP numbers, gold level, big timer, row of owned weapon/item icons with
  Lv/EVO/xN badges, boss bar + "THE GRUMPY YETI APPROACHES!" banner. Restyled level-up/chest cards with
  21 pixel icons (`art_src/tools/make_icons.py`) and win/lose panel with kill count.
- **Juice**: enemy hit flash + frozen (ice tint, stops waddling) + poisoned (green) via shader looks; floating
  damage numbers (capped at 40); snow-cube poofs on deaths and chests; camera shake on hits, explosions,
  elite/boss deaths and boss arrival.
- **Audio**: `Audio` autoload, buses Music/SFX. Kenney CC0 SFX (throw, hit, pop, XP chime that rises with
  combos, hurt, explosion, freeze, clicks, boss charge). Music + jingles generated by
  `art_src/tools/make_audio.py`: 8-bit "Jingle Bells" (public domain) as two synced stems — the drive layer
  fades in at 3:30 — and level-up / chest / win / lose / boss jingles. Music ducks for the boss.
  Credits in `assets/CREDITS.md`.

**Checks**: 0 script errors, tests pass, sims unchanged in shape. Web: ~215 fps (full loadout + 300
enemies), 0 console errors. Audio not checked by ear (Claude can't listen).

**Next**: Checkpoint 4 = feature freeze. Then Phase 5 (ship).

## 2026-11-11 — Phase 3: content + art families (awaiting Checkpoint 3)

**Done**
- Checkpoint 2 approved (Claus, imp, snow).
- Weapons share a `Weapon` base (level 1–5, reads global stats, damage via `Player.deal_damage` so
  items proc). New: **Candy Cane Orbit** (canes circle Claus) and **Jingle Pulse** (area burst +
  knockback). Weapon cards in the level-up pool ("NEW WEAPON" / "Lv N").
- **Elites** at 1:00/2:00/3:00/4:00 (x1.6 size, x15 HP, gold crown) drop a **gift chest** → pick 1 of 3
  **items** (11, our own: Spiced Dates, Sleigh Bells, Santa's Sack, Hay Bale, Fruitcake poison, Christmas
  Cracker explosions, Icicle freeze, Naughty List, Snow Globe cheat-death, Chimney Draft, Lump of Coal).
- **Evolutions** offered in a chest: Gift Toss Lv5 + Santa's Sack → Present Barrage; Jingle Pulse Lv5 +
  Sleigh Bells → Carol of the Bells.
- **Grumpy Yeti** boss at 4:15 (walk/wind-up/charge, HP bar), spawn surge x2 from 4:30.
- Art (same pipeline): zoomer ice bat, chonk grumpy pine, yeti, crown, chest, candy cane; props (snowy
  pines also ring the arena edge, drifts, gift piles, cane posts, camel pennants) via MultiMesh.
- Animation: enemy waddle/bob vertex shader (GPU, phase from world position); Claus hops while walking,
  breathes when idle, squashes when hit.
- Debug keys for testing: F3 skips 30 s, F4 gives every weapon at Lv 5 + both evolution items + a chest.

**Balance (bot, random picks)**: XP growth back to +4/level, enemy HP doubles every 130 s, spawns every
130 s, boss 4500 HP. ~65–75% wins, deaths mostly 4:20–4:55, ~19 level-ups, 5 chests per run.
Web: ~154 fps with 300 enemies + every weapon evolved + props; 0 console errors.

**Issues**: windowed Godot games crash on this PC right now (stack overflow even for a brand-new empty
project; editor fine) — environmental, verified via web build instead. Editor-state gotchas (stale
autoload, stale scene script, UID cache) added to CONVENTIONS.

**Next**: Checkpoint 3 — Quentin plays full runs and lists what feels off. Then Phase 4 (UI, juice, audio).

## 2026-11-11 — Phase 2: visual target built (awaiting Checkpoint 2)

**Done**
- Reusable Blender pipeline `art_src/tools/pixel_bake.py`: primitives + palette materials → join →
  one Cycles color bake → palette snap → single nearest-filtered material → `.glb` + `.blend`.
- Models (all original, palette-only): **Claus** (chibi camel, Santa hat, blue/white scarf; 634 tris,
  64 px), **chaser** frost imp (round blue plush, purple glaring eyes, angry brows, fangs, icicle
  horns; 472 tris, 64 px), **gift** projectile (bigger, wide gold ribbons, chunky bow — per Checkpoint 0
  feedback; 176 tris, 32 px), **XP ornament** bauble (104 tris, 32 px).
- In game: Claus turns toward where he walks (starts facing the camera); enemies face Claus; gifts
  spin in flight; ornaments turn. Blob shadows under Claus, enemies and ornaments. Claus ×1.25 and
  chaser ×1.3 to hit the on-screen size targets (~70 px / ~45 px).
- Ground: world-space pixel snow shader (drifts in the 3 snow swatches, rare ice sparkles) — no
  visible tiling, no longer flat white. Noted as a deliberate change in ART_DIRECTION.
- Removed the Phase 0 throwaway gift. Zoomer/chonk stay tinted capsules until Phase 3.

**Checks**: 0 script errors; tests pass; balance sims unchanged (visual-only change). Web: 300
modelled enemies + shadows at ~174 fps in Chrome (was ~210 with capsules), 0 console errors.

**Learned**: an externally edited Resource script keeps its old property list in the editor even
after a focus rescan; writing it with `godot_files_write` fixes it (added to CONVENTIONS).

**Next**: Checkpoint 2 — Quentin approves the look or we iterate; then fill "Visual target".

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
