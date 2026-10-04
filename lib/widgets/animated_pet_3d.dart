import 'package:flutter/material.dart';

import './pet_3d_viewer.dart';

class AnimatedPet3D extends StatelessWidget {
  final String? animationName;

  const AnimatedPet3D({super.key, this.animationName});

  @override
  Widget build(BuildContext context) {
    return Pet3DViewer(
      modelPath: 'assets/images/Meshy_AI_Pebble_the_Penguin_All_Animations.glb',
      altText: 'Pebble, mascota 3D de TwoHearts',
      autoPlay: true,
      animationName: animationName,
      cameraControls: false,
      disableZoom: true,
    );
  }
}
