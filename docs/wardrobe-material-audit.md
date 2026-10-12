# Wardrobe material audit

Reference inspected: `design/penguin-outfits-approved.png`. Its convincing fabric
comes from rounded collars and cuffs, soft seams, a complete garment silhouette,
fine fibre detail and diffuse illumination. The image also contains accessories
outside this build. A material map cannot make a different silhouette identical.

## Corrections in the portable PBR materials

- Cotton and poplin: finer, low contrast warp/weft, with restrained micro normals.
- Denim: diagonal twill, subtle dye variation and diffuse highlights.
- Knit: actual V-shaped stitches with smooth row transitions, rather than simple
  corrugated stripes.
- Wool and felt: periodic correlated fibres instead of static-looking noise.
- Straw: softly interwoven ribbons rather than deeply dimpled checkerboards.
- All fabrics: non-metallic, roughness 0.76–0.97, normal maps in +Y convention,
  pastel-preserving albedo, two repetitions and small 256px lossless RGB textures.
  Cloth remains readable at playing distance without painting dark fake creases.

`make_material(color, fabric, directory)` and material naming remain compatible.
Blender uses sheen and a reduced specular response; core glTF base colour,
roughness and tangent-space normal maps remain sufficient for the mobile viewer.
The renderer must not rely on optional sheen to achieve the reference.

## UV and geometry requirements

The previous generic UV used `atan2(x,z)` about the whole character's origin and
world `y` for every mesh. This is unsuitable for offset sleeves and decorative
details. It also lets a face interpolate across U=0/1, stretching an entire tile
over one triangle. Fixing maps alone cannot repair these lines.

Use locally centred, continuous UVs for each surface. Split/unwrap the rear torso
seam and each sleeve seam, with UV loops on either side using U near 0 and U near
1 consistently. Orient the V direction along the garment. Keep equal texel
density on torso and sleeves; a useful starting point is one base U tile around
the body and a V span based on garment height divided by its circumference.
The material already applies the configured repetition, so avoid applying it a
second time in mesh UVs. Small seams and borders can use local planar UVs.

Smooth sleeve/body junctions and actual rim thickness take priority over stronger
normals. Fluffy silhouette requires a rounded fleece border or cuff geometry;
normal maps affect surface light and cannot add fibre volume at the outer edge.

## Checks performed

All seven generated maps are deterministic, finite, 256×256 RGB and keep tangent
normals facing out. Per-channel albedo standard deviation is approximately
0.9–2.6% of the mean. Texture-only contact sheet was inspected locally. These
checks do not approve garment fit or the final rendered result; each exported
piece still needs inspection on all four textured pets, with movement.
