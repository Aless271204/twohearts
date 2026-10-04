import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/animated_pet_3d.dart';

class PebbleRunnerTest extends StatefulWidget {
  const PebbleRunnerTest({super.key});

  @override
  State<PebbleRunnerTest> createState() => _PebbleRunnerTestState();
}

class _PebbleRunnerTestState extends State<PebbleRunnerTest> {
  double _height = 0;
  double _velocity = 0;
  bool _running = false;
  int _score = 0;
  Timer? _timer;

  void _start() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _height = 0;
      _velocity = 0;
      _score = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted || !_running) return;
      setState(() {
        _score++;
        _velocity -= 1.15;
        _height += _velocity;
        if (_height <= 0) {
          _height = 0;
          _velocity = 0;
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
            Positioned(top: 24, left: 24, child: Text('Puntos: $_score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            Positioned(left: 0, right: 0, bottom: 70, child: Container(height: 4, color: const Color(0xFFEB5B7C))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 30),
              curve: Curves.linear,
              left: 36,
              bottom: 74 + _height,
              width: 150,
              height: 190,
              child: const AnimatedPet3D(animationName: 'Running'),
            ),
            Positioned(
              right: 28,
              bottom: 74,
              child: Container(width: 38, height: 55, decoration: BoxDecoration(color: const Color(0xFF6B4F3A), borderRadius: BorderRadius.circular(8))),
            ),
            if (!_running)
              Center(
                child: FilledButton(
                  onPressed: _start,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text('JUGAR CON PEBBLE'),
                  ),
                ),
              ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Text('Toca la pantalla para saltar', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
