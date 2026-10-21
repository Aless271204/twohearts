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
    'nido_gold_600',
    'Un detalle bonito',
    199,
    600,
    '600 de oro para combinar prendas y pequeños detalles.',
  ),
  StorePackage(
    'nido_gold_2000',
    'Nuestro estilo',
    599,
    2000,
    '2.000 de oro para varios conjuntos o un mueble legendario.',
  ),
  StorePackage(
    'nido_gold_10000',
    'Un Nido de ensueño',
    2499,
    10000,
    '10.000 de oro: alcanza para una habitación completa, los tres conjuntos actuales y una corona legendaria.',
  ),
];
// Configuration only: no client-side crediting or purchased entitlement grants.
const purchasesEnabled = false;

// Proposed balance, configurable before publishing the rewarded ad placement.
// Never credit these amounts from an unverified client callback.
const rewardedAdsEnabled = true;
const rewardedAdGold = 3;
const rewardedAdsWindowLimit = 5;
const rewardedAdsWindowHours = 12;
