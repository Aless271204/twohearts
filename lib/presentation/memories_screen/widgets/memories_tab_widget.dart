import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../services/share_service.dart';

class MemoriesTabWidget extends StatefulWidget {
  const MemoriesTabWidget({super.key});

  @override
  State<MemoriesTabWidget> createState() => _MemoriesTabWidgetState();
}

class _MemoriesTabWidgetState extends State<MemoriesTabWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  final List<Map<String, dynamic>> _photoMaps = [
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1673973655340-d735897a7cdf',
      'semanticLabel':
          'Couple hugging in a park during autumn with colorful leaves',
      'date': '2026-09-15',
      'caption': 'Nuestro paseo de otoño 🍂',
      'likes': 3,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1586985564259-6211deb4c122',
      'semanticLabel': 'Two people video calling and smiling at the screen',
      'date': '2026-09-10',
      'caption': 'Videollamada de medianoche 🌙',
      'likes': 7,
    },
    {
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_124a53871-1772796853794.png',
      'semanticLabel': 'Couple sharing a meal at a restaurant, both smiling',
      'date': '2026-08-28',
      'caption': 'Cuando nos vimos en Madrid 🥂',
      'likes': 12,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1601193709804-cee3c9669766',
      'semanticLabel': 'Two silhouettes watching sunset on a hilltop',
      'date': '2026-08-01',
      'caption': 'Atardecer juntos ☀️',
      'likes': 9,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1707451956654-21cdf1ccf641',
      'semanticLabel': 'Young woman in floral dress smiling in a garden',
      'date': '2026-07-14',
      'caption': 'Foto que me mandaste 🌸',
      'likes': 5,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1704539100427-a931d79ed036',
      'semanticLabel': 'Couple walking hand in hand along a beach boardwalk',
      'date': '2026-06-30',
      'caption': 'Primer viaje juntos 🌊',
      'likes': 18,
    },
  ];

  final List<Map<String, dynamic>> _travelMaps = [
    {
      'city': 'Barcelona, España',
      'emoji': '🇪🇸',
      'date': '2026-08-14',
      'rating': 5,
      'hotel': 'Hotel Arts Barcelona',
      'note':
          'El lugar donde nos reencontramos después de 3 meses. Caminamos por la Barceloneta al atardecer.',
      'imageUrl':
          'https://images.unsplash.com/photo-1703457428215-96a08a7e81c5',
      'semanticLabel':
          'Barcelona cityscape with Sagrada Familia visible in background',
      'expanded': false,
    },
    {
      'city': 'Quito, Ecuador',
      'emoji': '🇪🇨',
      'date': '2026-03-20',
      'rating': 5,
      'hotel': 'Casa Gangotena',
      'note':
          'Primera vez que Mateo visitó mi ciudad. Le mostré el centro histórico y la Mitad del Mundo.',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1d4551e54-1773166258240.png',
      'semanticLabel':
          'Quito Ecuador old town historic center with colonial architecture',
      'expanded': false,
    },
    {
      'city': 'París, Francia',
      'emoji': '🇫🇷',
      'date': '2025-12',
      'rating': 4,
      'hotel': 'Hôtel du Louvre',
      'note':
          'Nuestro primer aniversario. La Torre Eiffel de noche fue mágica.',
      'imageUrl':
          'https://images.unsplash.com/photo-1571433062233-dd3916ec7def',
      'semanticLabel':
          'Eiffel Tower in Paris illuminated at night with city lights below',
      'expanded': false,
    },
  ];

  late List<Map<String, dynamic>> _photos;
  late List<Map<String, dynamic>> _travels;

  @override
  void initState() {
    super.initState();
    _photos = List<Map<String, dynamic>>.from(_photoMaps);
    _travels = List<Map<String, dynamic>>.from(_travelMaps);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily reminder card
          _buildDailyReminderCard(context),
          const SizedBox(height: 20),

          // Photo album section
          _buildSectionHeader('Álbum juntos', '📸', () {}),
          const SizedBox(height: 12),
          _buildPhotoGrid(context),
          const SizedBox(height: 20),

          // Travel map section
          _buildSectionHeader('Viajes', '🗺️', () {}),
          const SizedBox(height: 12),
          _buildTravelList(context),
        ],
      ),
    );
  }

  Widget _buildDailyReminderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withAlpha(31),
            AppTheme.secondary.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withAlpha(38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Recordatorio del día',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text('💌', style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Envía algo que te haya hecho pensar en Mateo hoy',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aparecerá en su pantalla como widget',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReminderTypeButton(
                  emoji: '📷',
                  label: 'Foto',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReminderTypeButton(
                  emoji: '✏️',
                  label: 'Dibujo',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReminderTypeButton(
                  emoji: '💬',
                  label: 'Frase',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String emoji,
    VoidCallback onSeeAll,
  ) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'Ver todo',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, i) {
        final photo = _photos[i];
        return _PhotoCard(photo: photo);
      },
    );
  }

  Widget _buildTravelList(BuildContext context) {
    return Column(
      children: List.generate(_travels.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TravelCard(
            travel: _travels[i],
            onToggle: () {
              setState(() {
                _travels[i] = Map<String, dynamic>.from(_travels[i])
                  ..['expanded'] = !(_travels[i]['expanded'] as bool);
              });
            },
          ),
        );
      }),
    );
  }
}

class _ReminderTypeButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ReminderTypeButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatefulWidget {
  final Map<String, dynamic> photo;

  const _PhotoCard({required this.photo});

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard> {
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await ShareService.instance.shareWithBranding(
        context: context,
        repaintKey: _shareKey,
        caption: widget.photo['caption'] as String? ?? '',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _shareKey,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomImageWidget(
                imageUrl: widget.photo['imageUrl'] as String,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: widget.photo['semanticLabel'] as String,
              ),
              // Bottom gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(153)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.photo['caption'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${widget.photo['likes']}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: Colors.white,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          // Share button
                          GestureDetector(
                            onTap: _share,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                shape: BoxShape.circle,
                              ),
                              child: _sharing
                                  ? const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.share_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelCard extends StatelessWidget {
  final Map<String, dynamic> travel;
  final VoidCallback onToggle;

  const _TravelCard({required this.travel, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isExpanded = travel['expanded'] as bool;
    final rating = travel['rating'] as int;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row — always visible
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // City image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomImageWidget(
                      imageUrl: travel['imageUrl'] as String,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      semanticLabel: travel['semanticLabel'] as String,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              travel['emoji'] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                travel['city'] as String,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: i < rating
                                    ? AppTheme.moodHappy
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              travel['date'] as String,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF9E9E9E),
                    size: 22,
                  ),
                ],
              ),
            ),

            // Expanded content
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: const Color(0xFFEEEEEE), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.hotel_outlined,
                                size: 14,
                                color: Color(0xFF9E9E9E),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                travel['hotel'] as String,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: const Color(0xFF6B6B6B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📝',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    travel['note'] as String,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: const Color(0xFF1A1A1A),
                                      height: 1.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
