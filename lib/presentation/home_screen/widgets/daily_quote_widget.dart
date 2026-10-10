import '../../../widgets/twohearts_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/app_language.dart';
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

  List<Map<String, String>> get _quotes => AppLanguage.instance.quotes;
  void _languageChanged() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.addListener(_languageChanged);
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
    AppLanguage.instance.removeListener(_languageChanged);
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
    final quote=_quotes[_quoteIndex];
    return Padding(padding:const EdgeInsets.fromLTRB(20,4,20,0),child:RepaintBoundary(key:_shareKey,child:FadeTransition(opacity:_fadeAnim,child:HeartQuoteCard(text:quote['text']!,eyebrow:AppLanguage.instance.text('Un momento para ustedes','A moment for the two of you','Um momento para vocês'),sendLabel:AppLanguage.instance.text('Enviar a mi pareja','Send to my partner','Enviar para meu amor'),onSend:_sharing?null:_shareToStories,onMore:_nextQuote))));
  }
}
