# Camel Claus — Conventions

Rules that keep code, scenes and assets consistent. Claude follows these on every change.
Add a rule here when you notice drift; don't add rules "just in case".

## GDScript

- Follow the official Godot GDScript style guide. Godot 4 / GDScript 2.0 only.
- Static typing everywhere: `var speed: float = 5.0`, typed function args and returns.
- Files and folders `snake_case`; `class_name` in `PascalCase`; constants `UPPER_SNAKE`.
- Signals named in past tense (`died`, `gift_collected`); connect in code with `signal.connect(callable)`.
- Prefer `@export` values over hard-coded tuning numbers.
- Data (items, stats, upgrades) as custom `Resource` (`.tres`), not dictionaries in code.

## Scenes

- One responsibility per scene; compose with instanced child scenes.
- Edit scenes through the Godot MCP tools, never by hand-editing `.tscn` text.
- Script lives next to its scene with the same name (`player.tscn` + `player.gd`).
- Each `.glb` gets a wrapper scene that inherits it (e.g. `scenes/props/gift_test.tscn`); instance the wrapper, never the `.glb` (the MCP tools can't instance `.glb`).
- Textures Godot extracts from a `.glb` (`assets/models/<name>_<image>.png`) must be re-imported with `compress/mode=0` (lossless) and `mipmaps/generate=false`; the default is VRAM compression, which smears pixel art.

## Folders

```
scenes/      gameplay scenes grouped by feature (player/, enemies/, levels/, ui/)
scripts/     shared scripts not tied to one scene (autoloads, utils)
resources/   .tres data
assets/      models/, textures/, materials/, audio/, fonts/  (imported art)
art_src/     .blend and other source files; has .gdignore so Godot won't auto-import .blend
docs/        devlog, art direction, these conventions
```

## Godot MCP gotchas

- Scripts written from outside Godot aren't registered until the editor rescans, which it does when its window gets focus. After creating new `.gd` files, focus the Godot window before using their `class_name`s.
- New `class_name` scripts written from outside sometimes never register ("Identifier not declared") even
  after focusing Godot; re-save them with `godot_files_write`.
- Changing a **Resource** script's fields from outside: the editor keeps the old property list (focus doesn't fix it). Write those scripts with `godot_files_write` so the editor reloads them, then set `.tres` values with `godot_resource_set`.
- Add an autoload only after its script compiles; if it was added while broken, remove and re-add it.
  Rewriting the autoload script from outside can also break it in the editor ("Identifier not found:
  GameState" everywhere) — same fix: `godot_autoload_edit` remove + add.
- A scene open in an editor tab keeps the old version of its script's exports; `godot_scene_close` it and
  set properties again (the tool reopens it).
- Headless `--import` runs while the editor is open can leave the UID cache stale: every autoload then
  shows "Unrecognized UID" and `root.get_node("Profile")` is null in `-s` tests. Rerun `--import`.
- New resources get UIDs in the editor before its UID cache reaches disk; headless runs then warn "invalid
  UID". Run `godot --headless --path . --import` once before tests/sims.
- `-s` test scripts: the tree isn't live during `_initialize`, so `_enter_tree` doesn't run — set
  `GameState.player` by hand.
- A script's `@export` fields can't be set in the same call that attaches the script; prefer `preload()` defaults in the script for data resources.
- A freed node compares equal to `null`: use `is_instance_valid()` (and a separate flag if you need to
  know it existed), never `node == null`, to tell "gone" from "never set".
- Never pass possibly-freed nodes to a typed lambda (`filter(func(m: Mine) ...)` errors "Cannot convert
  argument 1 from Object to Object"); loop and check `is_instance_valid()` instead.
- Don't `git stash` while the editor is open: it swaps files under open scene tabs. If it happens, close
  those tabs with `godot_scene_close` (discard) so a stale copy can't be saved back.
- Headless windows are square (1280x1280): `test_text_fit.gd` letterboxes the root to the 1280x720 design
  canvas (`content_scale_aspect = KEEP`); any new layout test must do the same or height bugs hide.
- Cosmetics are data: a piece = a model in Claus's space (see ART_DIRECTION) + wrapper scene in
  `scenes/player/cosmetics/` + a `CosmeticData` .tres + its line in `Profile.COSMETICS`. Skins recolor the
  body by swapping palette swatches (`palette_swap.gdshader`); hats and outfits keep their own baked
  look (two-swatch recolors left the default color showing through), so a new color = a new piece.
- After changing UI layout, fonts or any name/description text, run `tests/test_text_fit.gd` (catches cut-off text).
- `tests/test_weapons.gd` (`--fixed-fps 60`) checks every weapon fires and that its evolution hits harder;
  add each new weapon scene to its `WEAPONS` list. Tests that kill enemies must free `LevelUpMenu`
  first, or a level-up pauses the tree mid-test.
- `tests/test_santa.gd` (`--fixed-fps 60`) covers the meter, sleigh/present flow, blessings, loadout pool,
  reroll/banish. Scene tests end with a 180 s watchdog so a script error fails instead of hanging.
- Tests and the balance bot must never write the real `user://profile.json`: set
  `Profile.save_path = "user://test_scratch_profile.json"` in `_initialize()` (the results screen records
  every run), and change `Profile.data` in memory after the first frame (when `Profile._ready()` has loaded).
- Meta content is data: a Workshop upgrade = a `WorkshopData` .tres + its line in `Profile.WORKSHOP`; an
  achievement = an `AchievementData` .tres (stat key from `Profile.progress()`) + its line in
  `Profile.ACHIEVEMENTS`. New save fields go in `Profile.DEFAULTS` (old saves get them automatically).
- `GameState.start_run()` runs in `main.gd`'s `_enter_tree()` (before any child's `_ready()`), so scene
  children can read the run's loadout in `_ready()`.
- Tests live in `tests/` as `SceneTree` scripts: `godot --headless --path . -s res://tests/<test>.gd` (exit code 1 = failure).
  `-s` scripts compile before autoloads exist: never use project `class_name`s as types there; `load()` scripts/scenes at runtime.
- Balance bot: `godot --headless --fixed-fps 60 --path . -s res://tests/balance_sim.gd -- seed=N mode=collect|kite|idle`
  plays a full run in ~2 s and prints level/HP/enemies. Run ~10 seeds after any tuning change.
- After changing a data script's fields or defaults, the editor may keep the old script cached; saving a `.tres` through
  MCP then drops values equal to the *old* defaults. Check the `.tres` text afterwards (or write it explicitly).

## Art pipeline

- Model in Blender with `art_src/tools/pixel_bake.py` (`exec(open(path).read())` in Blender): build from
  `part()` primitives with palette `mat()`s, `build_asset()` joins them, `bake_export(ob, name, px)` bakes one
  albedo, palette-snaps it, exports `assets/models/<name>.glb` and saves `art_src/<name>.blend`.
- Models face Blender **+Y** (= Godot −Z); code turns them with `rotation.y = atan2(-dir.x, -dir.z)`.
- Characters and pickups get a `BlobShadow` (shared `assets/materials/blob_shadow_mesh.tres`).

## Game structure

- Main scene is `scenes/ui/splash.tscn` (intro -> `main_menu.tscn`); scene changes go through the `Transition`
  autoload (knitted curtain).
- UI text about upgrades/weapons/items/stats comes from `scripts/ui/describe.gd`, which uses the same
  formulas as gameplay (`WeaponData.damage_at/cooldown_at/count_at/radius_at`). Never hard-code numbers
  in UI text.
- Exception: the `DemoCode` autoload (type "hohoho") works in release builds on purpose, for live demos.
- Debug-only features check `OS.is_debug_build()` (F2/F3/F4, FPS readout); release exports drop them.
  Browser tests that need F3/F4 must use a debug export.
- Tests and the balance bot load `res://scenes/main/main.tscn` directly (no menu).
- Balance bot modes: `collect` (random picks, calls Santa at once), `focus` (builds on purpose, saves the
  meter for evolutions, rerolls), `kite`, `idle`; `loadout=a,b,c starter=a` picks the run's weapons.
- Weapons are listed once, in `Profile.WEAPON_CARDS` (id = scene file name). A new weapon needs: scene +
  script (extends `Weapon`), a `WeaponData` .tres (with evolution fields), an `UpgradeData` weapon card, the
  card in `LevelUpMenu.upgrades` and `Profile.WEAPON_CARDS`, `Describe.WEAPONS`, icons `weapon_<id>` and
  `weapon_<id>_evo`, and an entry in `tests/test_weapons.gd`.

## UI ("Workshop Tin" theme, see `art_reference/GUI_Style_Guide/`)

- Text, buttons and panels get a **theme type variation** (`HeaderLabel`, `PrimaryButton`, `PlateTight`, ...),
  never per-node font sizes or stylebox overrides. Need a new look? Add a role to
  `art_src/tools/build_ui_theme.gd`, then rebuild: `godot --headless --path . -s <abs>/art_src/tools/build_ui_theme.gd`.
- UI textures are generated: edit `art_src/tools/make_ui_textures.py`, run it, `--import`, rebuild the theme.
- UI built in code uses `Tin` (`scripts/ui/tin.gd`): `Tin.header()`, `Tin.stamp()`, `Tin.tile()`, `Tin.label()`.
- One gold primary button per screen. Buttons grab focus on hover so the `FocusBrackets` autoload agrees with
  keyboard/gamepad. Opt a control out with meta `no_brackets`.
- Deliberate overhangs (rays, a tag breaking a border) set meta `decor`; `test_text_fit.gd` then skips only
  their bounds. Anything else that sticks out is a bug.
- Clearing old overrides from existing scenes: `art_src/tools/apply_tin_roles.gd` (MCP can't remove an override).
- Panels built in code: `Tin.header(title, extra, close_callable)` gives the band + red close X; coins
  via `Tin.coin()`, keys via `Tin.keycap()` / `Tin.key_hint()`, numbers via `Tin.num()` (1,042).
- Settings options live in `Audio.options` (`set_option()` saves to `user://settings.cfg`); gameplay
  checks them (`Audio.shake_allowed()`, `options["damage_numbers"]`, `options["reduce_motion"]`).
- `Player.deal_damage(..., source)`: pass the weapon's `data.display_name` (or the item/event name) so
  the results Damage table can attribute it.
- Tweens on UI that can be visible while the tree is paused (toasts, results) must run with
  `PROCESS_MODE_ALWAYS` (bind the tween to that node), or they freeze half-way.
- Main scene is `scenes/ui/splash.tscn` (Knit + Tin intro). Editor runs skip it; set
  `camel_claus/always_show_intro` to preview, and switch it back off.
- The web loading page is generated: `python art_src/tools/make_web_shell.py` -> `web/shell.html` (the Web
  preset's custom HTML shell). Its red must match `boot_splash/bg_color` and the intro's first frame.

## Web build

- Must keep working with the GL Compatibility renderer and Web export.
- No threads-only features unless the web export is configured for them.

## Workflow

- After meaningful work, add an entry to `docs/DEVLOG.md`.
- Before calling something done: run the project and check for errors.
