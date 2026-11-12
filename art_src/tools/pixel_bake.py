"""Camel Claus asset pipeline helpers for Blender (run inside Blender: exec(open(path).read())).

Model = low-poly parts built from primitives, each with its own small procedural material
(flat palette color + optional 1-step shade). bake_export() joins nothing itself: build_asset()
joins the parts, then bake_export() bakes every material into ONE tiny albedo texture,
snaps it to the ART_DIRECTION palette, swaps in a single nearest-filtered material and
exports a .glb into assets/models/ (+ a .blend copy into art_src/).

Conventions: 1 unit = 1 m, model stands on Z=0 centred on the origin, faces Blender +Y
(= Godot -Z after glTF export).
"""
import bpy
import os
from collections import Counter

# Run via exec() in Blender, so __file__ isn't available: the project folder (renamed 2026-11-11 from
# cc-v-0) is the first of these that exists.
_ROOTS = [r"C:\Users\qdruc\Projects\Godot\Camel Claus\Camel Claus The North Pole",
          r"C:\Users\qdruc\Projects\Godot\Camel Claus\cc-v-0"]
PROJ = next((p for p in _ROOTS if os.path.isdir(p)), _ROOTS[0])

# docs/ART_DIRECTION.md palette (snap targets).
PALETTE = [
    "#F4F8FF", "#C9DAF0", "#8FA9D1",  # snow
    "#7FD6F2", "#4E6A9E", "#22304F",  # ice / cold shadow
    "#E8C48E", "#C98F55", "#8A5A33",  # camel
    "#D9343F", "#8E1F2E",             # christmas red
    "#3E9A5B", "#1F5A43",             # pine
    "#F2B53B",                        # gold
    "#5B3A2A",                        # wood
    "#9B4FD1",                        # hostile accent
]


def hex_srgb(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))


def hex_lin(h):
    return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in hex_srgb(h)) + (1.0,)


def clear_scene():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for block in list(coll):
            if block.users == 0:
                coll.remove(block)


def mat(name, light, dark=None, below=0.0, axis=2):
    """Palette color; with `dark`, object-space coord on `axis` below `below` uses the dark shade."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    N, L = m.node_tree.nodes, m.node_tree.links
    bsdf = next(n for n in N if n.type == "BSDF_PRINCIPLED")
    if dark is None:
        bsdf.inputs["Base Color"].default_value = hex_lin(light)
        return m
    tc = N.new("ShaderNodeTexCoord")
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(tc.outputs["Object"], sep.inputs[0])
    lt = N.new("ShaderNodeMath")
    lt.operation = "LESS_THAN"
    L.new(sep.outputs[axis], lt.inputs[0])
    lt.inputs[1].default_value = below
    mix = N.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    L.new(lt.outputs[0], mix.inputs[0])
    mix.inputs[6].default_value = hex_lin(light)
    mix.inputs[7].default_value = hex_lin(dark)
    L.new(mix.outputs[2], bsdf.inputs["Base Color"])
    return m


def stripes(name, a, b, period=0.1):
    """Diagonal stripes (candy cane): object-space (x + z) / period alternates colors a and b."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    N, L = m.node_tree.nodes, m.node_tree.links
    bsdf = next(n for n in N if n.type == "BSDF_PRINCIPLED")
    tc = N.new("ShaderNodeTexCoord")
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(tc.outputs["Object"], sep.inputs[0])
    add = N.new("ShaderNodeMath")
    add.operation = "ADD"
    L.new(sep.outputs[0], add.inputs[0])
    L.new(sep.outputs[2], add.inputs[1])
    div = N.new("ShaderNodeMath")
    div.operation = "DIVIDE"
    L.new(add.outputs[0], div.inputs[0])
    div.inputs[1].default_value = period
    frac = N.new("ShaderNodeMath")
    frac.operation = "FRACT"
    L.new(div.outputs[0], frac.inputs[0])
    lt = N.new("ShaderNodeMath")
    lt.operation = "LESS_THAN"
    L.new(frac.outputs[0], lt.inputs[0])
    lt.inputs[1].default_value = 0.5
    mix = N.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    L.new(lt.outputs[0], mix.inputs[0])
    mix.inputs[6].default_value = hex_lin(a)
    mix.inputs[7].default_value = hex_lin(b)
    L.new(mix.outputs[2], bsdf.inputs["Base Color"])
    return m


def part(kind, name, loc, scale, material, rot=(0, 0, 0), seg=8, rings=5, r2=0.0, bevel=0.0):
    """kind: sphere | cube | cyl | cone. cube/cyl/sphere scale = half-extents (radius)."""
    ops = bpy.ops.mesh
    if kind == "sphere":
        ops.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc, rotation=rot)
    elif kind == "cube":
        ops.primitive_cube_add(size=2, location=loc, rotation=rot)
    elif kind == "cyl":
        ops.primitive_cylinder_add(vertices=seg, radius=1, depth=2, location=loc, rotation=rot)
    elif kind == "cone":
        ops.primitive_cone_add(vertices=seg, radius1=1, radius2=r2, depth=2, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if bevel > 0:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.materials.append(material)
    return o


def build_asset(name, parts):
    """Join parts into one flat-shaded mesh named `name` (origin at world origin)."""
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = name
    ob.data.name = name
    for poly in ob.data.polygons:
        poly.use_smooth = False
    tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    print(f"{name}: {tris} tris, {len(ob.data.materials)} part materials")
    return ob


def bake_export(ob, name, size, island_margin=0.02, palette=None):
    """Bake all part materials into one size x size albedo, palette-snap, export .glb + .blend.
    `palette`: optional subset of PALETTE hexes, so blended edges can't snap to unrelated colors."""
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=island_margin)
    bpy.ops.object.mode_set(mode="OBJECT")

    img_name = f"{name}_albedo"
    if img_name in bpy.data.images:
        bpy.data.images.remove(bpy.data.images[img_name])
    img = bpy.data.images.new(img_name, size, size, alpha=False)
    for m in ob.data.materials:
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = img
        m.node_tree.nodes.active = tex

    sc = bpy.context.scene
    try:
        sc.render.engine = "CYCLES"
    except TypeError as e:
        print(e)
    sc.cycles.samples = 4
    bake = sc.render.bake
    bake.use_pass_direct = False
    bake.use_pass_indirect = False
    bake.use_pass_color = True
    bake.margin = 2
    bpy.ops.object.bake(type="DIFFUSE")

    # Palette snap (byte images hold sRGB values).
    pal = [hex_srgb(h) for h in (palette or PALETTE)]
    px = list(img.pixels)
    out = []
    for i in range(0, len(px), 4):
        c = px[i:i + 3]
        best = min(pal, key=lambda p: sum((a - b) ** 2 for a, b in zip(c, p)))
        out += [*best, 1.0]
    img.pixels = out
    os.makedirs(os.path.join(PROJ, "art_src", "bakes"), exist_ok=True)
    img.filepath_raw = os.path.join(PROJ, "art_src", "bakes", img_name + ".png")
    img.file_format = "PNG"
    img.save()
    used = Counter("#%02X%02X%02X" % tuple(round(v * 255) for v in out[i:i + 3]) for i in range(0, len(out), 4))

    # One final material: baked texture, nearest filtering, matte.
    final = bpy.data.materials.new(name)
    final.use_nodes = True
    N, L = final.node_tree.nodes, final.node_tree.links
    bsdf = next(n for n in N if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Metallic"].default_value = 0.0
    for nm in ("Specular IOR Level", "Specular"):
        if nm in bsdf.inputs:
            bsdf.inputs[nm].default_value = 0.0
    tex = N.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    L.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    ob.data.materials.clear()
    ob.data.materials.append(final)

    glb = os.path.join(PROJ, "assets", "models", name + ".glb")
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True,
                              export_apply=True, export_yup=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(PROJ, "art_src", name + ".blend"),
                                copy=True, relative_remap=True)
    print(f"{name}: exported {os.path.getsize(glb)} bytes, colors {dict(used.most_common())}")
    return ob
