"""Inspect the final GLB buffers, independent of the Blender construction script."""
import json, math, struct
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
path = ROOT / 'assets/models/chaser.glb'
data=path.read_bytes()
magic,version,length=struct.unpack_from('<III',data)
assert magic == 0x46546c67 and version == 2 and length == len(data)
size,kind=struct.unpack_from('<II',data,12)
doc=json.loads(data[20:20+size]); pos=20+size
bin_size,bin_kind=struct.unpack_from('<II',data,pos); binary=data[pos+8:pos+8+bin_size]
def read_accessor(index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
    count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
    stride=v.get('byteStride',struct.calcsize('<'+fmt*count))
    offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*count,binary,offset+i*stride) for i in range(a['count'])]
assert len(doc['meshes'])==1 and len(doc['materials'])==1 and len(doc['images'])==1
assert not doc.get('skins') and not doc.get('animations')
primitives=doc['meshes'][0]['primitives'];assert len(primitives)==1
p=primitives[0]; assert p.get('mode',4)==4
vertices=read_accessor(p['attributes']['POSITION']);uvs=read_accessor(p['attributes']['TEXCOORD_0'])
normals=read_accessor(p['attributes']['NORMAL']);indices=[v[0] for v in read_accessor(p['indices'])]
assert len(indices)//3==3450
assert max(indices)<len(vertices)
assert all(math.isfinite(v) for row in vertices+uvs+normals for v in row)
assert all(-.0001<=v<=1.0001 for row in uvs for v in row)
assert all(abs(sum(v*v for v in row)-1)<.01 for row in normals)
lo=[min(v[i] for v in vertices) for i in range(3)]
hi=[max(v[i] for v in vertices) for i in range(3)]
assert abs(lo[1])<1e-5 and abs(hi[1]-.7)<1e-5
uv_area=0;zero=0
for i in range(0,len(indices),3):
    a,b,c=[uvs[j] for j in indices[i:i+3]]
    area=abs((b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]))*.5
    uv_area+=area
    if area<1e-12:zero+=1
assert zero==0, f'{zero} collapsed UV triangles'
report={'passed':True,'triangles':len(indices)//3,'exported_vertices_with_uv_splits':len(vertices),
        'meshes':1,'surfaces':1,'materials':1,'embedded_images':1,'rig':False,
        'godot_bounds_min':lo,'godot_bounds_max':hi,'uv_area_fraction':uv_area,
        'collapsed_uv_triangles':zero,'finite_buffers':True,'normalized_normals':True,
        'file_bytes':len(data)}
(ROOT/'art_src/frost_imp_v2/validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
