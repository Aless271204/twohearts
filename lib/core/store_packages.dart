class StorePackage {
  final String id, name, description;
  final int cents, gold, adoptions, growthPets;
  final bool voice, customVoice, interactions;
  const StorePackage(
    this.id,
    this.name,
    this.cents,
    this.gold,
    this.description, {
    this.adoptions = 0,
    this.growthPets = 0,
    this.voice = false,
    this.customVoice = false,
    this.interactions = false,
  });
  String get price => 'US\$${(cents / 100).toStringAsFixed(2)}';
}

// Proposed launch prices; Play Billing must supply the localized checkout price.
const storePackages = [
  StorePackage(
    'nido_gold_500',
    'Un detalle bonito',
    99,
    500,
    '500 monedas para prendas y pequeños detalles.',
  ),
  StorePackage(
    'nido_gold_2500',
    'Nuestro estilo',
    399,
    2500,
    '2.500 monedas para combinar conjuntos y muebles.',
  ),
  StorePackage(
    'nido_gold_10000',
    'Un Nido de ensueño',
    999,
    10000,
    '10.000 monedas para una habitación temática completa y varios conjuntos.',
  ),
];
// Configuration only: no client-side crediting or purchased entitlement grants.
const purchasesEnabled = bool.fromEnvironment('NIDO_PLAY_BILLING');

// Proposed balance, configurable before publishing the rewarded ad placement.
// Never credit these amounts from an unverified client callback.
const rewardedAdsEnabled = true;
const rewardedAdGold = 3;
