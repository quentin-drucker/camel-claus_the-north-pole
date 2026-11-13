# Camel Claus: The North Pole — Modern-Retro Art Direction (Exploratory Brief)

## Reference videos
- **Short**: *Retro Graphics with Modern Software! #ps1 #n64 #3d #retrogaming* (pwnisher), 0:31.
- **Compilation**: *10 NEW PS1-Style Games Coming 2026-2027 Amazing Low-Poly Retro Gems* (Magic Game World), 12:00.
- See accompanying `retro_style_reference_board.jpg` and contact sheets for extracted references. The scenes are independent references, **not** a continuous style or narrative.

## One-sentence aesthetic
**A charming, cozy, neo-retro 3D North Pole: PS1/N64-era low-poly shapes and deliberately low-resolution, hand-painted pixel textures, elevated by modern color design, expressive animation, warm lighting, soft atmospheric depth, and restrained snow and magical effects.**

## What this is (and is not)
This is **stylized modern retro**, not a demand for hardware-accurate PS1 emulation. A few references show bright whimsical fantasy with sculptural clouds; others show snow-softened silhouettes and pixel-textured interiors; the compilation also includes dark, grainy survival horror. For Camel Claus, prioritize the playful, vivid, readable, atmospheric subset. Avoid copying the dark horror palette, strong grain, muddy shadows, excessive wobbling, CRT bars, or aggressively limited render resolution without testing. The goal is **nostalgic visual language plus modern polish**, not roughness as an end in itself.

## Six visual pillars
1. **Chunky, purposeful geometry:** Low-to-moderate polygon counts, geometric/planar faceting, attractive clear silhouettes, carefully exaggerated proportions. Simple does not mean primitive.
2. **Coherent texel language:** Pixelated or low-resolution painted materials, nearest-neighbor filtering where it improves appearance, controlled texel density, a coordinated atlas/palette. Avoid mixing photo-real textures with retro pixel materials.
3. **Hand-authored colors:** Restrained cold winter blues, teal shadows, ivory snow, pine greens, cranberry/berry reds; warm honey-gold light for cabins, lanterns and pickups. Avoid generic saturated rainbow Christmas colors everywhere.
4. **Modern lighting:** Directional light, intentional cast shadows, nuanced ambient/fill lighting, warm–cool contrast; subtle glow for magical objects. Keep silhouettes and ground readability intact.
5. **Atmospheric layering:** Foreground crispness, midground readable forms, softened distant forest/mountain silhouettes, snow/haze/fog and scattered particles. Avoid a flat horizon or a hard unexplained map boundary.
6. **Responsive, polished motion:** Smooth movement, appealing animation arcs, squash/stretch where appropriate, restrained particle bursts and hover effects. Do not purposely reduce gameplay responsiveness to mimic old hardware.

## Useful observations from the videos
- Short ~0:00–0:04: faceted tropical island and boat; simple geometry, colorful sea using conspicuous blocky surface patterns, soft sculptural clouds, welcoming lighting.
- Short ~0:04–0:08: magical book in a room; low-resolution surfaces with strong atmospheric spot lighting, bright beams and carefully staged particles.
- Short ~0:08–0:15: snowy landscape; chunky stylized trees, extremely soft distant landscape, pale fog, sparse snow particles, reduced detail with distance.
- Short ~0:16–0:21: first-person industrial corridor; angular architecture and low-resolution, graphic surfaces with strong directional light and shadows.
- Short ~0:22–0:30: miniature room diorama; few large pieces, clean readable shapes, stylized wood/paper textures and miniature-like camera scale.
- Compilation: multiple styles rather than one. The brightly lit fantasy/platforming portions suggest family-friendly color and readable silhouette treatments; medieval village scenes show textured rough surfaces and environmental layering; horror/survival sections emphasize fog, grain and dark palettes, less appropriate as a default Christmas world style.

## Asset-specific directions

### Ground / snow / terrain
Replace uniform flat colors and repetitive single-tile patterns with **three to five related surface families**: powder snow, packed traversable snow, icy/glazed paths, slushy shadow patches, sparse dirt/grass around trees or structures. Use low-resolution painterly/pixel texture atlases, broad forms and large patches; keep terrain navigable. Add restrained angular snowbanks, snow clumps, drift variations and light-blue shadow tint. Avoid checkerboarding, noisy speckling, photoreal normal maps, and inconsistent texture scale. Make footprints or interaction marks subtle and short-lived if needed.

### Trees and foliage
Build small families of recognizable low-poly pine silhouettes with faceted branch tiers and stylized, chunky snow caps. Brown trunks should have simple low-res bark treatment; foliage can have 2–4 coordinated value bands. Vary height, angle and crown shape deliberately, not through random scale alone. Distant trees can be simpler or sprite/impostor based.

### Rocks, mountains and perimeter
Use layered polygonal snowdrifts, boulders, cliff faces, snowed-in fences, dense clusters of forest, and large mountain silhouettes. Make the map perimeter **physically plausible in-world** rather than relying on occasional trees and an invisible wall. Fade far mountains with cool fog and lighting. Keep the center playfield relatively uncluttered.

### Sky and atmosphere
Use a stylized gradient sky, layered blocky/soft cumulus-like cloud forms or textured sky cards, crisp horizon colors, and slow ambient sky motion. Modern atmospheric perspective is encouraged. Avoid pairing photorealistic HDRI clouds with otherwise aggressively low-res art unless consciously art-directed.

### Characters / camels / enemies
Favor chunky, expressive, rounded-with-facets silhouettes over highly detailed anatomy. Eyes, ears, muzzle, scarf, Santa hat and accessory shapes should remain readable at typical gameplay zoom. Use simple color-grouped low-resolution textures and perhaps a few more geometric facets on hero characters than minor enemies. Readability and expression matter more than a strict polygon limit. Enemy silhouettes should be distinguishable by shape as well as color.

### Pickups, weapons, props and holiday decorations
Create a consistent set of low-poly/pixel-textured props: peppermint candy canes, gift boxes, baubles, lanterns, log stacks, North Pole signs, wooden fences, cookies, snowflakes and glowing XP pickups. Make pickups slightly brighter or more emissive than ordinary scenery so they remain visible during combat. Use warm gold glow sparingly as a visual priority cue, not everywhere.

### Shadows and effects
Anchor characters and props with simple readable ground shadows even if the art is highly stylized. Give interactions small animated flourishes: snowfall, drifting motes, small impact pixel shards, pickup glints. Prefer cheap particles, flipbook sprites, one-shot animations and pooled effects over dense transparent effects. Avoid bloom that destroys pixel texture clarity.

### UI / HUD
Develop a complementary, original stylized roguelite UI using bold readable typography, compact upgrade cards, handcrafted icons, tactile buttons and subtle winter motifs. Do **not** apply world-resolution pixelation indiscriminately to text and vital gameplay numbers. The UI can use pixel-inspired contours and icons while preserving crisp text, contrast and accessibility.

## Rendering & pipeline choices to test — not hard requirements
- Prototype a **single small art-direction vertical slice** first: camel, one enemy, snow ground, two tree variants, one rock, one pickup, one decorative prop, sky, lighting and a tiny HUD sample.
- Prototype materials at **64×64 / 128×128** for small props and **128×128 / 256×256** for primary characters or complex props as starting points, then adjust by screen size, UV scale and the camera. These are stylistic starting points, not fixed hardware-era rules.
- Use nearest-neighbor sampling on deliberately pixel-art materials where attractive; test mipmaps or lower-frequency detail to prevent crawling textures in motion.
- Optionally test rendering the **3D world** at 1/2 or 1/3 resolution, upscaled with nearest-neighbor, while leaving the HUD at native resolution. Compare against full-resolution rendering with pixel textures: lower screen resolution is **not** mandatory for this aesthetic.
- Optionally test a *very subtle* color quantization/dither pass; avoid strong grain, severe affine warping, camera jitter or UV wobble unless that exact look is desired. Old console quirks are not required for modern-retro art direction.
- Consider the project's Godot renderer/web performance before choosing shaders or particle techniques. Keep baseline performance, collision, UI readability and game logic unchanged.

## Important architecture checkpoint
Inspect whether Camel Claus currently uses 2D sprites, 3D meshes or a mixed 2.5D setup. Reference clips are mostly 3D, but a 2D game does **not** need to become fully 3D to inherit this art direction. A viable path is to create low-poly characters and props in Blender, render matching sprite sheets and texture atlases with consistent camera angle/light, and deploy them as 2D sprites in Godot. A genuine 3D conversion would be a major separate gameplay/engine decision—not something to smuggle into an asset makeover.

## Evaluation criteria / anti-goals
- Consistent pixel scale and texel density across related assets.
- Cohesive geometry style; no mixtures of photoreal assets, modern glossy bevels, and random crude cubes.
- Friendly, legible top-down playfield; clear differentiation between background clutter, hazards, enemy outlines, pickups and player character.
- Environment has believable spatial boundaries, distant layers and subtle animation.
- Good appearance at actual gameplay zoom and in motion—not merely in close-up Blender renders.
- Web-capable, without gratuitous post-processing or permanent performance regression.
- No scene or asset replacements until the art direction prototype is reviewed and chosen.

## Claude Code art-direction prompt
> Study the attached reference-board frames and videos as *independent visual examples*, not as a single unified game's art. I want to explore a coherent **cozy modern-retro low-poly 3D** look for Camel Claus: The North Pole. Take the PS1/N64 era's geometric silhouettes, low-resolution pixel-textured surfaces and nostalgic color design, but elevate them with modern composition, atmospheric fog, warm/cool lighting, subtle snow/particle motion and smoothly animated characters. It must feel like a deliberate hand-authored indie-game visual identity, **not** cheap PS1 emulation, generic Minecraft blocks, primitive placeholder geometry or dark VHS horror. Favor chunky, adorable camels; faceted snowbanks; stylized snowy pines; angular distant mountains; colorful tactile pickups; and warm Christmas lanterns against cool snowy blue shadows. Keep texel density/pixel scale, silhouettes, palette, shadow treatment and lighting consistent across *all* assets. Preserve readable gameplay and native-resolution text. First inspect whether this is a 2D, 3D or 2.5D project; do not convert architecture implicitly. Make a small comparison prototype showing three disciplined looks: **(A) bright whimsical N64 storybook**, **(B) cozy pixel-textured PS1 diorama**, **(C) atmospheric snowy modern-retro**, each with identical example assets and camera framing. Demonstrate them with actual rendered screenshots or interactive scenes; visually inspect and revise them. Do not overwrite the game's existing models, sprites, textures, shaders, levels or UI until I select a direction. Then plan an asset-by-asset migration.

