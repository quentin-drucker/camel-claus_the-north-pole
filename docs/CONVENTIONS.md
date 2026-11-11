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
- Changing a **Resource** script's fields from outside: the editor keeps the old property list (focus doesn't fix it). Write those scripts with `godot_files_write` so the editor reloads them, then set `.tres` values with `godot_resource_set`.
- Add an autoload only after its script compiles; if it was added while broken, remove and re-add it.
  Rewriting the autoload script from outside can also break it in the editor ("Identifier not found:
  GameState" everywhere) — same fix: `godot_autoload_edit` remove + add.
- A scene open in an editor tab keeps the old version of its script's exports; `godot_scene_close` it and
  set properties again (the tool reopens it).
- New resources get UIDs in the editor before its UID cache reaches disk; headless runs then warn "invalid
  UID". Run `godot --headless --path . --import` once before tests/sims.
- `-s` test scripts: the tree isn't live during `_initialize`, so `_enter_tree` doesn't run — set
  `GameState.player` by hand.
- A script's `@export` fields can't be set in the same call that attaches the script; prefer `preload()` defaults in the script for data resources.
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

## Web build

- Must keep working with the GL Compatibility renderer and Web export.
- No threads-only features unless the web export is configured for them.

## Workflow

- After meaningful work, add an entry to `docs/DEVLOG.md`.
- Before calling something done: run the project and check for errors.
