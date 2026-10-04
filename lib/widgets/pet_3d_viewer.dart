import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Pet3DViewer extends StatelessWidget {
  final String modelPath;
  final String altText;
  final bool cameraControls;
  final bool disableZoom;
  final bool autoRotate;
  final bool autoPlay;
  final String? animationName;

  const Pet3DViewer({
    super.key,
    required this.modelPath,
    this.altText = 'Mascota 3D de TwoHearts',
    this.cameraControls = true,
    this.disableZoom = false,
    this.autoRotate = false,
    this.autoPlay = false,
    this.animationName,
  });

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      key: ValueKey(modelPath),
      src: modelPath,
      alt: altText,
      autoPlay: autoPlay,
      animationName: animationName,
      cameraControls: cameraControls,
      disableZoom: disableZoom,
      autoRotate: autoRotate,
      backgroundColor: Colors.transparent,
      interactionPrompt: InteractionPrompt.none,
      loading: Loading.eager,
      ar: false,
    );
  }
}
