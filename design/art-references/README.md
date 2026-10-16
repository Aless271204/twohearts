# Referencias de Pincel en pareja

Los originales PNG de las dos ilustraciones se conservan aquí. Las copias WebP
de 512 × 512 utilizadas por la app están en `assets/images/art_references/`.
Catálogo de lugares y transformaciones: `lib/core/art_reference_catalog.dart`.
Los identificadores no limitan los destinos personales: pueden elegir sus fotos,
viajes y cualquier imagen de inspiración para un viaje futuro.

## Procedencia
Las ocho fotografías se obtuvieron de Unsplash. Las URLs individuales y la
licencia están en `travel-sources.json`; licencia: https://unsplash.com/license.
Son referencias para dibujar, no productos fotográficos revendidos.
Se revisó visualmente que corresponden a sus destinos. Preparación reproducible:
`scripts/prepare-art-travel-photos.py`. Suma de las doce imagenes empaquetadas: 1117078 bytes.

Las ilustraciones se generaron con la herramienta integrada ImageGen, usando
los cuatro retratos de NIDO como referencias de identidad. No son renders de los
modelos del juego. No se usan fotos privadas de clientes en esas generaciones.

## Prompts utilizados

### paris-mascots.png
Create ONE polished square illustration as an actual drawing-game reference for NIDO. Four adorable existing mascots visiting Paris together, sitting at a charming picnic beside the Seine, Eiffel Tower recognizable in the background, spring blossoms, small croissant basket, one little sketchbook. Use the four provided images ONLY as character identity references: penguin black/white huge warm eyes orange beak, brown teddy bear cream muzzle, pink pig floppy ears and snout, yellow chick orange beak. Preserve their sweet facial proportions, give natural adorable poses interacting with picnic and drawing. Cute high-quality soft 3D animated film still, tactile woven outfits in cream/coral/sage/lavender, detailed but readable silhouettes and clean composition, soft warm afternoon light, pastel pink sky, realistic cute materials, small delicate shadows. Subjects fill lower two thirds, landmark visible above. No text, no labels, no collage, no panels, no logos, no watermarks. This is a finished single scene, not a UI or contact sheet.

### guardian-mascots.png
Create ONE beautiful square actual pixel art illustration for a cozy mascot drawing challenge in the NIDO mobile game. Four adorable chibi mascots from reference images: black-and-white penguin, brown bear, pink pig, yellow chick. They cooperate in a magical forest adventure minigame: penguin jumping gracefully onto a mossy log, bear holding a glowing little heart shield, pig collecting a golden coin, chick casting a small lavender sparkle. A mischievous cute moss turtle boss peeks behind ferns far in the background, playful not scary. A tranquil waterfall, tiny flowers, warm sunbeams through canopy. Crisp genuinely hand-placed pixel art 16-bit game aesthetic, visible square pixels, consistent limited coral sage cream gold lavender palette, excellent readable silhouettes, soft charming faces, no photoreal texture, no blurry scaling, no text, no logos, no UI, no collage, no panels. Rich but clear composition suitable to copy by drawing. The four source images are identity references only, translate their facial charm to pixel art.

## Dificultad aprobada
Paris dispone de tres ilustraciones distintas y nitidas: easy con un pinguino,
medium con pinguino y cerdito, y original con las cuatro mascotas y escenario completo.
La imagen mas sencilla reduce objetos, no calidad. En fotos personales el encuadre
se amplia en facil, se abre en medio y se muestra completo en dificil; las tres
conservan 512 px y colores originales. El pixel art usa bloques nitidos y el
boceto contornos. Ambos participantes reciben exactamente la misma referencia.

### paris-mascots-easy.png (ImageGen integrado)
Create a NEW single square reference illustration for the EASY level of NIDO's drawing game. Use the attached scene ONLY for character identity, palette, warm lighting and beautiful 3D animated-film style. Show ONLY the adorable black-and-white penguin, full body seated, holding one simple croissant with both little flippers. Cream knitted shirt with one coral heart and lavender beret. Very large readable clean shapes and tender face. Background is a spacious plain pale pink sky with one SMALL SIMPLE Eiffel Tower silhouette far away and a flat cream ground with just two tiny flowers. No other characters, no picnic basket, no buildings, no busy textures, no fine filigree. Absolutely crisp and beautifully rendered, charming smooth fabric texture and soft shadows, retain high quality. Reduce the NUMBER of things to draw, never blur or pixelate. No text, no labels, no UI, no collage.

### paris-mascots-medium.png (ImageGen integrado)
Create a NEW single square reference illustration for the MEDIUM level of NIDO's drawing game. Use the attached scene as identity/style reference, same cute 3D animation quality, warm pastel coral cream sage lavender colors. Show ONLY TWO adorable mascots: black-and-white penguin and pink floppy-ear pig, sitting together on a simple cream picnic blanket beside the Seine, sharing an open sketchbook. Penguin wearing cream heart shirt/lavender beret, pig cream knitted top and lavender beret. Include one small croissant basket, a recognizable Eiffel Tower with moderate structural detail in the middle distance, one bridge, a few simple blossoms overhead, and gentle water reflections. Clean spacious composition with far FEWER props and flowers than the supplied scene. Crisp, high quality, adorable tactile fabric and readable forms. Not blurry, not posterized, not pixelated. No other mascots, no text, no collage, no UI.
