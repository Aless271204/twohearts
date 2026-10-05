import 'package:flutter/material.dart';
import '../core/pet_model_catalog.dart';

import './pet_3d_viewer.dart';

class AnimatedPet3D extends StatelessWidget {
  final String? animationName;

  const AnimatedPet3D({super.key, this.animationName});

  @override
  Widget build(BuildContext context) {
    return Pet3DViewer(
      modelPath: PetModelCatalog.penguinModelPath,
      altText: 'Pip, mascota 3D de TwoHearts',
      autoPlay: true,
      animationName: animationName,
      cameraControls: false,
      disableZoom: true,
      autoRotate: false,
      cameraOrbit: '0deg 75deg 105%',
    );
  }
}
