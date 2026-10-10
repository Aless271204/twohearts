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

const storePackages = [
  StorePackage(
    'nido_gold_099',
    'Un toque de ternura',
    99,
    3000,
    'Dos conjuntos esenciales y decoración para su rincón. Incluye voz de mascota.',
    voice: true,
  ),
  StorePackage(
    'nido_gold_200',
    'Nuestro estilo',
    200,
    10000,
    'Varios conjuntos, muebles y accesorios. Voz personalizable, una adopción y crecimiento para dos mascotas.',
    voice: true,
    customVoice: true,
    adoptions: 1,
    growthPets: 2,
  ),
  StorePackage(
    'nido_gold_500',
    'Un nido completo',
    500,
    30000,
    'Todo el catálogo actual y oro de reserva. Tres adopciones, crecimiento para esas tres mascotas y voz interactiva: frases, datos y chistes.',
    voice: true,
    customVoice: true,
    interactions: true,
    adoptions: 3,
    growthPets: 3,
  ),
];
// Configuration only: no client-side crediting or purchased entitlement grants.
const purchasesEnabled = false;

// Proposed balance, configurable before publishing the rewarded ad placement.
// Never credit these amounts from an unverified client callback.
const rewardedAdsEnabled = false;
const rewardedAdGold = 30;
const rewardedAdsDailyLimit = 5;
