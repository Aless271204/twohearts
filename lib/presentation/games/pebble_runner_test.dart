import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/pet_model_catalog.dart';
import '../../services/supabase_service.dart';
import '../../widgets/pet_3d_viewer.dart';

class PebbleRunnerTest extends StatefulWidget {
  final String? modelPath;

  const PebbleRunnerTest({super.key, this.modelPath});

  @override
  State<PebbleRunnerTest> createState() => _PebbleRunnerTestState();
}

class _PebbleRunnerTestState extends State<PebbleRunnerTest> {
  double _height = 0;
  double _velocity = 0;
  double _obstacleX = 300;
  bool _running = false;
  bool _gameOver = false;
  int _score = 0;
  String _petModelPath = PetModelCatalog.defaultModelPath;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.modelPath != null) {
      _petModelPath = widget.modelPath!;
    } else {
      _loadSelectedPet();
    }
  }

  Future<void> _loadSelectedPet() async {
    final profile = await SupabaseService.instance.getMyProfile();
    final petType = profile?['pet_type'];
    final modelPath = PetModelCatalog.modelPathFor(
      petType is String ? petType : null,
    );
    if (mounted) setState(() => _petModelPath = modelPath);
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _gameOver = false;
      _height = 0;
      _velocity = 0;
      _score = 0;
      _obstacleX = MediaQuery.sizeOf(context).width - 66;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted || !_running) return;
      setState(() {
        _score++;
        _velocity -= 1.15;
        _height += _velocity;
        _obstacleX -= 4;
        if (_height <= 0) {
          _height = 0;
          _velocity = 0;
        }
        if (_obstacleX < -38) {
          _obstacleX = MediaQuery.sizeOf(context).width + 100;
        }

        final overlapsPlayer =
            _obstacleX <= 36 + 150 && _obstacleX + 38 >= 36;
        if (overlapsPlayer && _height < 55) {
          _running = false;
          _gameOver = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _jump() {
    if (!_running) {
      _start();
      return;
    }
    if (_height == 0) setState(() => _velocity = 16);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      appBar: AppBar(
        title: const Text('Pebble Runner · Prueba 3D'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _jump,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE5EE), Color(0xFFF4FFF8)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              child: Text(
                'Puntos: $_score',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 70,
              child: Container(height: 4, color: const Color(0xFFEB5B7C)),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 30),
              curve: Curves.linear,
              left: 36,
              bottom: 74 + _height,
              width: 150,
              height: 190,
              child: Pet3DViewer(
                modelPath: _petModelPath,
                altText: 'Mascota 3D de Pebble Runner',
                cameraControls: false,
                disableZoom: true,
                autoRotate: false,
                cameraOrbit: '90deg 75deg 105%',
                autoPlay: true,
                animationName: 'Jump_Run',
              ),
            ),
            Positioned(
              left: _obstacleX,
              bottom: 74,
              child: Container(
                width: 38,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4F3A),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (!_running)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_gameOver) ...[
                      Text(
                        '¡Fin del juego! Puntos: $_score',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _start,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          _gameOver ? 'REINTENTAR' : 'JUGAR CON PEBBLE',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Text(
                'Toca la pantalla para saltar',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
