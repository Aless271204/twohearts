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

  Future<void> _watch() async {
    setState(() => busy = true);
    final message = await RewardedAdsService.instance.watch();
    if (!mounted) return;
    setState(() => busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            '+$rewardedAdGold de oro por vídeo completado · Sin límite diario ni tiempo de espera.',
          ),
          const SizedBox(height: 6),
          const Text(
            'Tú eliges cada vídeo, según disponibilidad. Sin interrupciones durante el juego.',
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
                    !RewardedAdsService.instance.supported
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
