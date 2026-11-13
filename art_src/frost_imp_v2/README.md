# Frost Imp — sculpted version

Based on the approved reference in `art/concepts/frost-imp/frost-imp-approved-sculpted.png`.

## Files

- `frost_imp_v2.blend`: final UV-mapped mesh with packed baked texture.
- `frost_imp_sculpt.blend`: pre-bake source with editable procedural color/shading materials.
- `frost_imp_v2_albedo.png`: 512x512 sRGB color atlas. Includes painted shading and subtle occlusion.
- `frost_imp_v2_uv.svg`: UV wire layout, scalable for painting/inspection.
- `../../../assets/models/chaser.glb`: game-ready Chaser export, embedded texture.
- `preview_front.png`, `preview_topdown.png`, `preview_back.png`: Blender renders of the reimported GLB.
- `godot_review.png`, `godot_crowd.png`: actual Godot Compatibility-renderer captures.
- `validation.json`: independent exported-buffer audit; `asset_report.json`: source stats.

## Contract

3,450 triangles, one render mesh/surface, one material, one 512x512 texture, no rig.
0.70 m high, origin on the floor between the feet, applied object transforms.
Blender +Y maps to Godot -Z. Opaque matte material, no normal map or live procedural shading.
UV charts are packed in 0–1 without intentionally stacked faces. Geometric fur and face parts
are disconnected shells within the one mesh; the body/arms/feet are a continuous fused surface.
This is a game-resolution interpretation of the concept, not a high-resolution sculpt replica.

## Inspect

Open `scenes/enemies/frost_imp_review.tscn` in Godot and press F6.
Space toggles the 100-instance view; S saves a capture; Escape closes it.
Close-ups use orthographic cameras to aid comparison; elevated views use the game's 55-degree
angle, environment/light settings and existing enemy waddle shader. The production camera is perspective.
The review is separate from gameplay; the GLB it displays is the production Chaser asset.

## Budget and performance

Suggested range for this revised art style: 2,500–3,500 triangles per common enemy.
100 copies of this model contribute 345,000 base triangles. Textures and geometry are shared.
The successful 100-instance local render check reported 346,058 total primitives and 207 draw
calls including blob shadows and UI. No browser frame-rate claim is made: gameplay, effects,
resolution and target hardware still need profiling. At 40–60 px, the face and silhouette do most
of the work. A future lower LOD can reduce triangles if browser profiling warrants it.

## Rebuild

Run Blender in background with `--python art_src/tools/build_frost_imp.py` from the project root.
Run `python art_src/tools/audit_frost_imp.py` to check the exported GLB buffers.
The generator uses sculpt fusion, mesh reduction, packed UV charts, procedural painted-color
materials and an emission bake. The resulting texture is generated/baked, not manually brush-painted.
`FROST_IMP_CAPTURE=1` runs the Godot review through front/elevated and 100-instance capture modes
and then exits; otherwise it stays interactive and animates via the existing waddle shader.
