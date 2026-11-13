"""Build, UV unwrap, bake and export the approved Frost Imp concept. Blender 5.x."""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
from math import sin, cos, pi

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art_src/frost_imp_v2'
OUT.mkdir(parents=True, exist_ok=True)
ASSET = ROOT / 'assets/models/chaser.glb'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
parts=[]

def lin(h):
    rgb=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb)+(1,)

def painted(name, dark, light, fur=True):
    m=bpy.data.materials.new(name); m.use_nodes=True
    n=m.node_tree.nodes; l=m.node_tree.links; n.clear()
    out=n.new('ShaderNodeOutputMaterial'); emit=n.new('ShaderNodeEmission')
    l.new(emit.outputs[0],out.inputs['Surface'])
    tc=n.new('ShaderNodeTexCoord')
    mapping=n.new('ShaderNodeVectorMath'); mapping.operation='MULTIPLY'
    mapping.inputs[1].default_value=(12,12,1.5) if fur else (6,6,6)
    l.new(tc.outputs['Object'],mapping.inputs[0])
    noise=n.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value=4
    noise.inputs['Detail'].default_value=2; noise.inputs['Roughness'].default_value=.65
    l.new(mapping.outputs[0],noise.inputs['Vector'])
    geo=n.new('ShaderNodeNewGeometry')
    dot=n.new('ShaderNodeVectorMath'); dot.operation='DOT_PRODUCT'
    dot.inputs[1].default_value=(-.25,.45,.85)
    l.new(geo.outputs['Normal'],dot.inputs[0])
    mul=n.new('ShaderNodeMath'); mul.operation='MULTIPLY_ADD'
    l.new(dot.outputs['Value'],mul.inputs[0]); mul.inputs[1].default_value=.28; mul.inputs[2].default_value=.48
    grain=n.new('ShaderNodeMath'); grain.operation='MULTIPLY_ADD'
    l.new(noise.outputs['Fac'],grain.inputs[0]); grain.inputs[1].default_value=.72 if fur else .15; grain.inputs[2].default_value=-.36 if fur else -.075
    add=n.new('ShaderNodeMath'); add.operation='ADD'
    l.new(mul.outputs[0],add.inputs[0]); l.new(grain.outputs[0],add.inputs[1])
    ramp=n.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position=.05; ramp.color_ramp.elements[0].color=lin(dark)
    ramp.color_ramp.elements[1].position=.9; ramp.color_ramp.elements[1].color=lin(light)
    l.new(add.outputs[0],ramp.inputs[0])
    ao=n.new('ShaderNodeAmbientOcclusion'); ao.inputs['Distance'].default_value=.10
    ao.samples=16
    shade=n.new('ShaderNodeMixRGB'); shade.blend_type='MULTIPLY'; shade.inputs[0].default_value=.32
    l.new(ramp.outputs[0],shade.inputs[1]); l.new(ao.outputs['Color'],shade.inputs[2])
    l.new(shade.outputs[0],emit.inputs[0])
    return m

navy=painted('Fur - deep indigo roots','#192444','#5677AE')
slate=painted('Fur - swept slate locks','#34466F','#8CA9D6')
face=painted('Fur - pale blue face','#617CA7','#C1D8F1')
ice=painted('Horn - blue ice','#3983AC','#A6EDFF',False)
purple=painted('Eyes - amethyst','#7734B9','#D5A1FF',False)
dark=painted('Eye rims and mouth','#13182C','#303653',False)
pupil=painted('Pupils','#101529','#222744',False)
tooth=painted('Fangs','#91ABC4','#F4F8FF',False)
nosemat=painted('Nose','#1B2847','#4E6891',False)

def active(o):
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active=o

def sphere(name,loc,scale,mat=None,segments=20,rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if mat: o.data.materials.append(mat)
    for p in o.data.polygons:p.use_smooth=True
    parts.append(o); return o

def mesh(name,vs,fs,mat):
    me=bpy.data.meshes.new(name); me.from_pydata(vs,[],fs); me.update()
    o=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(o)
    me.materials.append(mat)
    active(o); bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False); bpy.ops.object.mode_set(mode='OBJECT')
    for p in me.polygons:p.use_smooth=True
    parts.append(o); return o

def lock(name,centers,widths,depths,mat,sides=8):
    # A swept, flattened sculpted lock; cross section lies in XY for vertical locks.
    vs=[]
    for (x,y,z),w,d in zip(centers,widths,depths):
        for i in range(sides):
            a=2*pi*i/sides; vs.append((x+cos(a)*w,y+sin(a)*d,z))
    fs=[tuple(range(sides-1,-1,-1))]
    for r in range(len(centers)-1):
        for i in range(sides):
            a=r*sides+i; b=r*sides+(i+1)%sides;fs.append((a,b,b+sides,a+sides))
    fs.append(tuple((len(centers)-1)*sides+i for i in range(sides)))
    return mesh(name,vs,fs,mat)

def tube(name,centers,radii,mat,sides=8,flatten=1):
    vs=[]
    for j,(c,r) in enumerate(zip(centers,radii)):
        c=Vector(c); tangent=Vector(centers[min(j+1,len(centers)-1)])-Vector(centers[max(j-1,0)])
        tangent.normalize(); u=tangent.cross(Vector((0,1,0))).normalized()
        if u.length<.1:u=tangent.cross(Vector((1,0,0))).normalized()
        v=tangent.cross(u).normalized()
        for i in range(sides):
            a=2*pi*i/sides;vs.append(c+r*cos(a)*u+r*sin(a)*v*flatten)
    fs=[tuple(range(sides-1,-1,-1))]
    for j in range(len(centers)-1):
        for i in range(sides):
            a=j*sides+i;b=j*sides+(i+1)%sides;fs.append((a,b,b+sides,a+sides))
    fs.append(tuple((len(centers)-1)*sides+i for i in range(sides)))
    return mesh(name,vs,fs,mat)

# Fuse the body, shoulders, head, jaw, arms and feet into a continuous sculpt.
sphere('Torso',(0,-.035,.60),(.34,.255,.43))
sphere('Head',(0,.015,1.12),(.435,.33,.385))
sphere('Jaw',(0,.17,.91),(.32,.245,.19))
for s in (-1,1):
    sphere('Shoulder',(s*.335,-.025,.83),(.19,.20,.22))
    o=sphere('Forearm',(s*.43,.015,.56),(.155,.175,.27));o.rotation_euler.y=s*-.15
    sphere('Paw',(s*.455,.055,.37),(.155,.17,.16))
    sphere('Thumb',(s*.35,.17,.39),(.07,.075,.105))
    sphere('Haunch',(s*.205,-.005,.235),(.16,.205,.23))
    sphere('Foot',(s*.205,.10,.095),(.18,.245,.095))
coreparts=parts[:]
active(coreparts[0])
for o in coreparts:o.select_set(True)
bpy.ops.object.join();core=bpy.context.object;core.name='Continuous sculpted body'
parts=[core]
rem=core.modifiers.new('Fuse anatomy','REMESH');rem.mode='VOXEL';rem.voxel_size=.024
bpy.ops.object.modifier_apply(modifier=rem.name)
sm=core.modifiers.new('Soften transitions','SMOOTH');sm.factor=1.2;sm.iterations=4
bpy.ops.object.modifier_apply(modifier=sm.name)
dec=core.modifiers.new('Body retopology budget','DECIMATE');dec.ratio=1350/sum(len(p.vertices)-2 for p in core.data.polygons)
bpy.ops.object.modifier_apply(modifier=dec.name)
core.data.materials.clear();core.data.materials.append(navy)
for p in core.data.polygons:p.use_smooth=True

# Broad cheeks sweep into fur tips, and small shoulder locks break up the outline.
for s in (-1,1):
    for i in range(3):
        z=1.08-i*.09
        lock('Cheek swept lock',[(s*.29,.225,z+.10),(s*.39,.26,z+.015),(s*(.51-i*.017),.20,z-.025),(s*(.48-i*.02),.17,z-.10)],
             [.105,.125,.06,.002],[.085,.105,.05,.002],face)
    for i in range(2):
        lock('Shoulder layered fur',[(s*(.32+i*.05),-.015,.88-i*.13),(s*(.43+i*.045),.045,.76-i*.13),(s*(.53+i*.03),.08,.63-i*.13)],
             [.12,.13,.003],[.155,.13,.003],slate)
    lock('Outer temple tuft',[(s*.30,-.06,1.30),(s*.41,-.055,1.28),(s*.48,-.01,1.34)], [.12,.09,.002],[.14,.09,.002],navy)
    # Curved horns, wider rooted bases with tapered swept tips.
    tube('Curved ice horn',[(s*.315,-.025,1.37),(s*.40,-.03,1.46),(s*.445,-.015,1.56),(s*.435,.01,1.65),(s*.40,.045,1.72)],
         [.105,.09,.065,.033,.0015],ice,10)

# The crest is a few wide swept shapes, not a collection of thin spikes.
lock('Crown rear sweep',[(0,-.17,1.28),(.015,-.18,1.47),(.06,-.13,1.61),(.15,-.08,1.68)], [.22,.18,.09,.002],[.16,.13,.07,.002],navy)
lock('Crown front sweep',[(-.07,.08,1.30),(-.05,.115,1.46),(.015,.09,1.57),(.095,.05,1.62)], [.17,.145,.085,.002],[.115,.11,.065,.002],slate)

# Subtle swept locks on the lower belly and back connect the shaggy design.
for x in (-.16,0,.16):
    lock('Belly fur sweep',[(x,.19,.52),(x+.015,.225,.43),(x+.05,.18,.30)], [.08,.10,.002],[.04,.045,.002],navy)
for x in (-.20,0,.20):
    lock('Back fur sweep',[(x,-.24,1.10),(x+.025,-.29,.98),(x+.06,-.24,.83)], [.10,.12,.002],[.055,.055,.002],navy)

# Lighter chest bib shaped into three overlapping locks.
for x,z,w in [(-.13,.76,.115),(.13,.76,.115),(0,.71,.15)]:
    lock('Chest bib',[(x,.218,z+.08),(x,.255,z),(x*.6,.26,z-.15),(x*.4,.24,z-.24)],
         [w*.6,w,w*.6,.002],[.025,.048,.035,.002],face)

# Face: shaped almond eye surfaces and sculpted brow strips.
def eye_patch(s, name, contour, y, mat, bulge=.025):
    # contour is positive-x; viewing front, inner to outer around lower lid.
    pts=[(s*x,y,z) for x,z in contour]; cx=sum(p[0] for p in pts)/len(pts);cz=sum(p[2] for p in pts)/len(pts)
    vs=[(cx,y+bulge,cz)]+pts
    fs=[(0,i+1,(i+1)%len(pts)+1) for i in range(len(pts))]
    return mesh(name,vs,fs,mat)

for s in (-1,1):
    eye_patch(s,'Dark recessed eye surround',[(.055,1.175),(.155,1.20),(.31,1.27),(.355,1.205),(.337,1.10),(.27,1.065),(.15,1.065),(.075,1.11)],.324,dark,.035)
    eye_patch(s,'Purple iris eye',[(.075,1.17),(.17,1.19),(.305,1.245),(.33,1.19),(.309,1.115),(.26,1.09),(.155,1.09),(.093,1.125)],.349,purple,.026)
    # Dark pupils lie on top of the iris without a separate material in the export.
    sphere('Pupil',(s*.196,.381,1.155),(.047,.012,.057),pupil,12,6)
    sphere('Painted eye glint',(s*.18,.394,1.183),(.012,.004,.014),tooth,8,4)
    tube('Heavy expressive brow',[(s*.058,.355,1.195),(s*.15,.36,1.255),(s*.27,.31,1.30),(s*.38,.24,1.31)],
         [.021,.063,.066,.006],face,8,flatten=.9)
    # Muzzle blends into pale cheek shapes; broad flattened cheek pads.
    sphere('Muzzle cheek',(s*.14,.315,1.00),(.185,.085,.105),face,16,8)
    # Two little sculpted fangs with soft taper.
    tube('Fang',[(s*.155,.403,1.002),(s*.16,.425,.97),(s*.15,.426,.928)], [.027,.021,.001],tooth,7)
    # Two broad toes per paw, flush with the underlying sculpt.
    for dx in (-.065,.065):
        sphere('Toe pad',(s*.205+dx,.264,.083),(.071,.075,.066),slate,10,6)

sphere('Lower muzzle',(0,.305,.93),(.23,.075,.075),face,16,8)
nose=sphere('Small nose',(0,.409,1.06),(.063,.037,.033),nosemat,12,6)
for s in (-1,1):sphere('Nostril',(s*.027,.440,1.054),(.013,.004,.007),dark,8,4)
tube('Grumpy mouth',[(-.195,.384,.95),(-.13,.405,.977),(0,.416,.993),(.13,.405,.977),(.195,.384,.95)], [.007,.009,.009,.009,.007],dark,6)

# Merge into one render mesh, retain an editable source copy before baking.
active(core)
for o in parts:o.select_set(True)
bpy.ops.object.join();ob=bpy.context.object;ob.name='FrostImp'
bpy.context.scene.cursor.location=(0,0,0)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
budget=ob.modifiers.new('Final silhouette-preserving reduction','DECIMATE')
budget.ratio=min(1,3450/sum(len(p.vertices)-2 for p in ob.data.polygons))
bpy.ops.object.modifier_apply(modifier=budget.name)
tri=ob.modifiers.new('Triangulated export','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=tri.name)
tris=len(ob.data.polygons)
print('PRE_BAKE_TRIANGLES',tris,flush=True)
# UV islands: angle-based charts with margins, non-overlapping and packed.
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.004,area_weight=.3,correct_aspect=True)
bpy.ops.object.mode_set(mode='OBJECT')
ob.data.uv_layers.active.name='UV_Albedo'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'frost_imp_sculpt.blend'))

# Bake color + painted occlusion into a single real UV image.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
scene.cycles.bake_type='EMIT';scene.render.bake.margin=4
img=bpy.data.images.new('frost_imp_v2_albedo',width=1024,height=1024,alpha=False)
img.generated_color=(.13,.18,.3,1)
for m in ob.data.materials:
    tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img;m.node_tree.nodes.active=tex
bpy.ops.object.bake(type='EMIT')
img.scale(512,512)
img.filepath_raw=str(OUT/'frost_imp_v2_albedo.png');img.file_format='PNG';img.save();img.pack()
mat=bpy.data.materials.new('FrostImp_Baked');mat.use_nodes=True
bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=1
bsdf.inputs['Specular IOR Level'].default_value=0
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img;tex.interpolation='Linear'
mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
ob.data.materials.clear();ob.data.materials.append(mat)
for p in ob.data.polygons:p.material_index=0
# Exact 0.70m tall, ground contact at zero, identity transforms.
minimum=min(v.co.z for v in ob.data.vertices); maximum=max(v.co.z for v in ob.data.vertices)
factor=.70/(maximum-minimum)
for v in ob.data.vertices:v.co=(Vector((v.co.x,v.co.y,v.co.z-minimum)))*factor
ob.data.update()
active(ob)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            space=area.spaces.active
            space.shading.type='MATERIAL'
            space.shading.use_scene_world=False
            space.shading.use_scene_lights=False
            space.region_3d.view_location=(0,0,.35)
            space.region_3d.view_distance=1.25
            space.region_3d.view_rotation=Vector((.65,2,1.15)).to_track_quat('Z','Y')
            space.region_3d.view_perspective='ORTHO'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'frost_imp_v2.blend'))
bpy.ops.export_scene.gltf(filepath=str(ASSET),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_materials='EXPORT',export_animations=False)
bpy.ops.uv.export_layout(filepath=str(OUT/'frost_imp_v2_uv.svg'),mode='SVG',size=(1024,1024),opacity=.35)
stats={'triangles':len(ob.data.polygons),'vertices':len(ob.data.vertices),'materials':len(ob.data.materials),'texture':[512,512],'height_m':.7,'rig':False,'blender_forward':'+Y','godot_forward':'-Z','origin':'ground center','source':str(OUT/'frost_imp_v2.blend'),'glb':str(ASSET)}
(OUT/'asset_report.json').write_text(json.dumps(stats,indent=2))
print('ASSET_REPORT',json.dumps(stats),flush=True)

# Render the exported GLB, not the procedural sculpt, for honest previews.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(ASSET))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32
scene.world.color=(.65,.65,.65)
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.64,.69,.78,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
scene.view_settings.exposure=0;scene.view_settings.gamma=1
scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=True
def area(loc,power,size):
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size
    o.rotation_euler=(Vector((0,0,.35))-o.location).to_track_quat('-Z','Y').to_euler()
area((-2,3,4),160,4)
bpy.ops.object.camera_add(location=(0,3,1))
cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=.89
for name,pos,target in [('front',(0,3,.38),(0,0,.35)),('topdown',(1.25,2.4,4.19),(0,0,.33)),('back',(-1.6,-3,1.7),(0,0,.34))]:
    cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/f'preview_{name}.png');bpy.ops.render.render(write_still=True)
# UI/achievement portrait from the same exported game mesh. Transparent, square and readable at 96 px.
cam.location=(0,3,.39);cam.rotation_euler=(Vector((0,0,.36))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.ortho_scale=.82
scene.render.resolution_x=96;scene.render.resolution_y=96;scene.render.resolution_percentage=100
scene.render.filepath=str(ROOT/'assets/ui/renders/chaser.png');bpy.ops.render.render(write_still=True)
print('BUILD_COMPLETE',flush=True)
