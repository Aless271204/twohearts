# Complete, persistent store previews

The carousel previously mounted a live 3D scene only on the selected page and used a single product thumbnail on neighboring pages. Swiping destroyed that scene; returning rebuilt it. This explained both the incomplete neighboring previews and repeated loading.

Every current bundle now has a bundled WebP showroom image: eight complete rooms and three complete outfits. All eleven images together weigh approximately 210 KB. Each page owns its own image, uses contain fitting to avoid cropping furniture, and retains the same image when returning. The explicit “Explorar en 3D” / “Probar conjunto” button opens the real interactive scene without changing the saved equipment or room.

These are offline Blender renders of the actual exported furniture GLBs and the posed original pets with actual app equipment. They are not screenshots from the running app, and do not imply that every existing garment has passed visual fit review. Approved boutique illustrations were preserved.

Evidence: `design/store-showcases/room_set_*.json` records room source hashes and render settings; `outputs/store-showcase-contact.png` is the visual review sheet. Flutter layout checks traverse all eight room pages and return to the first page, asserting that no 3D preview is automatically mounted and no image/layout errors occur. The existing category layout and room-layout checks also pass.

## Beret candidate, separate from activation

The active large/open beret was compared with the approved lavender felt boutique reference. Candidate v8 replaces the open crown with a small closed crown based on each original skull profile, with 6 mm lining, a short stem and heart detail. It eliminates the v7 surface-raycast transition that produced tuft spikes. Original pet files and animation clips are unchanged.

First offline penguin views at 0, 90 and 180 degrees and the full pig Chic outfit were inspected. Native Android capture was requested for all four original pets, front/profile/back, running and jumping. Candidate files remain experimental until those actual-renderer images are inspected. No APK is published by this check.

## Folded beret v9, validated and applied

The user rejected the smooth v8 crown and asked for felt relief and waves while keeping a footprint smaller than the head. V9 has an asymmetric slouching crown, gathered edge and soft folds. The reviewed set contains 20 actual Android-host frames: all four original pets, front/profile/back, a running sample and a jumping sample. See `design/wardrobe-restart/experiments/beret-fit-v9/native-validation.json` for frame hashes and the three final source runs. Loading-screen captures were retained separately and excluded from acceptance.

A frozen inspection could stop drawing before its canvas fade became visible on Android. The inspection now renders twelve frames before freezing; the phase stays fixed and playable animations are unchanged. This resolved the final penguin running capture in run39634660827.

The existing four beret asset paths are retained for compatibility with older clients; their contents, per-species hashes and cache revision are updated together. Old accessory sources are archived under the v9 `sources` directory for material/heart provenance. Four editable Blender masters and the fitting generator are retained. All original pet GLBs match the previous delivery byte for byte. Prices, item identity and ownership are preserved. The Chic showroom image now shows the same folded beret.

Validation is limited to the reviewed poses and geometric motion samples; it is not a certification of every garment or every animation frame.
