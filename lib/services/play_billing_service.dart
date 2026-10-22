import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/store_packages.dart';
import 'inventory_service.dart';
import 'supabase_service.dart';

class PlayBillingService extends ChangeNotifier {
  static final instance = PlayBillingService();
  static const enabled = purchasesEnabled;
  bool get supported =>
      enabled && !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final products = <String, ProductDetails>{};
  bool ready = false, loading = false, busy = false;
  String? message;
  bool _initialized = false;
  final _processing = <String>{};
  final _pending = <String, PurchaseDetails>{};
  String _account(String id) => sha256.convert(utf8.encode(id)).toString();
  void initialize() {
    if (!supported || _initialized) return;
    _initialized = true;
    InAppPurchase.instance.purchaseStream.listen(
      _purchases,
      onError: (_) {
        busy = false;
        message = 'No pudimos consultar las compras. Pulsa Reintentar.';
        notifyListeners();
      },
    );
    SupabaseService.instance.client.auth.onAuthStateChange.listen((_) {
      if (SupabaseService.instance.currentUser != null) {
        unawaited(load());
      } else {
        ready = false;
        products.clear();
        _pending.clear();
        notifyListeners();
      }
    });
    unawaited(load());
  }

  Future<void> load() async {
    if (!supported || loading) return;
    final user = SupabaseService.instance.currentUser;
    if (user == null) {
      message = 'Inicia sesión para comprar oro.';
      notifyListeners();
      return;
    }
    loading = true;
    ready = false;
    notifyListeners();
    try {
      final status = await SupabaseService.instance.client.functions.invoke(
        'play-billing',
        body: {'action': 'status'},
      );
      if (status.data is! Map || status.data['ready'] != true) {
        message = 'Estamos preparando las compras con Google Play.';
        return;
      }
      if (!await InAppPurchase.instance.isAvailable()) {
        message = 'Abre Nido desde Google Play para comprar oro.';
        return;
      }
      final result = await InAppPurchase.instance.queryProductDetails(
        storePackages.map((p) => p.id).toSet(),
      );
      if (result.error != null) throw StateError('store unavailable');
      products
        ..clear()
        ..addEntries(result.productDetails.map((p) => MapEntry(p.id, p)));
      ready = products.isNotEmpty;
      message = ready
          ? null
          : 'Los paquetes todavía no están disponibles en Google Play.';
      await InAppPurchase.instance.restorePurchases(
        applicationUserName: _account(user.id),
      );
    } catch (_) {
      message = 'No pudimos conectar con Google Play. Puedes reintentar.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> buy(String id) async {
    if (!ready || busy || !products.containsKey(id)) return;
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      final opened = await InAppPurchase.instance.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: products[id]!,
          applicationUserName: _account(user.id),
        ),
        autoConsume: false,
      );
      if (!opened) {
        busy = false;
        message = 'La compra no se abrió. No se ha entregado oro.';
      }
    } catch (_) {
      busy = false;
      message = 'No se pudo abrir Google Play. Inténtalo nuevamente.';
    }
    notifyListeners();
  }

  Future<void> retry() async {
    for (final purchase in _pending.values.toList()) {
      await _verify(purchase);
    }
    await load();
  }

  Future<void> _purchases(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      if (!storePackages.any((pack) => pack.id == p.productID)) continue;
      if (p.status == PurchaseStatus.pending) {
        busy = true;
        message = 'Pago pendiente de confirmación de Google Play.';
      } else if (p.status == PurchaseStatus.error ||
          p.status == PurchaseStatus.canceled) {
        busy = false;
        message = p.status == PurchaseStatus.canceled
            ? 'Compra cancelada.'
            : 'Google Play no pudo completar la compra.';
      } else if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _verify(p);
      }
      notifyListeners();
    }
  }

  Future<void> _verify(PurchaseDetails p) async {
    final token = p.verificationData.serverVerificationData;
    if (token.isEmpty || !_processing.add(token)) return;
    _pending[token] = p;
    try {
      final result = await SupabaseService.instance.client.functions.invoke(
        'play-billing',
        body: {'action': 'verify', 'product': p.productID, 'token': token},
      );
      if (result.data is! Map || result.data['verified'] != true)
        throw StateError('unverified');
      // Android only: server consumption already fulfills Google's acknowledgment.
      // Do not acknowledge again after consumption; never grant coins locally.
      _pending.remove(token);
      message = result.data['test'] == true
          ? 'Compra de prueba verificada · +${result.data['gold']} monedas.'
          : 'Compra verificada · +${result.data['gold']} monedas en su cofre.';
      unawaited(InventoryService.instance.refresh().catchError((Object _) {}));
    } catch (_) {
      message =
          'Tu compra está pendiente de verificar. Reintenta sin volver a pagar.';
    } finally {
      _processing.remove(token);
      busy = false;
      notifyListeners();
    }
  }
}
