import 'package:flutter/material.dart';
import '../../widgets/forest_runner_view.dart';
import '../../services/audio_service.dart';
import '../../services/shared_pet_service.dart';
import '../../widgets/scene_status.dart';

class PebbleRunnerTest extends StatefulWidget {
  final String? modelPath;
  const PebbleRunnerTest({super.key, this.modelPath});
  @override
  State<PebbleRunnerTest> createState() => _PebbleRunnerTestState();
}
class _PebbleRunnerTestState extends State<PebbleRunnerTest> {
  late final Future<void> _petReady;
  @override
  void initState(){super.initState();AudioService.instance.pause();_petReady=SharedPetService.instance.refresh();}
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF17392B),
    appBar: AppBar(
      title: const Text('Corre en pareja · Bosque'),
      backgroundColor: const Color(0xFF17392B),
      foregroundColor: Colors.white,
    ),
    body: FutureBuilder<void>(future: _petReady, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const SceneStatus(title: 'Nos vamos al bosque', message: 'Cargando vuestra mascota y sus accesorios…');
      if (snapshot.hasError) return SceneStatus(title: 'No pudimos conectar', message: 'Comprueba la conexión y vuelve a entrar.', loading: false, onRetry: () => Navigator.pop(context));
      return ForestRunnerView(petSpecies: SharedPetService.instance.species,petLevel: SharedPetService.instance.level);
    }),
  );
}
