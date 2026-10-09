import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared visual tokens. These components do not change navigation or data.
class RoseEntrance extends StatelessWidget {
  final Widget child;
  const RoseEntrance({super.key, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 240),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 6 * (1-value)), child: child)),
  );
}

class RoseLoading extends StatelessWidget {
  final String label;
  const RoseLoading({super.key, this.label = 'Preparamos tu nido…'});
  @override
  Widget build(BuildContext context) => RoseEntrance(child: Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppTheme.primaryContainer, shape: BoxShape.circle), child: const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 32)),
      const SizedBox(height: 20),
      Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      const SizedBox(width: 128, child: ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child: LinearProgressIndicator(minHeight: 4, color: AppTheme.primary, backgroundColor: AppTheme.primaryContainer))),
    ]),
  )));
}

/// Three generated illustration panels, without embedding UI text in bitmaps.
class GameArt extends StatelessWidget {
  final int panel;
  const GameArt({super.key, required this.panel});
  @override
  Widget build(BuildContext context) => ClipRect(child: LayoutBuilder(builder: (_, constraints) => OverflowBox(
    alignment: Alignment(-1 + panel.toDouble(), 0),
    maxWidth: constraints.maxWidth * 3,
    minWidth: constraints.maxWidth * 3,
    child: Image.asset('assets/images/ui/game-art.png', width: constraints.maxWidth * 3, height: constraints.maxHeight, fit: BoxFit.fill),
  )));
}

/// Product art is an indicative family thumbnail; the actual object is previewed
/// with the same equipment renderer used by the pet and room before purchase.
class ProductArt extends StatelessWidget {
  final int panel;
  const ProductArt({super.key, required this.panel});
  @override
  Widget build(BuildContext context) => ClipRect(child: LayoutBuilder(builder: (_, constraints) => OverflowBox(
    alignment: Alignment(-1 + (panel % 3).toDouble(), panel < 3 ? -1 : 1),
    minWidth: constraints.maxWidth * 3, maxWidth: constraints.maxWidth * 3,
    minHeight: constraints.maxHeight * 2, maxHeight: constraints.maxHeight * 2,
    child: Image.asset('assets/images/ui/shop-art.png', width: constraints.maxWidth * 3, height: constraints.maxHeight * 2, fit: BoxFit.fill),
  )));
}
