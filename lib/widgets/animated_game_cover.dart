import 'package:flutter/material.dart';
import 'rose_ui.dart';

/// Gentle movement on illustrated covers; respects reduced motion and page visibility.
class AnimatedGameCover extends StatefulWidget {
  final int panel;
  const AnimatedGameCover({super.key, required this.panel});
  @override
  State<AnimatedGameCover> createState() => _AnimatedGameCoverState();
}

class _AnimatedGameCoverState extends State<AnimatedGameCover>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      controller.stop();
      controller.value = 0;
    } else if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: controller,
      child: RepaintBoundary(child: GameArt(panel: widget.panel)),
      builder: (_, child) => Transform.scale(
        scale: 1.015 + Curves.easeInOut.transform(controller.value) * .02,
        child: child,
      ),
    ),
  );
}
