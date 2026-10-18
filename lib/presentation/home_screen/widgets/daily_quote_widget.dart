import '../../../widgets/twohearts_ui.dart';
import 'package:flutter/material.dart';
import '../../../services/app_language.dart';
import '../../../services/share_service.dart';
import 'dart:async';
import '../../../core/couple_daily_quote.dart';
import '../../../services/supabase_service.dart';
import '../../../services/profile_change_notifier.dart';

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
  Timer? _dayTimer;
  List<String> _members = [];

  List<Map<String, String>> get _quotes => coupleQuoteCatalog;
  Future<void> _refreshQuote() async {
    try {
      final service = SupabaseService.instance,
          profile = await SupabaseService.instance.getMyProfile();
      _members = [
        if (service.currentUser != null) service.currentUser!.id,
        if (profile?['partner_id'] is String) profile!['partner_id'] as String,
      ];
    } catch (_) {}
    if (mounted)
      setState(() => _quoteIndex = coupleQuoteIndex(_members, DateTime.now()));
  }

  void _languageChanged() {
    if (mounted) setState(() {});
  }

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
    ProfileChangeNotifier.instance.addListener(_refreshQuote);
    _refreshQuote();
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = coupleQuoteIndex(_members, DateTime.now());
      if (mounted && next != _quoteIndex) setState(() => _quoteIndex = next);
    });
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_languageChanged);
    ProfileChangeNotifier.instance.removeListener(_refreshQuote);
    _dayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _nextQuote() {
    final quote = _quotes[_quoteIndex];
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('La frase de hoy'),
        content: SelectableText('${quote['source']}\n\n${quote['url']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[_quoteIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: RepaintBoundary(
        key: _shareKey,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: HeartQuoteCard(
            text: quote['text']!,
            source: quote['source'],
            eyebrow: AppLanguage.instance.text(
              'Un momento para ustedes',
              'A moment for the two of you',
              'Um momento para vocês',
            ),
            sendLabel: AppLanguage.instance.text(
              'Enviar a mi pareja',
              'Send to my partner',
              'Enviar para meu amor',
            ),
            onSend: _sharing ? null : _shareToStories,
            onMore: _nextQuote,
          ),
        ),
      ),
    );
  }
}
