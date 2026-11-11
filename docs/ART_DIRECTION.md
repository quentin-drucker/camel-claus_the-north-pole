# Camel Claus — Art Direction (style bible)

The single source of truth for how the game looks and sounds. Every AI-generated or sourced asset
must follow it. Claude reads this before creating or changing any model, texture, material, UI art
or audio. Fill in the TBDs; once filled, change them only on purpose and note the change in `DEVLOG.md`.

Format follows the `create-game-assets` skill's art-direction brief, so that skill can use it directly.

**One-line look:** chunky low-poly 3D with tiny nearest-filtered pixel textures, seen from a fixed
high camera; a cold blue-white North Pole broken up by warm camel tans and Christmas-gift reds/golds.
Genre references: horde-survivor games (Vampire Survivors, Megabonk) for *readability and
performance*, not for their characters, UI, logos or assets — everything here is original.

## Game frame

- Player fantasy: Claus, the Connecticut College Camel (school colors blue + white), lost at the North Pole, survives ever-growing waves of
  winter creatures, powered up by scattered Christmas gifts.
- Core verbs: move, survive, collect (XP and gifts), choose upgrades. Attacks fire automatically.
- Engine and renderer: Godot 4.7.2, **GL Compatibility** (required for Web export)
- Target platforms: Web browser (desktop first)
- Camera/view/facing: fixed high angle, ~55° pitch, perspective with a narrow FOV (~40°), follows
  the player, never rotates. Models must read from the **front and top**; backs can be simpler.
- Native viewport and common display scale: 1280×720 base, stretch mode `canvas_items`, aspect
  `expand`. Full-resolution render (no low-res whole-screen pixelation).
- Typical asset size on screen (at 720p): player ~70 px tall, common enemies 40–60 px, elites/bosses
  100–200 px, pickups 16–24 px.

## Visual system

- Tone: **cute, cozy-chaotic, all-ages.** Nothing scary. Even enemies are adorable: think mischievous
  toys and plush critters, not monsters.
- Shape language: chunky, rounded-boxy, few big forms. Exaggerated chibi proportions (big heads,
  stubby legs, big simple eyes). Everything is round and soft; enemies read as "enemy" through the
  purple hostile accent, small playful points (tiny horns, icicle tufts, pointy hats) and grumpy or
  "scary" faces (angry brows, little fangs, glaring eyes) — as long as the overall body stays round,
  chunky and cute, like an angry plush toy. Faces can be mean; the design is never actually frightening.
- Silhouette priorities: each enemy type must be identifiable by silhouette alone from above.
  Claus: humps + long neck + Santa hat. Gifts: cube + bow on top.
- Value structure: the snow ground is the **lightest** value on screen. Everything you interact with
  (player, enemies, pickups) sits in mid-to-dark values or saturated color so it pops off the snow.
  Never put a white enemy on white snow without a dark accent.
- Palette roles and exact swatches (hex) — use only these; add new ones here first:

  | Role | Swatches |
  |------|----------|
  | Snow / ground (light → dark) | `#F4F8FF` `#C9DAF0` `#8FA9D1` |
  | Ice / cold shadow / night | `#7FD6F2` `#4E6A9E` `#22304F` |
  | Camel (player warmth) | `#E8C48E` `#C98F55` `#8A5A33` |
  | Christmas red (hat, gifts) | `#D9343F` `#8E1F2E` |
  | Pine / gift green | `#3E9A5B` `#1F5A43` |
  | Gold (XP, ribbons, rare loot) | `#F2B53B` |
  | Wood / dark brown | `#5B3A2A` |
  | Enemy hostile accent (eyes, attacks) | `#9B4FD1` |

  Rule of thumb: **cool = world, warm = player and rewards, purple = danger.**
- Materials and surface cues: albedo-only pixel textures; flat color blocks with 1–2 shade steps
  painted in (no realistic PBR, no normal maps). Roughness 1, metallic 0, specular off.
- Edge/line treatment: no outline shader (extra draw cost per enemy). Readability comes from value
  contrast plus a soft dark **blob shadow** quad under every character and pickup.
- Lighting direction and contrast: one DirectionalLight3D from upper-left-front, soft; bright cool
  ambient so shadow sides stay readable. No real-time shadows on hordes (blob shadows instead).
- Detail density and focal hierarchy: player > elites > pickups > common enemies > props > ground.
  Ground and props stay low-detail and low-contrast so the action reads on top.
- Motion character: bouncy and snappy. Squash-and-stretch and bobbing via tweens or vertex shader;
  common enemies use shader bob/waddle, not skeletal rigs (so they can be instanced in bulk).
- Explicit exclusions: realistic or high-res textures, normal/roughness maps, smooth gradients,
  heavy bloom/post-processing, text baked into textures, gore, horror (realistic creepy anatomy,
  disturbing imagery), copying characters/UI/logos from reference games, the official
  Connecticut College logo or wordmark.

## Technical contract

- 3D format: `.glb` exported from Blender, 1 unit = 1 meter, apply transforms before export
- Texel density: **32 px per meter**. Typical textures: enemy 32–64 px, player 64–128 px, props
  32–64 px. Hard cap 128×128.
- Ground (changed 2026-11-11, was a 64×64 tile): world-space pixel shader
  `assets/materials/snow_ground.gdshader`, 16 px/m, snow swatches only, large drifts + rare ice
  sparkles. Reason: a repeating tile looked redundant (Checkpoint 0 feedback); the shader never repeats.
- Texture set per material: `<asset>_albedo.png` only. Built in Blender as a procedural material,
  then baked down to the target pixel size and palette-snapped to the swatches above.
- Import settings: texture filter **nearest**, mipmaps off, lossless compression (VRAM compression
  smears pixel art). Set `texture_filter = nearest` on every StandardMaterial3D.
- Color space: albedo sRGB
- Poly / material budgets: player ≤ 1500 tris, common enemy 150–600, elite ≤ 1500, pickup ≤ 100,
  props ≤ 300. One material (one texture) per asset; share atlases across enemy families when possible.
- Pivot/origin: at the base, centered, facing −Z (Godot forward)
- Naming and folders: see `docs/CONVENTIONS.md`

> Compatibility renderer limits: no SDFGI/VoxelGI/SSR, fewer lights per object. Lighting looks
> must be judged in-engine with this renderer, not in Blender's viewport.

## Visual target

- First target (to build and approve before anything else): **Claus the camel** (Santa hat, scarf),
  **one gift pickup**, **one common enemy**, and a **snow ground tile**, viewed in-engine from the
  game camera at 1280×720.
- **Approved 2026-11-11** (Quentin: Claus reads as a cute camel at a good size; the imp is clearly
  an enemy but still cute; snow better): `art_src/{claus,chaser,gift,ornament}.blend` →
  `assets/models/*.glb` (Claus 634 tris/64 px, chaser 472/64 px, gift 176/32 px, ornament 104/32 px).
  Pipeline: `art_src/tools/pixel_bake.py`. In-game scale: Claus model ×1.25, chaser size 1.3.
- Phase 3 families (same pipeline, 2026-11-11): zoomer (ice bat), chonk (grumpy walking pine with a
  face — decorative pines are tall, faceless and snow-heavy so they never read as enemies), Grumpy Yeti
  boss (836 tris, 128 px), elite gold crown, gift chest (gold box, red ribbon — distinct from red
  thrown gifts), candy cane; props: snowy pine, snowdrift, muted gift pile, candy-cane post, camel
  pennant (blue/white flag with an original two-hump camel silhouette, no college logo). Bakes can pass
  a per-asset `palette=` subset so blended edges can't snap to unrelated colors.
- Approved seed/reference paths: the four models above + `scenes/main/main.tscn` ground shader.
  New art matches them: chunky primitives, palette-only bake, chibi faces, purple = danger.
- Required do/don't examples: TBD
- Native-scale gameplay capture: TBD
- Approval owner/date: Quentin / 2026-11-11

## Audio & UI style

- Music mood (revised 2026-11-11 after Quentin found the 8-bit loop harsh): **modern, warm and cozy with
  a retro flavour** - music box, soft flute-like lead, detuned pads, round bass, soft drums, filtered
  sleigh bells; no square waves or piercing highs; 112 BPM; 2-minute arrangement (intro, verse, chorus,
  interlude, chorus) + an intensity layer that fades in at 3:30.
- SFX character: short, soft-edged chiptune blips; festive (bells, paper rustle, ornament "tink"),
  never harsh or gory. Hits/pickups get small random pitch variation. (Quentin, 2026-11-11)
- Audio source: CC0 packs (Kenney Interface Sounds + Digital Audio, credited in `assets/CREDITS.md`) for
  SFX. Music and jingles are **generated** by `art_src/tools/make_audio.py` (changed 2026-11-11: no CC0
  Christmas chiptune loop was downloadable; the tune is the public-domain melody "Jingle Bells", our
  own 8-bit arrangement — fits the all-AI pipeline). OGG for music,
  WAV for short SFX. Web build plays audio as samples, so no bus effects (reverb/compressor/limiter):
  balance with bus volume only.
- UI style (Quentin, 2026-11-11): **cozy pixel** — chunky CC0 pixel font, dark navy `#22304F` panels with
  gold `#F2B53B` trim and a 2 px border, snow-white `#F4F8FF` text, small pixel icons on cards. Rarity
  tints: rare = ice `#7FD6F2`, epic = hostile purple `#9B4FD1`, evolution = gold. UI-text-only tints
  (for readability on navy): better `#9BE0A8`, worse `#FF9AA0`, epic tag `#C9A6EC`, item tag `#E8C48E`.
  Icons: 12x12 pixel art + 1 px navy outline, saved 4x (56 px); HUD shows them at 28 px.
