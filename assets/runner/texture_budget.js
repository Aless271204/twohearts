// Keep original GLBs/animations; limit only uploaded runtime texture resolution.
export function limitTextureMemory(root, maximum = 512) {
  const textures = new Set(), originals = new Set();
  root.traverse(object => {
    for (const material of Array.isArray(object.material) ? object.material : [object.material]) {
      if (!material) continue;
      for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
    }
  });
  for (const texture of textures) {
    const image = texture.image;
    if (!image || Math.max(image.width, image.height) <= maximum) continue;
    const scale = maximum / Math.max(image.width, image.height);
    const canvas = document.createElement('canvas');
    canvas.width = Math.max(1, Math.round(image.width * scale));
    canvas.height = Math.max(1, Math.round(image.height * scale));
    const context = canvas.getContext('2d');
    if (!context) throw Error('No se pudo preparar una textura del bosque');
    context.drawImage(image, 0, 0, canvas.width, canvas.height);
    originals.add(image);texture.image = canvas;texture.needsUpdate = true;
  }
  for (const image of originals) image.close?.();
}
