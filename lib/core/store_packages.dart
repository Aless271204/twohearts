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
    'nido_gold_1000',
    'Un toque de ternura',
    199,
    1000,
    '1.000 de oro para prendas y pequeños detalles de su habitación. Incluye voz de mascota.',
    voice: true,
  ),
  StorePackage(
    'nido_gold_2000',
    'Nuestro estilo',
    299,
    2000,
    '2.000 de oro para combinar conjuntos y muebles. Voz personalizable y una adopción. Crecimiento para dos mascotas cuando estén disponibles sus etapas.',
    voice: true,
    customVoice: true,
    adoptions: 1,
    growthPets: 2,
  ),
  StorePackage(
    'nido_gold_5000',
    'Un nido completo',
    499,
    5000,
    '5.000 de oro para una gran colección. Tres adopciones y voz interactiva. Crecimiento reservado hasta disponer de las etapas.',
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
const rewardedAdsEnabled = true;
const rewardedAdGold = 3;
const rewardedAdsWindowLimit = 5;
const rewardedAdsWindowHours = 12;
