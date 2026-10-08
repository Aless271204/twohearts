import 'package:flutter/material.dart';
import '../../widgets/forest_runner_view.dart';
import '../../services/audio_service.dart';

class PebbleRunnerTest extends StatefulWidget {
  final String? modelPath;
  const PebbleRunnerTest({super.key, this.modelPath});
  @override
  State<PebbleRunnerTest> createState() => _PebbleRunnerTestState();
}
class _PebbleRunnerTestState extends State<PebbleRunnerTest> {
  @override
  void initState(){super.initState();AudioService.instance.pause();}
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF17392B),
    appBar: AppBar(
      title: const Text('Corre en pareja · Bosque'),
      backgroundColor: const Color(0xFF17392B),
      foregroundColor: Colors.white,
    ),
    body: const ForestRunnerView(),
  );
}
