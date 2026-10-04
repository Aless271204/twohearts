import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class AnimatedPet3D extends StatelessWidget {
  final String? animationName;

  const AnimatedPet3D({super.key, this.animationName});

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: 'assets/images/Meshy_AI_Pebble_the_Penguin_All_Animations.glb',
      alt: 'Pebble, mascota 3D de TwoHearts',
      autoPlay: true,
      animationName: animationName,
      cameraControls: false,
      disableZoom: true,
      backgroundColor: Colors.transparent,
      cameraOrbit: '0deg 80deg 2.6m',
      fieldOfView: '28deg',
      interactionPrompt: InteractionPrompt.none,
      loading: Loading.eager,
      ar: false,
    );
  }
}
