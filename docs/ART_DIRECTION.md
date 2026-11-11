# Camel Claus — Art Direction (style bible)

The single source of truth for how the game looks and sounds. Every AI-generated or sourced asset
must follow it. Claude reads this before creating or changing any model, texture, material, UI art
or audio. Fill in the TBDs; once filled, change them only on purpose and note the change in `DEVLOG.md`.

Format follows the `create-game-assets` skill's art-direction brief, so that skill can use it directly.

## Game frame

- Player fantasy: TBD
- Core verbs: TBD
- Engine and renderer: Godot 4.7.2, **GL Compatibility** (required for Web export)
- Target platforms: Web browser (desktop first)
- Camera/view/facing: TBD
- Native viewport and common display scale: TBD
- Typical asset size on screen: TBD

## Visual system

- Shape language: TBD
- Silhouette priorities: TBD
- Value structure: TBD
- Palette roles and exact swatches (hex): TBD
- Materials and surface cues: TBD (PBR via StandardMaterial3D: albedo, normal, roughness, metallic, AO)
- Edge/line treatment: TBD
- Lighting direction and contrast: TBD
- Detail density and focal hierarchy: TBD
- Motion character: TBD
- Explicit exclusions: TBD

## Technical contract

- 3D format: `.glb` exported from Blender, 1 unit = 1 meter, apply transforms before export
- Texture sizes: TBD (keep small for web load time; e.g. 1024 max for props)
- Texture set per material: `<asset>_albedo`, `_normal`, `_orm` (occlusion/roughness/metallic packed)
- Color space: albedo sRGB; normal/ORM linear
- Poly / material budgets: TBD
- Pivot/origin: at the base, centered, facing −Z (Godot forward)
- Naming and folders: see `docs/CONVENTIONS.md`

> Compatibility renderer limits: no SDFGI/VoxelGI/SSR, fewer lights per object. Lighting looks
> must be judged in-engine with this renderer, not in Blender's viewport.

## Visual target

- Approved seed/reference paths: TBD
- Required do/don't examples: TBD
- Native-scale gameplay capture: TBD
- Approval owner/date: Quentin / TBD

## Audio & UI style

- Music mood: TBD
- SFX character: TBD
- UI fonts, colors, panel style: TBD
