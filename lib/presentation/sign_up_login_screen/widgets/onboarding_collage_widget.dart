import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class OnboardingCollageWidget extends StatefulWidget {
  const OnboardingCollageWidget({super.key});

  @override
  State<OnboardingCollageWidget> createState() =>
      _OnboardingCollageWidgetState();
}

class _OnboardingCollageWidgetState extends State<OnboardingCollageWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _opacityAnims;

  final List<_CollageCard> _cards = [
    _CollageCard(
      imageUrl:
          'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?w=400',
      rotation: -12,
      left: -20,
      top: 40,
      width: 160,
      height: 200,
      semanticLabel: 'Young couple embracing outdoors in golden hour light',
    ),
    _CollageCard(
      imageUrl:
          'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=400',
      rotation: 8,
      left: 120,
      top: 10,
      width: 140,
      height: 180,
      semanticLabel: 'Two people holding hands walking along a beach at sunset',
    ),
    _CollageCard(
      imageUrl:
          'https://images.pexels.com/photos/1415131/pexels-photo-1415131.jpeg?w=400',
      rotation: -5,
      left: 200,
      top: 130,
      width: 155,
      height: 195,
      semanticLabel: 'Couple laughing together at a cafe with coffee cups',
    ),
    _CollageCard(
      imageUrl:
          'https://images.pixabay.com/photo/2016/11/29/06/15/silhouettes-1867285_640.jpg',
      rotation: 10,
      left: 30,
      top: 200,
      width: 130,
      height: 160,
      semanticLabel: 'Silhouette of couple against vibrant sunset sky',
    ),
    _CollageCard(
      imageUrl:
          'https://images.pexels.com/photos/1024960/pexels-photo-1024960.jpeg?w=400',
      rotation: -8,
      left: 150,
      top: 300,
      width: 150,
      height: 185,
      semanticLabel: 'Woman in floral dress smiling at camera in park setting',
    ),
    _CollageCard(
      imageUrl:
          'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=400',
      rotation: 6,
      left: -10,
      top: 360,
      width: 145,
      height: 175,
      semanticLabel: 'Couple video calling on laptop, smiling at screen',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _cards.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _scaleAnims = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0.7,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
        )
        .toList();
    _opacityAnims = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();

    // Staggered entrance
    for (int i = 0; i < _cards.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      height: size.height * 0.75,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(_cards.length, (i) {
          final card = _cards[i];
          return Positioned(
            left: card.left,
            top: card.top,
            child: AnimatedBuilder(
              animation: _controllers[i],
              builder: (_, child) => Opacity(
                opacity: _opacityAnims[i].value,
                child: Transform.scale(
                  scale: _scaleAnims[i].value,
                  child: child,
                ),
              ),
              child: Transform.rotate(
                angle: card.rotation * 3.14159 / 180,
                child: Container(
                  width: card.width,
                  height: card.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(31),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomImageWidget(
                      imageUrl: card.imageUrl,
                      width: card.width,
                      height: card.height,
                      fit: BoxFit.cover,
                      semanticLabel: card.semanticLabel,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CollageCard {
  final String imageUrl;
  final double rotation;
  final double left;
  final double top;
  final double width;
  final double height;
  final String semanticLabel;

  const _CollageCard({
    required this.imageUrl,
    required this.rotation,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.semanticLabel,
  });
}
