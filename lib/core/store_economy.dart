// Prices describe the product, not the size of its wearer.
// Server prices remain authoritative for purchases.
import 'shop_economy_v2.dart';

class StoreEconomy {
  static const rarities = ['Común', 'Especial', 'Exclusivo', 'Legendario'];
  static String rarity(String key) => economyRaritiesV2[key] ?? 'Común';
  static const colorPrice = 10;
  static const colors = {
    'coral': '#F05280',
    'sage': '#B8DCCB',
    'lavender': '#BAA2DB',
    'cream': '#FFF0D9',
    'sky': '#92B9D5',
  };
  static const colorNames = {
    'coral': 'Coral',
    'sage': 'Salvia',
    'lavender': 'Lavanda',
    'cream': 'Crema',
    'sky': 'Cielo',
  };
  static const itemPrices = economyPricesV2;
  static int price(String key, String slot) =>
      itemPrices[key] ??
      switch (slot) {
        'pet_eyes' => 50,
        'pet_body' => 100,
        'pet_feet' => 100,
        'pet_head' => 70,
        'pet_neck' => 50,
        'pet_back' => 120,
        'room_decor' => 60,
        'room_plant' => 100,
        'room_wall' => 140,
        'room_floor' => 180,
        'room_bed' => 400,
        'room_chair' => 450,
        'room_table' => 250,
        'room_dresser' => 350,
        'room_shelf' => 220,
        'room_lamp' || 'room_ceiling' || 'room_mirror' => 160,
        _ => 100,
      };
}
