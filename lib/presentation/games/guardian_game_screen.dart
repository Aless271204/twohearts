import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/forest_runner_view.dart';
import '../../widgets/immersive_game.dart';
import '../../services/audio_service.dart';
import '../../services/shared_pet_service.dart';

class GuardianGameScreen extends StatefulWidget {
  final bool penalties, maze;
  const GuardianGameScreen({
    super.key,
    this.penalties = false,
    this.maze = false,
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
      body: ForestRunnerView(
        guardian: !widget.penalties && !widget.maze,
        maze: widget.maze,
        penalties: widget.penalties,
        petSpecies: SharedPetService.instance.species,
        onExit: () => Navigator.maybePop(context),
      ),
    ),
  );
}
