import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/share_service.dart';

class DailyQuoteWidget extends StatefulWidget {
  const DailyQuoteWidget({super.key});

  @override
  State<DailyQuoteWidget> createState() => _DailyQuoteWidgetState();
}

class _DailyQuoteWidgetState extends State<DailyQuoteWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  int _quoteIndex = 0;
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;

  final List<Map<String, String>> _quotes = [
    {
      'text':
          'El amor es paciente, es bondadoso. El amor no tiene envidia, no es jactancioso, no se enorgullece.',
      'source': '1 Corintios 13:4',
      'type': 'Versículo',
    },
    {
      'text': 'Wherever you are, you will always be in my heart.',
      'source': 'Gandhi',
      'type': 'Frase',
    },
    {
      'text': 'I carry your heart with me, I carry it in my heart.',
      'source': 'E.E. Cummings',
      'type': 'Poema',
    },
    {
      'text': 'Distance is not for the fearful, it is for the bold.',
      'source': 'Inédita',
      'type': 'Inédita',
    },
    {
      'text': 'Eres tú la única que puedo ver, en este universo paralelo.',
      'source': 'Película: Coherence',
      'type': 'Película',
    },
    {
      'text':
          'I would rather spend one lifetime with you than face all the ages of this world alone.',
      'source': 'El Señor de los Anillos',
      'type': 'Película',
    },
    {
      'text':
          'La distancia no es un obstáculo, es solo una prueba de cuánto vale lo que sientes.',
      'source': 'Anónimo',
      'type': 'Frase',
    },
    {
      'text': 'Cada vez que pienso en ti, sonrío sin razón aparente.',
      'source': 'Anónimo',
      'type': 'Frase',
    },
    {
      'text': 'El amor verdadero no conoce fronteras ni distancias.',
      'source': 'Anónimo',
      'type': 'Frase',
    },
    {
      'text': 'Amar es encontrar en la felicidad de otro tu propia felicidad.',
      'source': 'Leibniz',
      'type': 'Frase',
    },
    {
      'text': 'You are my today and all of my tomorrows.',
      'source': 'Leo Christopher',
      'type': 'Frase',
    },
    {
      'text': 'In all the world, there is no heart for me like yours.',
      'source': 'Maya Angelou',
      'type': 'Poema',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _quoteIndex =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays %
        _quotes.length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextQuote() {
    _controller.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _quoteIndex = (_quoteIndex + 1) % _quotes.length;
      });
      _controller.forward();
    });
  }

  Future<void> _shareToStories() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final quote = _quotes[_quoteIndex];
      await ShareService.instance.shareWithBranding(
        context: context,
        repaintKey: _shareKey,
        caption: '"${quote['text']!}" — ${quote['source']!}',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Versículo':
        return AppTheme.secondary;
      case 'Poema':
        return const Color(0xFF9C6ADE);
      case 'Película':
        return const Color(0xFF1B6FD8);
      case 'Inédita':
        return AppTheme.primary;
      default:
        return const Color(0xFF6B6B6B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[_quoteIndex];
    final typeColor = _typeColor(quote['type']!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: RepaintBoundary(
        key: _shareKey,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE7EE), Color(0xFFFFF5ED)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
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
                      color: typeColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      quote['type']!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Frase del día',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('✨', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '"${quote['text']!}"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— ${quote['source']!}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: Text(
                        'Enviar a mi pareja',
                        style: GoogleFonts.dmSans(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(
                          color: AppTheme.primary.withAlpha(102),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share to stories button
                  GestureDetector(
                    onTap: _shareToStories,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF8C42)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _sharing
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.share_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                          const SizedBox(width: 5),
                          Text(
                            'Historias',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _nextQuote,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
