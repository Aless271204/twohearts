import 'package:flutter/material.dart';
import '../../widgets/forest_runner_view.dart';

class PebbleRunnerTest extends StatelessWidget {
  final String? modelPath;
  const PebbleRunnerTest({super.key, this.modelPath});
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
