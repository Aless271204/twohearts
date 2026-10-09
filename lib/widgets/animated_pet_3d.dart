import 'package:flutter/material.dart';
import '../core/pet_model_catalog.dart';
import '../services/shared_pet_service.dart';

import './pet_3d_viewer.dart';

class AnimatedPet3D extends StatelessWidget {
  final String? animationName;

  const AnimatedPet3D({super.key, this.animationName});

  @override
  Widget build(BuildContext context) {
    return Pet3DViewer(
      modelPath: PetModelCatalog.modelPathFor(SharedPetService.instance.species),
      petLevel: SharedPetService.instance.level,
      altText: 'Mascota 3D compartida',
      autoPlay: true,
      animationName: animationName,
      cameraControls: false,
      disableZoom: true,
      autoRotate: false,
      cameraOrbit: '0deg 75deg 105%',
    );
  }
}
