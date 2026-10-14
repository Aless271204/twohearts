import 'package:flutter/material.dart';
import 'pet_room_screen.dart';

/// Keeps the existing Mascota tab and route while using the immersive room.
class HomeScreen extends StatelessWidget {
  final bool previewMode;
  const HomeScreen({super.key, this.previewMode = false});
  @override
  Widget build(BuildContext context) =>
      PetRoomScreen(previewMode: previewMode, embedded: true);
}
