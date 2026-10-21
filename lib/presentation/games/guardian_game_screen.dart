import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/forest_runner_view.dart';
import '../../widgets/immersive_game.dart';
import '../../services/audio_service.dart';
import '../../services/shared_pet_service.dart';
import '../../services/inventory_service.dart';
import 'dart:convert';

class GuardianGameScreen extends StatefulWidget {
  final bool penalties, maze, snow;
  const GuardianGameScreen({
    super.key,
    this.penalties = false,
    this.maze = false,
    this.snow = false,
  });
  @override
  State<GuardianGameScreen> createState() => _GuardianGameScreenState();
}

class _GuardianGameScreenState extends State<GuardianGameScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.pause();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ImmersiveGame(
    child: Scaffold(
      backgroundColor: const Color(0xFF173B39),
      body: ListenableBuilder(
        listenable: InventoryService.instance,
        builder: (context, _) => ForestRunnerView(
          guardian: !widget.penalties && !widget.maze && !widget.snow,
          snow: widget.snow,
          maze: widget.maze,
          penalties: widget.penalties,
          petSpecies: SharedPetService.instance.species,
          appearance: jsonEncode({
            for (final entry in InventoryService.instance.loadout.entries)
              entry.key: {
                ...entry.value.appearance,
                'item_key': entry.value.key,
              },
          }),
          onExit: () => Navigator.maybePop(context),
        ),
      ),
    ),
  );
}
