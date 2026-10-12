"""Transfer real surface skinning to exported clothes and their decorations.

The Blender snapshot is the app's normalized, posed pet, not its unposed GLB.
Each primary fabric vertex receives the barycentric skin weights of the closest
triangle on that real surface. Draped panels inherit the primary cloth's field;
decorations sample the combined cloth, so embroidery follows its own pocket,
frill or sleeve rather than the pet surface below it.
"""
import json
import struct

from mathutils import Vector
from mathutils.bvhtree import BVHTree


TRANSFER_VERSION = 3
_cached_data = None
_cached_surface = None


def normalized_weights(weights, fallback=0):
    """Retain the four strongest original influences, in glTF's four-slot form."""
    selected = sorted(((int(b), float(w)) for b, w in weights.items() if w > 0),
                      key=lambda entry: (-entry[1], entry[0]))[:4]
    total = sum(w for _, w in selected)
    if total <= 1e-12:
        return [(fallback, 1.0)]
    return [(b, w / total) for b, w in selected]


def cloth_weights(weights, names, body=False):
    """A torso or neck garment ends above the legs; they cannot pull its hem.

    Keep the original arm, shoulder and neck blend. Redirect any influence from
    a thigh/foot to the hip at its root, rather than deleting it and changing the
    proportions of the remaining spine weights. Details inherit this same field.
    """
    hips = next((i for i, name in enumerate(names) if name.endswith('Hips')), 0)
    spine = next((i for i, name in enumerate(names) if name.endswith('Spine2')), hips)
    result = {}
    for bone, weight in weights.items():
        name = names[bone]
        target = hips if name.endswith(('UpLeg', 'Leg', 'Foot', 'ToeBase', 'Toe_End')) else spine if body and name.endswith(('Head','Neck')) else bone
        result[target] = result.get(target, 0.0) + weight
    return dict(normalized_weights(result, hips))


def smooth_shoulder_field(positions, indices, weights, body, iterations=12):
    """Regularize nearby arm/spine transitions on continuous stitched cloth.

    UV seams duplicate vertices; weld their fields in memory without touching
    positions, normals or UVs. Keep the chest/hem field outside the shoulders.
    """
    groups, group_for = {}, []
    for point in positions:
        key=tuple(round(value,5) for value in point)
        group_for.append(groups.setdefault(key,len(groups)))
    members=[[] for _ in groups]
    for i,group in enumerate(group_for):members[group].append(i)
    neighbors=[set() for _ in groups]
    for i in range(0,len(indices),3):
        triangle=[group_for[k] for k in indices[i:i+3]]
        for a in triangle:neighbors[a].update(b for b in triangle if b!=a)
    field=[]
    for vertices in members:
        combined={}
        for i in vertices:
            for bone,value in weights[i].items():combined[bone]=combined.get(bone,0)+value/len(vertices)
        field.append(dict(normalized_weights(combined)))
    width=max(abs(body['min'][0]),abs(body['max'][0]))
    selected=[abs(positions[vertices[0]][0])>=width*.55 and positions[vertices[0]][1]>=body['max'][1]-.22 for vertices in members]
    for _ in range(iterations):
        updated=[]
        for i,mapping in enumerate(field):
            if not selected[i] or not neighbors[i]:updated.append(mapping);continue
            combined={bone:value*.60 for bone,value in mapping.items()}
            for j in neighbors[i]:
                for bone,value in field[j].items():combined[bone]=combined.get(bone,0)+value*.40/len(neighbors[i])
            updated.append(dict(normalized_weights(combined)))
        field=updated
    return [field[group] for group in group_for]


def barycentric(point, a, b, c):
    """Coordinates of a projected point on a nondegenerate source triangle."""
    ab, ac, ap = b - a, c - a, point - a
    # Boolean shoulder unions can produce narrow but valid triangles. Cross
    # products avoid cancellation of nearly equal dot-product terms in the
    # float32 mathutils vectors; this is still barycentric interpolation.
    normal = ab.cross(ac)
    denominator = normal.length_squared
    if denominator <= 1e-20:
        raise ValueError('Cannot transfer weights from a degenerate triangle')
    v = ap.cross(ac).dot(normal) / denominator
    w = ab.cross(ap).dot(normal) / denominator
    # A nearest-point query is inside/on the triangle. Clamp rounding errors
    # at edges instead of permitting a negative bone influence.
    result = [max(0.0, 1 - v - w), max(0.0, v), max(0.0, w)]
    total = sum(result)
    return [x / total for x in result]


class SurfaceSkin:
    """A triangle BVH and the original skin field defined on its vertices."""

    def __init__(self, points, triangles, weights, fallback=0):
        self.points = [Vector(p) for p in points]
        self.weights = weights
        self.fallback = fallback
        self.triangles = []
        for triangle in triangles:
            a, b, c = (self.points[i] for i in triangle)
            if (b - a).cross(c - a).length_squared > 1e-20:
                self.triangles.append(tuple(triangle))
        if not self.triangles:
            raise ValueError('Skin transfer requires a nonempty triangle surface')
        self.tree = BVHTree.FromPolygons(self.points, self.triangles,
                                        all_triangles=True)

    def sample(self, point):
        projected, normal, face, distance = self.tree.find_nearest(Vector(point))
        if face is None:
            raise ValueError('Skin transfer did not find a surface triangle')
        triangle = self.triangles[face]
        factors = barycentric(projected, *(self.points[i] for i in triangle))
        mixed = {}
        for vertex, factor in zip(triangle, factors):
            for bone, weight in self.weights[vertex].items():
                mixed[bone] = mixed.get(bone, 0.0) + factor * weight
        return dict(normalized_weights(mixed, self.fallback))


def pet_surface(data):
    """Preserve the pet's complete skin field, including its rounded PG parts."""
    names = data['boneNames']
    spine = next((i for i, name in enumerate(names) if name.endswith('Spine2')), 0)
    points, triangles, weights = [], [], []
    for mesh in data['meshes']:
        offset = len(points)
        rigid_bone = spine
        # Refined PG wings/lining are attached to Spine2. Its reconstructed feet
        # and ankle feathers are attached to each real Foot bone instead.
        for side in ('Left', 'Right'):
            if mesh['name'].startswith(side) and mesh['name'].endswith(('RoundedFoot', 'FeatheredAnkle')):
                rigid_bone = next((i for i, name in enumerate(names)
                                   if name.endswith(side + 'Foot')), spine)
        for i in range(len(mesh['positions']) // 3):
            points.append(mesh['positions'][i * 3:i * 3 + 3])
            if mesh.get('skinWeight'):
                mapping = {}
                for bone, weight in zip(mesh['skinIndex'][i * 4:i * 4 + 4],
                                        mesh['skinWeight'][i * 4:i * 4 + 4]):
                    mapping[int(bone)] = mapping.get(int(bone), 0.0) + weight
                # Source GLB weights are already normalized. Normalize duplicate
                # indices without replacing or filtering any anatomical bones.
                weights.append(dict(normalized_weights(mapping, spine)))
            else:
                weights.append({rigid_bone: 1.0})
        for i in range(0, len(mesh['indices']), 3):
            triangles.append(tuple(offset + k for k in mesh['indices'][i:i + 3]))
    return SurfaceSkin(points, triangles, weights, spine)


def source_surface(data):
    global _cached_data, _cached_surface
    if _cached_data is not data:
        _cached_surface = pet_surface(data)
        _cached_data = data
    return _cached_surface


def _attribute(doc, binary, index):
    accessor = doc['accessors'][index]
    view = doc['bufferViews'][accessor['bufferView']]
    size, fmt = {5121: (1, 'B'), 5123: (2, 'H'), 5125: (4, 'I'),
                 5126: (4, 'f')}[accessor['componentType']]
    components = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[accessor['type']]
    start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
    stride = view.get('byteStride', size * components)
    return [struct.unpack_from('<' + fmt * components, binary, start + i * stride)
            for i in range(accessor['count'])]


def _is_fabric(mesh):
    name = mesh.get('name', '').replace('_', ' ')
    return name.startswith(('Patrón envolvente', 'Manga adaptada', 'Patrón cuello'))


def _is_secondary_fabric(mesh):
    name = mesh.get('name', '').replace('_', ' ')
    return name.startswith(('Panel ·', 'Volante pétalo'))


def add_skin_attributes(path, data):
    from wardrobe_export_seams import repair_export
    repair_export(path)
    blob = path.read_bytes()
    json_length = struct.unpack_from('<I', blob, 12)[0]
    doc = json.loads(blob[20:20 + json_length])
    binary = bytearray(blob[28 + json_length:])
    names = data['boneNames']
    surface = source_surface(data)

    def append(values, fmt, component_type, count, existing=None):
        packed = struct.pack('<' + fmt * len(values), *values)
        if existing is not None:
            accessor = doc['accessors'][existing]
            view = doc['bufferViews'][accessor['bufferView']]
            if (accessor['count'] == count and accessor['componentType'] == component_type
                    and not view.get('byteStride') and view['byteLength'] == len(packed)):
                offset = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
                binary[offset:offset + len(packed)] = packed
                return existing
        while len(binary) % 4:
            binary.append(0)
        offset = len(binary)
        binary.extend(packed)
        view = len(doc['bufferViews'])
        doc['bufferViews'].append({'buffer': 0, 'byteOffset': offset,
                                 'byteLength': len(packed)})
        accessor = len(doc['accessors'])
        doc['accessors'].append({'bufferView': view, 'componentType': component_type,
                                'count': count, 'type': 'VEC4'})
        return accessor

    # First bind the primary panels to the pet. Do not bind a flared skirt/frill
    # straight to the pet: a nearby foot or leg is not its attachment surface.
    cloth_points, cloth_triangles, fabric_weights = [], [], []
    samples = {}

    def add_panel(mesh_index, mesh, skin_source):
        for primitive_index, primitive in enumerate(mesh['primitives']):
            positions = _attribute(doc, binary, primitive['attributes']['POSITION'])
            sampled = [skin_source.sample(point) for point in positions]
            if _is_fabric(mesh):
                is_body=not mesh.get('name','').replace('_',' ').startswith('Patrón cuello')
                sampled = [cloth_weights(weights, names,body=is_body) for weights in sampled]
                if is_body and data.get('body'):
                    index=(_attribute(doc,binary,primitive['indices']) if 'indices' in primitive else [(i,) for i in range(len(positions))])
                    sampled=smooth_shoulder_field(positions,[i[0] for i in index],sampled,data['body'])
            samples[mesh_index, primitive_index] = sampled
            offset = len(cloth_points)
            cloth_points.extend(positions)
            fabric_weights.extend(sampled)
            index = (_attribute(doc, binary, primitive['indices'])
                     if 'indices' in primitive else [(i,) for i in range(len(positions))])
            flat = [i[0] for i in index]
            if primitive.get('mode', 4) != 4:
                raise ValueError('Wardrobe fabric must export triangle primitives')
            cloth_triangles.extend(tuple(offset + k for k in flat[i:i + 3])
                                   for i in range(0, len(flat), 3))

    for mesh_index, mesh in enumerate(doc['meshes']):
        if _is_fabric(mesh):
            add_panel(mesh_index, mesh, surface)
    primary_surface = (SurfaceSkin(cloth_points, cloth_triangles, fabric_weights,
                                  surface.fallback) if cloth_triangles else surface)
    # Secondary fabric samples only the complete primary cloth, not secondary
    # panels encountered earlier in file order. This keeps refresh deterministic
    # and avoids pockets/ruffles accidentally inheriting one another's weights.
    for mesh_index, mesh in enumerate(doc['meshes']):
        if _is_secondary_fabric(mesh):
            add_panel(mesh_index, mesh, primary_surface)
    # Details see both primary and secondary fabric. A flower on a flared hem
    # therefore follows that hem's local deformation, not the torso behind it.
    detail_surface = (SurfaceSkin(cloth_points, cloth_triangles, fabric_weights,
                                 surface.fallback) if cloth_triangles else surface)

    for mesh_index, mesh in enumerate(doc['meshes']):
        extras = mesh.setdefault('extras', {})
        extras['nidoBoneNames'] = names
        extras['nidoSkinTransfer'] = {
            'method': 'closest_triangle_barycentric', 'version': TRANSFER_VERSION,
            'anatomy': 'torso_without_leg_pull',
            'source': 'pet_surface' if _is_fabric(mesh) else 'garment_surface',
            'stage': ('primary' if _is_fabric(mesh) else 'secondary'
                      if _is_secondary_fabric(mesh) else 'decoration')}
        for primitive_index, primitive in enumerate(mesh['primitives']):
            positions = _attribute(doc, binary, primitive['attributes']['POSITION'])
            sampled = samples.get((mesh_index, primitive_index))
            foot = next((side for side in ('Left', 'Right') if mesh.get('name', '').replace('_', ' ').startswith('Calzado · ' + side)), None)
            if foot:
                bone = next(i for i, name in enumerate(names) if name.endswith(foot + 'Foot'))
                sampled = [{bone: 1.0} for _ in positions]
                extras['nidoSkinTransfer'] = {'method':'rigid_named_foot','version':TRANSFER_VERSION,'bone':names[bone]}
            if sampled is None:
                sampled = [detail_surface.sample(point) for point in positions]
            joints, skin_weights = [], []
            for mapping in sampled:
                chosen = list(mapping.items()) + [(0, 0)] * (4 - len(mapping))
                joints.extend(bone for bone, _ in chosen)
                skin_weights.extend(weight for _, weight in chosen)
            attrs = primitive['attributes']
            attrs['JOINTS_0'] = append(joints, 'H', 5123, len(positions), attrs.get('JOINTS_0'))
            attrs['WEIGHTS_0'] = append(skin_weights, 'f', 5126, len(positions), attrs.get('WEIGHTS_0'))
    doc['buffers'][0]['byteLength'] = len(binary)
    chunk = json.dumps(doc, separators=(',', ':')).encode()
    chunk += b' ' * (-len(chunk) % 4)
    path.write_bytes(struct.pack('<III', 0x46546c67, 2, 28 + len(chunk) + len(binary))
                     + struct.pack('<II', len(chunk), 0x4e4f534a) + chunk
                     + struct.pack('<II', len(binary), 0x004e4942) + binary)
