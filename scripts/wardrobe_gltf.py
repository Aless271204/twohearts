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
    names = list(data['boneNames'])
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
    names = list(data['boneNames'])
    surface = source_surface(data)
    sleeve_surfaces={}
    profile=data.get('garment_skin_profile',{})
    sleeve_fit={}
    if profile.get('surface_sleeve_anchors'):
        source=max(data['meshes'],key=lambda mesh:len(mesh['positions']))
        for side,sign in [('Left',1),('Right',-1)]:
            candidates=[]
            for i in range(len(source['positions'])//3):
                point=source['positions'][i*3:i*3+3]
                arm=sum(weight for bone,weight in zip(source['skinIndex'][i*4:i*4+4],source['skinWeight'][i*4:i*4+4]) if names[bone].endswith(tuple(side+suffix for suffix in ('Shoulder','Arm','ForeArm','Hand','HandMiddle1','HandMiddle2','HandMiddle3','HandMiddle4'))))
                if arm>.35 and sign*point[0]>.10:candidates.append(i)
            if len(candidates)<12:raise ValueError('Faltan vértices originales para ajustar la manga '+side)
            threshold=sorted(source['positions'][i*3+1] for i in candidates)[int(len(candidates)*.60)]
            selected=[i for i in candidates if source['positions'][i*3+1]>=threshold]
            ordered=sorted(candidates,key=lambda i:source['positions'][i*3+1]);ends=max(4,len(ordered)//6)
            mid_z=sum(source['positions'][i*3+2] for i in candidates)/len(candidates)
            groups={'center':selected,'top':ordered[-ends:],'bottom':ordered[:ends],'front':[i for i in candidates if source['positions'][i*3+2]>=mid_z],'back':[i for i in candidates if source['positions'][i*3+2]<mid_z]}
            if any(not group for group in groups.values()):raise ValueError('El ajuste original de la manga es degenerado')
            sleeve_fit[side]={'mesh':source['name'],'groups':groups}
            if profile.get('preserve_authored_sleeve_contact'):sleeve_fit[side]['preserve_authored_contact']=True
            shape=profile.get('volumetric_sleeves')
            if shape:sleeve_fit[side]['garment_center']=[sign*shape['center'][0],*shape['center'][1:]]
            names.append('Nido'+side+'Sleeve')
    if profile.get('sleeve_original_surface'):
        for side in ('Left','Right'):
            field=[]
            for mapping in surface.weights:
                selected={bone:weight for bone,weight in mapping.items() if names[bone].endswith(tuple(side+suffix for suffix in ('Shoulder','Arm','ForeArm')))}
                field.append(selected)
            triangles=[triangle for triangle in surface.triangles if sum(sum(field[v].values()) for v in triangle)/3>.35]
            fallback=next(k for k,name in enumerate(names) if name.endswith(side+'Arm'))
            sleeve_surfaces[side]=SurfaceSkin(surface.points,triangles,[dict(normalized_weights(mapping,fallback)) for mapping in field],fallback)

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
        profile=data.get('garment_skin_profile')
        for primitive_index, primitive in enumerate(mesh['primitives']):
            positions = _attribute(doc, binary, primitive['attributes']['POSITION'])
            sampled = [skin_source.sample(point) for point in positions]
            if _is_fabric(mesh):
                is_body=not mesh.get('name','').replace('_',' ').startswith('Patrón cuello')
                profile=data.get('garment_skin_profile')
                preserve_surface=bool(profile and profile.get('preserve_torso_surface'))
                if not preserve_surface:sampled = [cloth_weights(weights, names,body=is_body) for weights in sampled]
                if is_body and data.get('body') and not preserve_surface:
                    index=(_attribute(doc,binary,primitive['indices']) if 'indices' in primitive else [(i,) for i in range(len(positions))])
                    sampled=smooth_shoulder_field(positions,[i[0] for i in index],sampled,data['body'])
                if is_body and profile:
                    # New sleeves are sewn outside the skin. Their outer crown
                    # must follow the upper arm, rather than a nearby head vertex.
                    # Only garment weights change; source pet weights are immutable.
                    start,full=profile['shoulder_start'],profile['sleeve_full']
                    for i,point in enumerate(positions):
                        if profile.get('stable_torso'):
                            torso=next(k for k,name in enumerate(names) if name.endswith('Spine2'))
                            sampled[i]={torso:1.0}
                        if profile.get('torso_joint_mask'):
                            mapping={bone:weight for bone,weight in sampled[i].items() if names[bone].endswith(('Hips','Spine','Spine1','Spine2'))}
                            sampled[i]=dict(normalized_weights(mapping,next(k for k,name in enumerate(names) if name.endswith('Spine2'))))
                        blend=max(0.0,min(1.0,(abs(point[0])-start)/(full-start)))
                        blend=blend*blend*(3-2*blend)
                        vertical=max(0.0,min(1.0,(point[1]-profile['sleeve_min_y'])/profile.get('sleeve_fade_y',.06)))
                        if abs(point[0])>=full:vertical=1.0
                        blend*=vertical*vertical*(3-2*vertical)
                        shape=profile.get('volumetric_sleeves')
                        if shape:
                            center=shape['center'];radius=shape['radius']
                            distance=sum(((coordinate-origin)/size)**2 for coordinate,origin,size in zip((abs(point[0]),point[1],point[2]),center,radius))**.5
                            blend=max(0.0,min(1.0,(1.45-distance)/.25))
                            if point[1]<.365 and abs(point[0])<full:blend=0.0
                            if abs(point[0])<start:blend=0.0
                        for cuff in profile.get('cuff_areas',[]):
                            displacement=Vector(point)-Vector(cuff['center']);normal=Vector(cuff['normal'])
                            if abs(displacement.dot(normal))<.022 and displacement.length<.13:blend=1.0
                        if profile.get('sleeve_root_fade'):
                            cuff_y,root_y=profile['sleeve_root_fade']
                            root_blend=max(0.0,min(1.0,(root_y-point[1])/(root_y-cuff_y)))
                            blend*=root_blend*root_blend*(3-2*root_blend)
                        if not blend:continue
                        side='Left' if point[0]>0 else 'Right'
                        arm=names.index('Nido'+side+'Sleeve') if profile.get('surface_sleeve_anchors') else next(k for k,name in enumerate(names) if name.endswith(side+'Arm'))
                        mapping={bone:weight*(1-blend) for bone,weight in sampled[i].items()}
                        sleeve=sleeve_surfaces[side].sample(point) if side in sleeve_surfaces else {arm:1.0}
                        for bone,weight in sleeve.items():mapping[bone]=mapping.get(bone,0.0)+blend*weight
                        sampled[i]=dict(normalized_weights(mapping))
            sewn=profile.get('sewn_sleeve_field') if profile and _is_fabric(mesh) else None
            if sewn:
                from mathutils.kdtree import KDTree
                field=KDTree(len(sewn))
                for field_index,entry in enumerate(sewn):field.insert(Vector(entry[:3]),field_index)
                field.balance()
                torso=next(k for k,name in enumerate(names) if name.endswith('Spine2'))
                neck=next((k for k,name in enumerate(names) if name.endswith('Neck')),torso)
                for i,point in enumerate(positions):
                    _,field_index,_=field.find(Vector(point));entry=sewn[field_index]
                    blend=entry[4]
                    neck_blend=entry[5] if len(entry)>5 else 0.0
                    mapping={torso:(1-blend)*(1-neck_blend)}
                    if neck_blend:
                        contact={neck:1.0} if profile.get('sewn_neck_joint') else surface.sample(point)
                        contact={bone:weight for bone,weight in contact.items() if names[bone].endswith(('Head','Neck','Spine','Spine1','Spine2','Shoulder','Arm','ForeArm','Hand'))}
                        for bone,weight in normalized_weights(contact,neck):mapping[bone]=mapping.get(bone,0.0)+(1-blend)*neck_blend*weight
                    if blend:
                        if profile.get('sewn_surface_skin'):
                            contact=surface.sample(point)
                            contact={bone:weight for bone,weight in contact.items() if not names[bone].endswith(('UpLeg','Leg','Foot','ToeBase'))}
                            for bone,weight in normalized_weights(contact,torso):mapping[bone]=mapping.get(bone,0.0)+blend*weight
                        else:
                            arm=names.index('Nido'+('Left' if entry[3]>0 else 'Right')+'Sleeve')
                            mapping[arm]=blend
                    sampled[i]=dict(normalized_weights(mapping,torso))
                # Relax the sewn weight field across shared cloth vertices.
                # The source rig has abrupt head/arm changes; transfer their
                # motion smoothly instead of imprinting those changes as tears.
                ids={};groups=[];members=[]
                for i,p in enumerate(positions):
                    key=tuple(round(x,6) for x in p)
                    if key not in ids:ids[key]=len(groups);groups.append([]);members.append([])
                    g=ids[key];groups[g].append(i);members[g].append(p)
                adjacency=[set() for _ in groups]
                flat=[row[0] for row in _attribute(doc,binary,primitive['indices'])]
                vertex_group={i:g for g,vertices in enumerate(groups) for i in vertices}
                for k in range(0,len(flat),3):
                    tri=[vertex_group[i] for i in flat[k:k+3]]
                    for a in tri:adjacency[a].update(b for b in tri if a!=b)
                fields=[]
                for vertices in groups:
                    mapping={}
                    for i in vertices:
                        for bone,weight in sampled[i].items():mapping[bone]=mapping.get(bone,0)+weight/len(vertices)
                    fields.append(mapping)
                for iteration in range(0 if profile.get('field_pre_smoothed') else 8):
                    relaxed=[]
                    for g,vertices in enumerate(groups):
                        p=positions[vertices[0]]
                        if abs(p[0])<.15 or p[1]>.570 or not adjacency[g]:relaxed.append(fields[g]);continue
                        mapping={bone:weight*.55 for bone,weight in fields[g].items()}
                        for neighbor in adjacency[g]:
                            for bone,weight in fields[neighbor].items():mapping[bone]=mapping.get(bone,0)+.45*weight/len(adjacency[g])
                        relaxed.append(dict(normalized_weights(mapping,torso)))
                    fields=relaxed
                for g,vertices in enumerate(groups):
                    for i in vertices:sampled[i]=fields[g]
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

    sleeve_metadata_written=False
    for mesh_index, mesh in enumerate(doc['meshes']):
        extras = mesh.setdefault('extras', {})
        extras['nidoBoneNames'] = names
        # The loader creates one shared pair of clothing joints per garment.
        # Duplicating thousands of identical source indices on every stitch and
        # button inflated the GLB without adding any geometry or precision.
        if sleeve_fit and not sleeve_metadata_written and _is_fabric(mesh):
            extras['nidoSleeveFit']=sleeve_fit;sleeve_metadata_written=True
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
                if data.get('surface_footwear'):
                    # Exposed paws are often weighted to Leg/Toe as well as
                    # Foot in the immutable original rig. A rigid Foot-only
                    # sandal drifted away from that real skin during jumps.
                    blend=dict(normalized_weights(data['footwear_blends'][foot]))
                    bone=next(i for i,name in enumerate(names) if name.endswith(foot+'Foot'))
                    sampled=[{bone:1.0} for _ in positions]
                    extras['nidoSkinTransfer']={'method':'original_paw_anchor','version':TRANSFER_VERSION,'paw_weights':{names[k]:v for k,v in blend.items()}}
                else:
                    bone = next(i for i, name in enumerate(names) if name.endswith(foot + 'Foot'))
                    sampled = [{bone: 1.0} for _ in positions]
                    extras['nidoSkinTransfer'] = {'method':'rigid_named_foot','version':TRANSFER_VERSION,'bone':names[bone]}
            elif data.get('rigid_garment_bone'):
                bone=next(i for i,name in enumerate(names) if name.endswith(data['rigid_garment_bone']))
                sampled=[{bone:1.0} for _ in positions]
                extras['nidoSkinTransfer']={'method':'rigid_named_joint','version':TRANSFER_VERSION,'bone':names[bone]}
            if sampled is None:
                source=surface if mesh.get('name','').replace('_',' ').startswith('Forro interior cosido') else detail_surface
                sampled = [source.sample(point) for point in positions]
            # The raw edge and its binding share one height-based neck field.
            # Sampling independently selected nearby sleeve vertices, lifting
            # the outer cloth into a jagged lip while the binding stayed flat.
            neckline=profile.get('continuous_neck_binding')
            if neckline and not foot:
                torso=next((k for k,name in enumerate(names) if name.endswith('Spine2')),surface.fallback)
                neck=next((k for k,name in enumerate(names) if name.endswith('Neck')),torso)
                lower=neckline['lower'];upper=neckline['upper']
                for i,p in enumerate(positions):
                    if p[1]<lower:continue
                    t=max(0,min(1,(p[1]-lower)/(upper-lower)))
                    w=.5
                    sampled[i]={torso:1-w,neck:w}
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
