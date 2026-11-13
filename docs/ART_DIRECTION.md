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

### Approved Frost Imp direction update (2026-11-13)

For the new Frost Imp, this section supersedes the older primitive-shape, tiny-texture,
palette-only rules below. Existing assets retain their current contracts until revised.

- Reference: `art/concepts/frost-imp/frost-imp-approved-sculpted.png`. The user approved a
  cohesive sculpted creature: shaped muzzle and cheeks, integrated limbs, heavy brows,
  curved horns and broad swept fur locks. Simple major forms must not look like attached primitives.
- The original palette is a baseline. Harmonious intermediate colors, painted gradients,
  fur strokes and baked shading are allowed. Keep purple hostile eyes, cool body colors and matte surfaces.
- Working common-enemy target for this fidelity: **2,500-3,500 triangles**, one mesh surface,
  one material and one **512x512 albedo**. No skeleton, normal map or runtime procedural texture.
  The completed review asset has **3,450 triangles** and is **0.70 m** tall, with a ground-center pivot.
- Texture filtering may be linear for close inspection; the current enemy waddle shader uses
  nearest filtering. The review checks that exact shader too. Texture import is lossless with
  mipmaps available; the old strict palette-snapping pipeline is not used for this asset.
- Deliverables: `assets/models/chaser.glb`, `art_src/frost_imp_v2/`, and
  `scenes/enemies/frost_imp_review.tscn`. This model is now the production Chaser while retaining
  the existing wrapper, enemy data and GPU waddle animation. Do not treat this as approval to replace
  every other enemy.
- Budget is provisional for Web. 100 copies = 345,000 model triangles. The standalone
  Compatibility-renderer review succeeded with 100 copies; it is not a browser gameplay benchmark.

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
- Phase 6.1 (2026-11-11, same pipeline, not yet reviewed by Quentin): `snowball` (ice-blue, Claus's
  weapon), `enemy_snowball` (snow + purple bands: anything hostile in the air carries purple),
  `ornament_mine` (green bauble + gold studs, bigger than XP so the two never get confused), pickups
  `magnet` (red horseshoe), `cookies_milk` (on a red plate so it pops off the snow), `snow_bomb` (navy +
  ice band + gold fuse), and the **Snowball Lobber** enemy (navy imp holding a purple-banded snowball
  overhead; silhouette = "ranged"). Warning rings for enemy attacks are purple outlines
  (`assets/materials/warning_ring_mesh.tres`), mostly transparent inside so they never hide the ground.
- Phase 6.2-6.4 (2026-11-11, same pipeline, not yet reviewed by Quentin): Santa's `sleigh` (red body,
  gold runners and rails, gift sack, one reindeer with a red nose; 628 tris, 128 px; flies 3.2 m up,
  offset toward the camera so it crosses the middle of the screen), `santa_present` (green box, red ribbon,
  gold star: distinct from red thrown gifts and the gold chest), `gingerbread` (flat cookie man with white
  icing and red buttons, lies flat so it reads while spinning). Blizzard event: white frost only at the
  screen edges (radial gradient, middle stays clear), never full-screen fog.
- UI additions follow the cozy-pixel style: Santa's present screen uses a warm wood-brown backdrop
  `#5B3A2A` to feel special; blessing cards have a pine-green border; achievement toast = navy panel +
  trophy icon in the bottom-right corner; new icons (blessings, sleigh, present, reroll, banish, coin,
  trophy, lock, new weapons and evolutions) are 12x12 + navy outline like the rest.
- Phase 7 (2026-11-11, not yet reviewed by Quentin): **Claus is now body + hat + outfit pieces**
  (`art_src/claus_parts.blend` keeps the original split; new pieces in `art_src/hat_*.blend`,
  `outfit_*.blend`), all modelled in Claus's own space (head top z 1.07 at y 0.40, neck ring y 0.25 z 0.52,
  torso box +-0.26 x -0.34..0.28 x 0.19..0.53) so they attach with no offsets. Recolors use
  `palette_swap.gdshader` on exact swatches: camel swatches `#E8C48E #C98F55 #8A5A33 #5B3A2A` for skins,
  each piece's main pair for colors (red `#D9343F/#8E1F2E`, green `#3E9A5B/#1F5A43`, blue `#4E6A9E/#22304F`,
  gold `#F2B53B/#C98F55`, ice `#7FD6F2/#4E6A9E`). **Rules**: no purple cosmetics (purple = danger); the
  Cream skin is the lightest allowed (still warm against the snow, keeps dark eyes and the blob shadow).
  World: `rock` (blue-grey boulders + snow caps), `mountain` (54 tris, used 2-5x scale far away);
  boundary = snowbank ridge + rocks + 3 pine rows; sky gradient + depth fog from 60 m (atmospheric
  perspective) + pixel moon/stars + faint aurora; props sway via vertex shader (no skeletal rigs).
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
- UI style (changed 2026-11-12, was "cozy pixel"): **"Workshop Tin" A+ hybrid**, approved by Quentin in HTML.
  The full spec (tokens, every component, screen layouts, motion, intro, Godot recipe) is
  `art_reference/GUI_Style_Guide/Camel_Claus_GUI_Style_Guide.md`; read it before any UI work. In short:
  Megabonk-style riveted navy plates (`#1A2438`, pine header band `#1F5A43`, brass rivets), slab buttons with a
  pressable lip (one gold `#F2B53B` primary per screen), white corner brackets for the selection, rarity rows
  for upgrades, a bare outlined HUD. Accent layers: **knit** (Fair Isle camel trim under headers, knit behind
  cards, sewn sweater-button knobs, knitted-curtain transition, "Knit + Tin" intro) and **North Pole post**
  (stamps, postmarks, airmail toast, luggage tag, postcard achievements/results). Never knit or stamps on the HUD.
  Fonts (OFL): **New Rocker** titles/buttons (chosen by Quentin), **Tiny5** body/numbers, **Bowlby One** logo.
  Rarity: rare = ice `#7FD6F2`, epic = purple `#9B4FD1`, evolution = gold; purple stays danger/epic only.
  Icons: unchanged 12x12 pixel art + 1 px navy outline, saved 4x (56 px).
