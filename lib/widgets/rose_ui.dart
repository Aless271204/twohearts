import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/inventory_service.dart';
import 'inventory_scene.dart';

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
  Widget build(BuildContext context) => Center(child: Semantics(label: label, child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))));
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

class ProductThumbnail extends StatelessWidget {
  final InventoryItem item;
  const ProductThumbnail({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    if (item.scope == 'room') return RoomItemThumbnail(item: item);
    if (item.scope == 'pet') {
      final color = (item.appearance['color'] as String? ?? '#91bda7').replaceFirst('#','').toLowerCase();
      final file = '${item.slot}-${item.style}-$color.png';
      return ColoredBox(color: const Color(0xFFFFF5F7), child: Image.asset('assets/images/products/$file', fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text('Vista previa disponible al abrir', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall))));
    }
    return ColoredBox(color: item.color.withAlpha(35), child: Center(child: Icon(item.scope == 'pong' ? Icons.sports_tennis_rounded : Icons.style_outlined, size: 48, color: item.color)));
  }
}

/// Original generated travel illustrations for the explicitly labelled review.
class StoryArt extends StatelessWidget {
  final int panel;
  const StoryArt({super.key,required this.panel});
  @override
  Widget build(BuildContext context) => ClipRect(child:LayoutBuilder(builder:(_,c)=>OverflowBox(alignment:Alignment(0,panel==0?-1:1),minHeight:c.maxHeight*2,maxHeight:c.maxHeight*2,minWidth:c.maxWidth,maxWidth:c.maxWidth,child:Image.asset('assets/images/ui/preview-photos.png',width:c.maxWidth,height:c.maxHeight*2,fit:BoxFit.cover))));
}
