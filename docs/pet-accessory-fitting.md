# Accessories and room motion

The 25 accessory concepts are procedural meshes in `accessory-pieces.js`. Their store images are renders of those same meshes, saved under `assets/images/products/`.

`cosmetics.js` measures each actual pet mesh in its resting pose, then attaches head, eye, neck, torso and foot equipment to the corresponding bones while preserving transforms. Species adjustments account for ears, crests, facial proportions and feet. Growth scales the pet and equipment together. The same renderer serves the runner, room and inventory preview.

`pet-motion.js` adds subtle torso breathing and a short affectionate head/wing response after the animation mixer. Root position and foot joints remain fixed. Touches notify the Flutter room; care writes are throttled while visual reactions remain available. Motion pauses when the scene is suspended.

New unpublished concepts are try-on previews only. Existing published identities, ownership and prices take precedence. No database catalog or pricing migration has been applied, and no APK was generated.

Validation: five Node tests cover geometry, disposal, all four real rigs, running animation, growth and grounded care motion. Ten Flutter tests cover catalogue merging and existing responsive UI. The release web preview compiled, and a room touch produced an affection response with grounded feet. Visual review is available at `/assets/runner/accessory-review.html` when serving the repository root.

Room penguin regression: fitting now includes its replacement torso and feet, so removing original limb triangles cannot raise the measured floor or neck. Penguin collars use a lower, narrower attachment. A dedicated refined-model test checks collar height and shoe coverage.
