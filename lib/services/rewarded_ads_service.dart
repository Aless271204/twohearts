import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/store_packages.dart';
import 'supabase_service.dart';
import 'inventory_service.dart';
import 'scene_audio_policy.dart';

class RewardedAdsService {
  static final instance = RewardedAdsService();
  static const androidUnit = 'ca-app-pub-4237033451731865/6701979953';
  static const _live = bool.fromEnvironment('NIDO_LIVE_ADS');
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get testMode => !kReleaseMode || !_live;
  bool _busy = false;
  Future<void> _consent() async {
    final ready = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (!ready.isCompleted) {
            if (error != null) {
              ready.completeError(
                StateError('No pudimos preparar tu privacidad.'),
              );
            } else {
              ready.complete();
            }
          }
        });
      },
      (error) {
        if (!ready.isCompleted) {
          ready.completeError(StateError('No pudimos preparar tu privacidad.'));
        }
      },
    );
    await ready.future.timeout(const Duration(seconds: 30));
    if (!await ConsentInformation.instance.canRequestAds()) {
      throw StateError(
        'Los anuncios no están disponibles con tu configuración actual.',
      );
    }
    await MobileAds.instance.initialize();
  }

  Future<Map<String, dynamic>> status() async => Map<String, dynamic>.from(
    await SupabaseService.instance.client.rpc('rewarded_ad_status') as Map,
  );
  Future<String> watch() async {
    if (!supported) return 'Los vídeos están disponibles en la app de Android.';
    if (_busy) return 'Ya hay un vídeo en preparación.';
    _busy = true;
    RewardedAd? ad;
    String? ticket;
    var earned = false;
    final db = SupabaseService.instance.client;
    try {
      if (!testMode && db.auth.currentUser == null) {
        return 'Inicia sesión para recibir oro.';
      }
      await _consent();
      final loaded = Completer<RewardedAd>();
      RewardedAd.load(
        adUnitId: testMode
            ? 'ca-app-pub-3940256099942544/5224354917'
            : androidUnit,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: loaded.complete,
          onAdFailedToLoad: (error) => loaded.completeError(
            StateError('No hay vídeos disponibles ahora. Inténtalo más tarde.'),
          ),
        ),
      );
      ad = await loaded.future.timeout(const Duration(seconds: 35));
      if (!testMode) {
        final reservation = Map<String, dynamic>.from(
          await db.rpc('rewarded_ad_begin') as Map,
        );
        ticket = reservation['ticket'] as String;
        await ad.setServerSideOptions(
          ServerSideVerificationOptions(
            userId: db.auth.currentUser!.id,
            customData: ticket,
          ),
        );
      }
      final closed = Completer<void>();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) {
          if (!closed.isCompleted) closed.complete();
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          if (!closed.isCompleted) {
            closed.completeError(
              StateError('El vídeo no pudo abrirse. No se descontó oro.'),
            );
          }
        },
      );
      SceneAudioPolicy.instance.update(covered: true);
      try {
        await ad.show(
          onUserEarnedReward: (_, reward) {
            earned = true;
          },
        );
        await closed.future;
      } finally {
        SceneAudioPolicy.instance.update(covered: false);
      }
      if (testMode) {
        return 'Anuncio de prueba completado. No genera ingresos ni oro real.';
      }
      if (!earned) return 'Vídeo cerrado antes de completar la recompensa.';
      // The SDK callback never credits money. Only Google's signed SSV does.
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final result = Map<String, dynamic>.from(
          await db.rpc('rewarded_ad_result', params: {'p_ticket': ticket})
              as Map,
        );
        if (result['status'] == 'completed') {
          await InventoryService.instance.refresh();
          return '+$rewardedAdGold de oro en tu cofre.';
        }
      }
      return 'Vídeo completado. Confirmamos tu recompensa; aparecerá al actualizar tu saldo.';
    } catch (error) {
      return error is StateError
          ? error.message.toString()
          : 'No pudimos preparar el vídeo. Reintenta más tarde.';
    } finally {
      ad?.dispose();
      if (ticket != null && !earned) {
        try {
          await db.rpc('rewarded_ad_cancel', params: {'p_ticket': ticket});
        } catch (_) {}
      }
      _busy = false;
    }
  }

  Future<void> privacy() => ConsentForm.showPrivacyOptionsForm((error) {});
}
