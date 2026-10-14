import 'package:flutter/material.dart';
import '../core/store_packages.dart';
import '../services/rewarded_ads_service.dart';
import 'twohearts_ui.dart';

/// Voluntary placement in the game menu, never over a running minigame.
class RewardedGoldCard extends StatefulWidget {
  final bool previewMode;
  const RewardedGoldCard({super.key, this.previewMode = false});
  @override
  State<RewardedGoldCard> createState() => _RewardedGoldCardState();
}

class _RewardedGoldCardState extends State<RewardedGoldCard> {
  bool busy = false;
  int? remaining;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (widget.previewMode || RewardedAdsService.instance.testMode) return;
    try {
      final status = await RewardedAdsService.instance.status();
      if (mounted) setState(() => remaining = status['remaining'] as int?);
    } catch (_) {}
  }

  Future<void> _watch() async {
    setState(() => busy = true);
    final message = await RewardedAdsService.instance.watch();
    if (!mounted) return;
    setState(() => busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.ondemand_video_rounded, color: Color(0xFFF05280)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ver publicidad',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '+$rewardedAdGold de oro por vídeo completado · $rewardedAdsWindowLimit vídeos cada $rewardedAdsWindowHours horas por persona.',
          ),
          const SizedBox(height: 6),
          Text(
            remaining == null
                ? 'Tú eliges cuándo verlo. Sin interrupciones durante el juego.'
                : 'Te quedan $remaining vídeos en las últimas 12 horas.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF716B78)),
          ),
          const SizedBox(height: 12),
          HeartButton(
            label: busy
                ? 'Preparando vídeo…'
                : widget.previewMode
                ? 'Disponible en Android'
                : RewardedAdsService.instance.testMode
                ? 'Probar vídeo · Sin recompensa'
                : 'Ver vídeo · +$rewardedAdGold oro',
            icon: Icons.play_arrow_rounded,
            onPressed:
                busy ||
                    widget.previewMode ||
                    !RewardedAdsService.instance.supported ||
                    remaining == 0
                ? null
                : _watch,
          ),
          if (RewardedAdsService.instance.supported && !widget.previewMode)
            TextButton(
              onPressed: () => RewardedAdsService.instance.privacy(),
              child: const Text('Opciones de privacidad'),
            ),
        ],
      ),
    ),
  );
}
