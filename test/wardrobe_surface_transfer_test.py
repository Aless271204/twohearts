"""Run with Blender --background --python test/wardrobe_surface_transfer_test.py.

Tests the contact/weight-transfer algorithm without regenerating any app assets.
"""
import json
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from wardrobe_gltf import SurfaceSkin, add_skin_attributes, normalized_weights, pet_surface, barycentric, cloth_weights, smooth_shoulder_field
from mathutils import Vector


class SurfaceTransferTest(unittest.TestCase):
    def test_shoulder_field_softens_transition_and_welds_uv_seams_without_touching_chest(self):
        points=[(.1,.2,0),(.2,.4,0),(.21,.4,0),(.2,.41,0),(.2,.4,0)]
        mapping=[{0:1},{0:1},{1:1},{1:1},{1:1}]
        result=smooth_shoulder_field(points,[1,2,3,4,3,2],mapping,{'min':[-.25,0,0],'max':[.25,.5,0]})
        self.assertEqual(result[0],mapping[0])
        self.assertEqual(result[1],result[4])
        self.assertLess(abs(result[1].get(1,0)-result[2].get(1,0)),.5)
        for weights in result:
            self.assertAlmostEqual(sum(weights.values()),1)
            self.assertTrue(all(0<=w<=1 for w in weights.values()))

    def test_leg_influence_is_redirected_without_changing_arm_or_neck_weights(self):
        names = ['mixamorigHips', 'mixamorigSpine2', 'mixamorigLeftUpLeg', 'mixamorigLeftArm', 'mixamorigNeck']
        actual = cloth_weights({0:.15, 1:.35, 2:.30, 3:.10, 4:.10}, names)
        self.assert_weights(actual, {0:.45, 1:.35, 3:.10, 4:.10})
        self.assertEqual(cloth_weights({2:1}, names), {0:1})

    def test_narrow_boolean_triangle_retains_barycentric_weights(self):
        points = [Vector(p) for p in [(0,0,0), (.30,0,0), (.299999,.00003,0)]]
        factors = barycentric(sum(points, Vector((0,0,0)))/3, *points)
        self.assert_weights(dict(enumerate(factors)), {0:1/3,1:1/3,2:1/3}, .001)
        # BVH projection itself may snap a nearly degenerate face to an edge;
        # those samples still need valid normalized, nonnegative influences.
        skin = SurfaceSkin(points, [(0,1,2)], [{0:1},{1:1},{2:1}])
        sample=skin.sample((.1999996667,.00001,.001))
        self.assertAlmostEqual(sum(sample.values()),1)
        self.assertTrue(all(0<=w<=1 for w in sample.values()))

    def test_shirt_follows_chest_instead_of_head_but_scarf_retains_neck(self):
        names=['Hips','Spine2','Neck','Head','LeftArm']
        mapping={1:.3,2:.2,3:.4,4:.1}
        self.assert_weights(cloth_weights(mapping,names,body=True),{1:.9,4:.1})
        self.assert_weights(cloth_weights(mapping,names),mapping)

    def assert_weights(self, actual, expected, tolerance=2e-5):
        for bone in set(actual) | set(expected):
            self.assertAlmostEqual(actual.get(bone, 0), expected.get(bone, 0), delta=tolerance)

    def test_projection_interpolates_the_real_face_instead_of_nearby_vertices(self):
        points = [(0, 0, 0), (1, 0, 0), (0, 1, 0),
                  (0, 0, .04), (1, 0, .04), (0, 1, .04)]
        skin = SurfaceSkin(points, [(0, 1, 2), (3, 4, 5)],
                           [{0: 1}, {1: 1}, {2: 1}, {3: 1}, {3: 1}, {3: 1}])
        self.assert_weights(skin.sample((.25, .25, .001)), {0: .5, 1: .25, 2: .25})
        self.assert_weights(skin.sample((.25, .25, .039)), {3: 1})
        self.assert_weights(skin.sample((.5, -.05, 0)), {0: .5, 1: .5})

    def test_weights_are_continuous_across_adjacent_triangles(self):
        points = [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)]
        skin = SurfaceSkin(points, [(0, 1, 2), (0, 2, 3)],
                           [{0: 1}, {1: 1}, {1: 1}, {0: 1}])
        for x in (.05, .25, .5, .75, .95):
            before = skin.sample((x, x - .000001, .02))
            after = skin.sample((x, x + .000001, .02))
            self.assert_weights(before, {0: 1 - x, 1: x})
            self.assert_weights(before, after)

    def test_original_pet_triangles_reproduce_their_skin_field(self):
        for species in ('penguin', 'bear', 'pig', 'chick'):
            data = json.loads((ROOT / 'design/blender/fitting' / (species + '.json')).read_text())
            surface = pet_surface(data)
            for face in surface.triangles[::max(1, len(surface.triangles) // 40)]:
                point = sum((surface.points[i] for i in face), surface.points[face[0]] * 0) / 3
                mapping = {}
                for vertex in face:
                    for bone, value in surface.weights[vertex].items():
                        mapping[bone] = mapping.get(bone, 0) + value / 3
                expected = dict(normalized_weights(mapping, surface.fallback))
                with self.subTest(species=species, face=face):
                    self.assert_weights(surface.sample(point), expected, .001)

    def test_decoration_uses_its_fabric_surface_and_reexport_is_idempotent(self):
        # An unrelated skin layer sits near an embroidered patch. Direct pet
        # sampling would bind the embroidery to that layer; two-stage transfer
        # binds it to the panel onto which it was actually sewn.
        positions = [[(0, 0, 0), (1, 0, 0), (0, 1, 0)],
                     [(.25, .25, .1), (.4, .25, .1), (.25, .4, .1)]]
        binary = bytearray()
        views, accessors, meshes = [], [], []
        for name, points in zip(('Patrón envolvente', 'Corazón bordado'), positions):
            offset = len(binary)
            binary.extend(struct.pack('<' + 'f' * 9, *(v for p in points for v in p)))
            views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': 36})
            accessors.append({'bufferView': len(views) - 1, 'componentType': 5126,
                              'count': 3, 'type': 'VEC3'})
            meshes.append({'name': name, 'primitives': [{'attributes': {'POSITION': len(accessors) - 1}}]})
        doc = {'asset': {'version': '2.0'}, 'buffers': [{'byteLength': len(binary)}],
               'bufferViews': views, 'accessors': accessors, 'meshes': meshes}
        chunk = json.dumps(doc).encode()
        chunk += b' ' * (-len(chunk) % 4)
        blob = (struct.pack('<III', 0x46546c67, 2, 28 + len(chunk) + len(binary))
                + struct.pack('<II', len(chunk), 0x4e4f534a) + chunk
                + struct.pack('<II', len(binary), 0x004e4942) + binary)
        data = {'boneNames': ['Spine2', 'Spine1', 'Arm'], 'meshes': [{
            'name': 'skin', 'positions': [v for p in positions[0] + [(0, 0, .12), (1, 0, .12), (0, 1, .12)] for v in p],
            'indices': [0, 1, 2, 3, 4, 5],
            'skinIndex': [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0] + [2, 0, 0, 0] * 3,
            'skinWeight': [1, 0, 0, 0] * 6}]}
        class MemoryGLB:
            def read_bytes(self):
                return self.blob

            def write_bytes(self, data):
                self.blob = data

        path = MemoryGLB()
        path.write_bytes(blob)
        add_skin_attributes(path, data)
        first = path.read_bytes()
        add_skin_attributes(path, data)
        self.assertEqual(first, path.read_bytes())
        length = struct.unpack_from('<I', first, 12)[0]
        doc = json.loads(first[20:20 + length])
        binary = first[28 + length:]
        attrs = doc['meshes'][1]['primitives'][0]['attributes']
        joint_view = doc['bufferViews'][doc['accessors'][attrs['JOINTS_0']]['bufferView']]
        weight_view = doc['bufferViews'][doc['accessors'][attrs['WEIGHTS_0']]['bufferView']]
        joints = struct.unpack_from('<HHHH', binary, joint_view['byteOffset'])
        weights = struct.unpack_from('<ffff', binary, weight_view['byteOffset'])
        self.assert_weights({bone: weight for bone, weight in zip(joints, weights) if weight > 0}, {0: .5, 1: .5})
        self.assertEqual(doc['meshes'][1]['extras']['nidoSkinTransfer']['source'], 'garment_surface')

    def test_pocket_and_frill_decorations_follow_their_secondary_fabric(self):
        # This secondary panel is sloped away from the primary torso. Its
        # decoration must use the panel's projected point, not the torso's XY
        # point or the unrelated pet surface lying behind the panel.
        positions = [[(0, 0, 0), (1, 0, 0), (0, 1, 0)],
                     [(.2, .2, .1), (.6, .2, .1), (.2, .6, .2)],
                     [(.3, .3, .2), (.32, .3, .2), (.3, .32, .2)]]
        data = {'boneNames': ['Spine2', 'Spine1', 'Arm'], 'meshes': [{
            'name': 'skin', 'positions': [v for p in positions[0] + [(0, 0, .12), (1, 0, .12), (0, 1, .12)] for v in p],
            'indices': [0, 1, 2, 3, 4, 5],
            'skinIndex': [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0] + [2, 0, 0, 0] * 3,
            'skinWeight': [1, 0, 0, 0] * 6}]}
        for secondary_name in ('Panel · Bolsillo', 'Volante pétalo · 0'):
            binary = bytearray()
            views, accessors, meshes = [], [], []
            for name, points in zip(('Patrón envolvente', secondary_name, 'Flor bordada'), positions):
                offset = len(binary)
                binary.extend(struct.pack('<' + 'f' * 9, *(v for p in points for v in p)))
                views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': 36})
                accessors.append({'bufferView': len(views) - 1, 'componentType': 5126,
                                  'count': 3, 'type': 'VEC3'})
                meshes.append({'name': name, 'primitives': [{'attributes': {'POSITION': len(accessors) - 1}}]})
            doc = {'asset': {'version': '2.0'}, 'buffers': [{'byteLength': len(binary)}],
                   'bufferViews': views, 'accessors': accessors, 'meshes': meshes}
            chunk = json.dumps(doc).encode()
            chunk += b' ' * (-len(chunk) % 4)
            blob = (struct.pack('<III', 0x46546c67, 2, 28 + len(chunk) + len(binary))
                    + struct.pack('<II', len(chunk), 0x4e4f534a) + chunk
                    + struct.pack('<II', len(binary), 0x004e4942) + binary)

            class MemoryGLB:
                def read_bytes(self):
                    return self.blob

                def write_bytes(self, value):
                    self.blob = value

            path = MemoryGLB()
            path.write_bytes(blob)
            add_skin_attributes(path, data)
            first = path.read_bytes()
            add_skin_attributes(path, data)
            self.assertEqual(first, path.read_bytes())
            length = struct.unpack_from('<I', first, 12)[0]
            doc = json.loads(first[20:20 + length])
            binary = first[28 + length:]

            def first_weights(index):
                attrs = doc['meshes'][index]['primitives'][0]['attributes']
                joint_view = doc['bufferViews'][doc['accessors'][attrs['JOINTS_0']]['bufferView']]
                weight_view = doc['bufferViews'][doc['accessors'][attrs['WEIGHTS_0']]['bufferView']]
                joints = struct.unpack_from('<HHHH', binary, joint_view['byteOffset'])
                weights = struct.unpack_from('<ffff', binary, weight_view['byteOffset'])
                return {bone: weight for bone, weight in zip(joints, weights) if weight > 0}

            with self.subTest(secondary=secondary_name):
                self.assert_weights(first_weights(1), {0: .6, 1: .4})
                # Plane z=.05+.25*y: perpendicular projection increases y by
                # (.2-.125)*.25/(1+.25**2), so its interpolated skin field x+y
                # is .617647... . Projecting directly to the torso yields .6.
                influence = .6 + .075 * .25 / (1 + .25 ** 2)
                self.assert_weights(first_weights(2), {0: 1 - influence, 1: influence})
                self.assertEqual(doc['meshes'][1]['extras']['nidoSkinTransfer']['stage'], 'secondary')
                self.assertEqual(doc['meshes'][2]['extras']['nidoSkinTransfer']['stage'], 'decoration')


if __name__ == '__main__':
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(SurfaceTransferTest))
    if not result.wasSuccessful():
        raise RuntimeError('Wardrobe surface transfer checks failed')
