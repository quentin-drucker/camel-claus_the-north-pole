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

## Folders

```
scenes/      gameplay scenes grouped by feature (player/, enemies/, levels/, ui/)
scripts/     shared scripts not tied to one scene (autoloads, utils)
resources/   .tres data
assets/      models/, textures/, materials/, audio/, fonts/  (imported art)
art_src/     .blend and other source files; has .gdignore so Godot won't auto-import .blend
docs/        devlog, art direction, these conventions
```

## Web build

- Must keep working with the GL Compatibility renderer and Web export.
- No threads-only features unless the web export is configured for them.

## Workflow

- After meaningful work, add an entry to `docs/DEVLOG.md`.
- Before calling something done: run the project and check for errors.
