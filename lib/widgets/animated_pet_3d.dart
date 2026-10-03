import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Reusable viewer for TwoHearts animated GLB pets.
///
/// Pet assets live directly under assets/ so we do not need to add another
/// asset directory to pubspec.yaml. Meshy animation names can be passed to
/// [animationName] as they appear inside the GLB.
class AnimatedPet3D extends StatelessWidget {
  final String assetPath;
  final String? animationName;
  final bool autoPlay;
  final bool cameraControls;
  final String cameraOrbit;
  final String fieldOfView;
  final Color backgroundColor;

  const AnimatedPet3D({
    super.key,
    this.assetPath = 'assets/pebble_penguin.glb',
    this.animationName,
    this.autoPlay = true,
    this.cameraControls = false,
    this.cameraOrbit = '0deg 80deg 2.6m',
    this.fieldOfView = '28deg',
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: assetPath,
      alt: 'Mascota 3D de TwoHearts',
      autoPlay: autoPlay,
      animationName: animationName,
      cameraControls: cameraControls,
      disableZoom: !cameraControls,
      backgroundColor: backgroundColor,
      cameraOrbit: cameraOrbit,
      fieldOfView: fieldOfView,
      interactionPrompt: InteractionPrompt.none,
      loading: Loading.eager,
      ar: false,
    );
  }
}
