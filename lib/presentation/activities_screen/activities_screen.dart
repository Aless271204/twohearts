import 'package:flutter/material.dart';

import '../../widgets/twohearts_ui.dart';
import '../games/game_hub_screen.dart';

/// Keeps existing links working while the activities section is redesigned.
class ActivitiesScreen extends StatelessWidget {
  final bool previewMode;
  const ActivitiesScreen({super.key, this.previewMode = false});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const HeartHeader(title: 'Juguemos juntos'),
          Expanded(child: GameHubScreen(previewMode: previewMode)),
        ],
      ),
    ),
  );
}
