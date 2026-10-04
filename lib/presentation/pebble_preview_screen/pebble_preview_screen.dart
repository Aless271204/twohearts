import 'package:flutter/material.dart';
import '../../widgets/animated_pet_3d.dart';

class PebblePreviewScreen extends StatefulWidget {
  const PebblePreviewScreen({super.key});

  @override
  State<PebblePreviewScreen> createState() => _PebblePreviewScreenState();
}

class _PebblePreviewScreenState extends State<PebblePreviewScreen> {
  String _animation = 'Walking';

  static const _animations = <String>[
    'Walking',
    'Running',
    'Angry_Ground_Stomp',
    'Back_Jump',
    'Casual_Walk',
    'Happy_jump_f',
    'Jump_Run',
    'Jump_and_Grab_Wall',
    'Regular_Jump',
    'happy_jump_m',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      appBar: AppBar(
        title: const Text('Pebble 3D · Prueba'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ColoredBox(
                    color: Colors.white,
                    child: AnimatedPet3D(
                      key: ValueKey(_animation),
                      animationName: _animation,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
              child: Column(
                children: [
                  const Text(
                    'Toca una animación para probar a Pebble',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _animations.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final name = _animations[index];
                        return ChoiceChip(
                          label: Text(name.replaceAll('_', ' ')),
                          selected: _animation == name,
                          onSelected: (_) => setState(() => _animation = name),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
