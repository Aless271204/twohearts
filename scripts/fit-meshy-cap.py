"""Produce a fitted derivative; keep the supplied Meshy mesh and textures intact."""
import hashlib
import json
import pathlib
import struct
import math

root = pathlib.Path(__file__).resolve().parents[1]
source = root / 'assets/runner/accessories/cap_pink_meshy.glb'
data = source.read_bytes()
json_length = struct.unpack_from('<I', data, 12)[0]
document = json.loads(data[20:20 + json_length])
binary = bytearray(data[28 + json_length:])
primitive = document['meshes'][0]['primitives'][0]

def attribute(name):
    accessor = document['accessors'][primitive['attributes'][name]]
    view = document['bufferViews'][accessor['bufferView']]
    return accessor, view.get('byteOffset', 0) + accessor.get('byteOffset', 0), view.get('byteStride', 12)

positions, position_offset, stride = attribute('POSITION')
points = []
for i in range(positions['count']):
    x, y, z = struct.unpack_from('<fff', binary, position_offset + i * stride)
    # Lower the crown around its band. Shorten only the forward visor,
    # leaving the heart, seams and embedded UV/material assignments in place.
    y = -.15 + (y + .15) * .72
    z = -.10 + (z + .10) * .85 if z <= .12 else .087 + (z - .12) * .50
    points.append((x, y, z))
    struct.pack_into('<fff', binary, position_offset + i * stride, x, y, z)
positions['min'] = [min(p[k] for p in points) for k in range(3)]
positions['max'] = [max(p[k] for p in points) for k in range(3)]

# Recompute normals from the edited surface instead of retaining old shading.
indices = document['accessors'][primitive['indices']]
view = document['bufferViews'][indices['bufferView']]
offset = view.get('byteOffset', 0) + indices.get('byteOffset', 0)
fmt, size = {5125: ('I', 4), 5123: ('H', 2)}[indices['componentType']]
normals = [[0., 0., 0.] for _ in points]
for i in range(0, indices['count'], 3):
    ids = [struct.unpack_from('<' + fmt, binary, offset + (i + k) * size)[0] for k in range(3)]
    a, b, c = [points[k] for k in ids]
    u, v = [b[k] - a[k] for k in range(3)], [c[k] - a[k] for k in range(3)]
    n = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
    for vertex in ids:
        for k in range(3): normals[vertex][k] += n[k]
normal_accessor, normal_offset, normal_stride = attribute('NORMAL')
for i, normal in enumerate(normals):
    length = math.sqrt(sum(v*v for v in normal)) or 1
    struct.pack_into('<fff', binary, normal_offset + i * normal_stride, *(v/length for v in normal))
normal_accessor.pop('min', None)
normal_accessor.pop('max', None)
encoded = json.dumps(document, separators=(',', ':')).encode()
encoded += b' ' * (-len(encoded) % 4)
output = struct.pack('<III', 0x46546c67, 2, 28+len(encoded)+len(binary))
output += struct.pack('<II', len(encoded), 0x4e4f534a) + encoded
output += struct.pack('<II', len(binary), 0x004e4942) + binary
destination = 'assets/runner/accessories/cap_pink_fitted.glb'
(root / destination).write_bytes(output)
registry_path = root / 'assets/runner/head-models.json'
registry = json.loads(registry_path.read_text(encoding='utf-8'))
item = next(i for i in registry if i['item_key'] == 'cap_pink')
item['appearance']['model_asset'] = destination
item['appearance']['head_fit'] = json.loads((root / 'assets/runner/head-fit-profiles.json').read_text(encoding='utf-8'))['cap_pink']
item['source_sha256'] = hashlib.sha256(data).hexdigest()
item['sha256'] = hashlib.sha256(output).hexdigest()
item['fit_status'] = 'pending_visual_review'
registry_path.write_text(json.dumps(registry, ensure_ascii=False, indent=2), encoding='utf-8')
print('Fitted cap exported; original, triangle count and embedded textures preserved.')
