"""Small, repeatable textile maps exported as ordinary glTF PBR textures.

Texture detail describes the cloth, never the garment's silhouette or fit. The
generator supplies continuous, locally oriented UVs at a consistent density.
"""
import math
import struct
import zlib
import numpy as np


# Keep the API used by the Blender pattern builder and its editable exports.
# A tile is repeated twice, rather than amplifying fine weave into a rigid grid.
FABRICS = {
    'cotton': {'roughness': .88, 'normal': .20, 'repeat': 2},
    'denim': {'roughness': .84, 'normal': .27, 'repeat': 2},
    'wool': {'roughness': .96, 'normal': .30, 'repeat': 2},
    'knit': {'roughness': .92, 'normal': .42, 'repeat': 2},
    'poplin': {'roughness': .76, 'normal': .15, 'repeat': 2},
    'straw': {'roughness': .88, 'normal': .34, 'repeat': 2},
    'felt': {'roughness': .97, 'normal': .22, 'repeat': 2},
}


def png(path, pixels):
    """Write lossless RGB PNGs without a dependency on a desktop image editor."""
    h, w, _ = pixels.shape
    raw = b''.join(b'\0' + row.tobytes() for row in pixels)

    def chunk(kind, data):
        return (struct.pack('>I', len(data)) + kind + data +
                struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff))

    path.write_bytes(
        b'\x89PNG\r\n\x1a\n' +
        chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) +
        chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    )


def _soft_noise(rng, size, radius):
    """Periodic, softly correlated fibres; wrapping has no hard tile border."""
    source = rng.standard_normal((size, size))
    frequencies = np.fft.fftfreq(size)
    fx, fy = np.meshgrid(frequencies, frequencies)
    blur = np.exp(-2 * math.pi ** 2 * radius ** 2 * (fx * fx + fy * fy))
    noise = np.fft.ifft2(np.fft.fft2(source) * blur).real
    return noise / max(noise.std(), 1e-8)


def textile_maps(color, fabric, size=256):
    """Return a subtle albedo and tangent-space normal, independently of bpy.

    Integer thread counts and periodic noise make the maps seamless. Large
    decorative seams, fleece borders and knit cuffs must remain actual geometry.
    """
    rng = np.random.default_rng(420)
    y, x = np.mgrid[0:size, 0:size] / size
    fine = _soft_noise(rng, size, .60)
    soft = _soft_noise(rng, size, 1.65)
    broad = _soft_noise(rng, size, 9.0)

    if fabric == 'knit':
        # Alternating V loops, with a recessed centre and softly raised yarn.
        # A cosine stripe alone reads as corrugated plastic at the hem.
        u, v = x * 16, y * 12
        local_u = (u + .5) % 1 - .5
        local_v = v % 1
        branch = np.abs(local_u) - (.10 + .32 * local_v)
        yarn = np.exp(-(branch / .105) ** 2)
        # Taper yarn at the boundary of each row so adjacent loops join without
        # a hard horizontal jump in the normal map.
        stitch = yarn * np.sin(math.pi * local_v) ** 2
        valley = np.exp(-(local_u / .055) ** 2) * .025
        height = .21 * stitch - valley + .007 * fine
        shade = .043 * (stitch - stitch.mean()) + .007 * soft
    elif fabric == 'denim':
        # Fine diagonal twill. The blue stays uniform at normal playing distance.
        twill = np.cos(math.tau * (24 * x + 24 * y))
        warp = np.cos(math.tau * x * 64)
        height = .074 * twill + .018 * warp + .006 * fine
        shade = .018 * twill + .008 * soft + .004 * broad
    elif fabric == 'straw':
        # Rounded interwoven ribbons, rather than sharp checkerboard dimples.
        warp = np.cos(math.tau * x * 20)
        weft = np.cos(math.tau * y * 16)
        over = .5 + .5 * np.sin(math.tau * (10 * x + 8 * y))
        height = .09 * (over * warp + (1 - over) * weft) + .006 * fine
        shade = .025 * (warp + weft) + .008 * soft
    elif fabric == 'wool':
        # Correlated tiny fleecy clumps avoid the old sand/static appearance.
        height = .032 * soft + .010 * fine
        shade = .014 * soft + .007 * broad
    elif fabric == 'felt':
        height = .021 * soft + .009 * fine
        shade = .010 * soft + .006 * broad
    else:
        # Cotton jersey and smoother poplin have close, low contrast threads.
        thread_count = 48 if fabric == 'cotton' else 56
        warp = np.cos(math.tau * x * thread_count)
        weft = np.cos(math.tau * y * thread_count)
        weave = .6 * warp + .4 * weft
        height = .028 * weave + .005 * fine
        shade = .010 * weave + .006 * soft + .004 * broad

    # The PNG row axis points down; glTF tangent V points up. Reverse that
    # derivative for a conventional +Y normal map (Blender/glTF/OpenGL).
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 3
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 3
    normals = np.stack([-dx, dy, np.ones_like(height)], axis=-1)
    normals /= np.linalg.norm(normals, axis=-1, keepdims=True)
    normal_pixels = np.clip((normals * .5 + .5) * 255, 0, 255).astype(np.uint8)

    rgb = np.array([int(color[i:i + 2], 16) for i in (1, 3, 5)])
    # Prevent bright white material from burning out and keep the pastel palette
    # faithful. Cloth variation is a few percent, with no painted black creases.
    factor = np.clip(1 + shade, .94, 1.04)
    albedo_pixels = np.clip(factor[..., None] * rgb, 0, 255).astype(np.uint8)
    return albedo_pixels, normal_pixels


def make_material(color, fabric, directory):
    import bpy

    preset = FABRICS[fabric]
    directory.mkdir(parents=True, exist_ok=True)
    albedo, normals = textile_maps(color, fabric)
    normal_file = directory / ('fabric_' + fabric + '_normal.png')
    albedo_file = directory / ('fabric_' + fabric + '_' + color[1:].lower() + '.png')
    png(normal_file, normals)
    png(albedo_file, albedo)

    material = bpy.data.materials.new(fabric + ' · ' + color)
    material.use_nodes = True
    nodes, links = material.node_tree.nodes, material.node_tree.links
    shader = nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value = preset['roughness']
    shader.inputs['Sheen Weight'].default_value = .18
    shader.inputs['Sheen Roughness'].default_value = .75
    shader.inputs['Metallic'].default_value = 0
    shader.inputs['Specular IOR Level'].default_value = .25
    uv = nodes.new('ShaderNodeTexCoord')
    mapping = nodes.new('ShaderNodeMapping')
    mapping.inputs['Scale'].default_value = (preset['repeat'], preset['repeat'], 1)
    links.new(uv.outputs['UV'], mapping.inputs['Vector'])
    for path, target in [(albedo_file, 'Base Color'), (normal_file, 'Normal')]:
        texture = nodes.new('ShaderNodeTexImage')
        texture.image = bpy.data.images.load(str(path), check_existing=True)
        texture.extension = 'REPEAT'
        texture.interpolation = 'Linear'
        links.new(mapping.outputs['Vector'], texture.inputs['Vector'])
        if target == 'Normal':
            texture.image.colorspace_settings.name = 'Non-Color'
            normal = nodes.new('ShaderNodeNormalMap')
            normal.inputs['Strength'].default_value = preset['normal']
            links.new(texture.outputs['Color'], normal.inputs['Color'])
            links.new(normal.outputs['Normal'], shader.inputs['Normal'])
        else:
            links.new(texture.outputs['Color'], shader.inputs[target])
    material['fabric'] = fabric
    material['textile_density_note'] = 'Local continuous UVs; no silhouette baked into texture'
    return material
