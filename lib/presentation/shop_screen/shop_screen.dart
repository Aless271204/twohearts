import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/game_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _coins = 0;
  bool _loadingCoins = true;
  List<String> _ownedKeys = [];

  final List<Map<String, dynamic>> _accessories = [
    {
      'name': 'Sombrero de flores',
      'emoji': '🌸',
      'price': 80,
      'owned': false,
      'category': 'Sombreros',
    },
    {
      'name': 'Bufanda de corazones',
      'emoji': '🧣',
      'price': 120,
      'owned': true,
      'category': 'Ropa',
    },
    {
      'name': 'Gafas de sol',
      'emoji': '🕶️',
      'price': 60,
      'owned': false,
      'category': 'Accesorios',
    },
    {
      'name': 'Corona dorada',
      'emoji': '👑',
      'price': 200,
      'owned': false,
      'category': 'Sombreros',
    },
    {
      'name': 'Lazo rosa',
      'emoji': '🎀',
      'price': 50,
      'owned': true,
      'category': 'Accesorios',
    },
    {
      'name': 'Capa de héroe',
      'emoji': '🦸',
      'price': 180,
      'owned': false,
      'category': 'Ropa',
    },
  ];

  final List<Map<String, dynamic>> _mysteryBoxes = [
    {
      'name': 'Caja Dulce',
      'description': 'Accesorios básicos desbloqueados',
      'emoji': '🎁',
      'price': 150,
      'currency': 'coins',
      'rarity': 'Común',
      'rarityColor': 0xFF9E9E9E,
      'gradient': [0xFFFFD6E0, 0xFFFFF0F5],
    },
    {
      'name': 'Caja Especial',
      'description': 'Accesorios raros de tu mascota',
      'emoji': '✨',
      'price': 300,
      'currency': 'coins',
      'rarity': 'Raro',
      'rarityColor': 0xFF3D7A5E,
      'gradient': [0xFFB8E0CE, 0xFFE8F5EE],
    },
    {
      'name': 'Caja Legendaria',
      'description': 'Items exclusivos de parejas activas',
      'emoji': '💎',
      'price': 4.99,
      'currency': 'real',
      'rarity': 'Legendario',
      'rarityColor': 0xFFE8547A,
      'gradient': [0xFFFFD6E0, 0xFFFFB3C6],
    },
  ];

  final List<Map<String, dynamic>> _coinPacks = [
    {'amount': 100, 'price': 0.99, 'bonus': 0, 'popular': false},
    {'amount': 500, 'price': 3.99, 'bonus': 50, 'popular': true},
    {'amount': 1200, 'price': 7.99, 'bonus': 200, 'popular': false},
    {'amount': 3000, 'price': 14.99, 'bonus': 600, 'popular': false},
  ];

  final List<Map<String, dynamic>> _petCombos = [
    {
      'name': 'Edición Básica',
      'description': 'Tu mascota en su forma actual, ~8cm, impresión premium',
      'emoji': '🐣',
      'price': 24.99,
      'includes': ['Figura 3D ~8cm', 'Acabado suave', 'Caja regalo'],
      'badge': null,
      'color': 0xFFFFD6E0,
    },
    {
      'name': 'Edición Pareja',
      'description': 'Dos figuras de tu mascota, una para cada uno',
      'emoji': '💑',
      'price': 44.99,
      'includes': [
        '2 Figuras 3D ~8cm',
        'Acabado premium',
        '2 Cajas regalo',
        'Tarjeta personalizada',
      ],
      'badge': '⭐ Popular',
      'color': 0xFFB8E0CE,
    },
    {
      'name': 'Edición Evolución',
      'description': 'Set completo con todas las etapas de evolución',
      'emoji': '🌟',
      'price': 89.99,
      'includes': [
        '7 Figuras evolutivas',
        'Acabado artístico',
        'Caja coleccionista',
        'Certificado de pareja',
        'Envío prioritario',
      ],
      'badge': '💎 Premium',
      'color': 0xFFFFE082,
    },
    {
      'name': 'Mood Especial',
      'description': 'Tu mascota con el mood que hayas desbloqueado',
      'emoji': '🎨',
      'price': 29.99,
      'includes': [
        'Figura mood elegido',
        'Acabado pintado a mano',
        'Caja regalo',
        'Foto del proceso',
      ],
      'badge': '🔥 Nuevo',
      'color': 0xFFCE93D8,
    },
  ];

  // Track which combo is expanded
  int? _expandedComboIndex;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final stats = await GameService.instance.getStats();
    final owned = await GameService.instance.getOwnedItemKeys();
    if (mounted) {
      setState(() {
        _coins = stats['love_coins'] as int? ?? 0;
        _ownedKeys = owned;
        _loadingCoins = false;
        // Update owned status in accessories list
        for (final acc in _accessories) {
          final key = (acc['name'] as String).toLowerCase().replaceAll(
            ' ',
            '_',
          );
          if (_ownedKeys.contains(key)) acc['owned'] = true;
        }
      });
    }
  }

  Future<void> _buyWithCoins(Map<String, dynamic> item, int index) async {
    final price = item['price'] as int;
    if (_coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No tienes suficientes LoveCoins ❤️',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    final itemKey = (item['name'] as String).toLowerCase().replaceAll(' ', '_');
    final success = await GameService.instance.purchaseItem(itemKey, price);
    if (success && mounted) {
      setState(() {
        _coins -= price;
        _accessories[index]['owned'] = true;
        _ownedKeys.add(itemKey);
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡${item['name']} desbloqueado! 🎉',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

            // ── Section 1: Tu mascota en físico ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _build3DHeroBanner(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                'Elige tu combo',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Impresión 3D artesanal · Envío a tu dirección',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(
              _petCombos.length,
              (i) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _buildCollapsibleComboCard(_petCombos[i], i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _build3DProcessSection(),
            ),

            // ── Divider ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Divider(color: const Color(0xFFEEEEEE))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('🪙', style: const TextStyle(fontSize: 18)),
                  ),
                  Expanded(child: Divider(color: const Color(0xFFEEEEEE))),
                ],
              ),
            ),

            // ── Section 2: Accesorios con monedas ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accesorios para tu mascota',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Compra con monedas ganadas en la app',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _accessories.length,
                itemBuilder: (context, index) =>
                    _buildAccessoryCard(_accessories[index], index),
              ),
            ),

            // ── Section 3: Mystery Box ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: _buildMysteryBanner(),
            ),
            ...(_mysteryBoxes.map(
              (box) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _buildMysteryBoxCard(box),
              ),
            )),

            // ── Section 4: Monedas ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: _buildCoinsBalance(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Paquetes de monedas',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            ...(_coinPacks.map(
              (pack) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _buildCoinPackCard(pack),
              ),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildEarnCoinsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tienda',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Personaliza y colecciona',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // LoveCoins balance
          GestureDetector(
            onTap: _loadCoins,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFFF7A9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  _loadingCoins
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '$_coins',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                  const SizedBox(width: 2),
                  Text(
                    'LC',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3D Pet Section ──────────────────────────────────────────────────────────

  Widget _build3DHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3460).withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(60),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppTheme.primary.withAlpha(100),
                width: 1,
              ),
            ),
            child: Text(
              '✨ EDICIÓN FÍSICA',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryContainer,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu mascota\nen físico',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Impresión 3D artesanal ~8cm.\nDiseño optimizado, formas suaves,\nsin elementos frágiles.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(180),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _build3DFeatureChip('🖨️ Impresión 3D'),
                        const SizedBox(width: 8),
                        _build3DFeatureChip('📦 Envío incluido'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _build3DFeatureChip('🎨 Pintado a mano'),
                        const SizedBox(width: 8),
                        _build3DFeatureChip('💝 Caja regalo'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha(30),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text('🐣', style: TextStyle(fontSize: 52)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vista 3D',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: Colors.white.withAlpha(150),
                    ),
                  ),
                  Text(
                    '~8 cm',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          color: Colors.white.withAlpha(220),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Collapsible combo card — shows summary, expands details only when "Pedir ahora" is tapped
  Widget _buildCollapsibleComboCard(Map<String, dynamic> combo, int index) {
    final color = Color(combo['color'] as int);
    final badge = combo['badge'] as String?;
    final isExpanded = _expandedComboIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Always-visible summary row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withAlpha(60),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      combo['emoji'] as String,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            combo['name'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(50),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3A3A3A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        combo['description'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF6B6B6B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${combo['price']}',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      'USD',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // "Pedir ahora" button — tapping expands details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _expandedComboIndex = isExpanded ? null : index;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8547A), Color(0xFFFF8FAB)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isExpanded ? 'Cerrar detalles' : 'Pedir ahora',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable order details
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: isExpanded
                ? _buildComboOrderDetails(combo, color)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildComboOrderDetails(Map<String, dynamic> combo, Color color) {
    final includes = combo['includes'] as List<String>;
    final unlockedMoods = ['Fitness 🏋️', 'Cine 🎬', 'Música 🎵', 'Felices 😊'];
    String selectedMood = unlockedMoods.first;

    return StatefulBuilder(
      builder: (context, setLocal) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Includes
            Text(
              'Incluye',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: includes
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✓ $item',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: const Color(0xFF4A4A4A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Mood selector
            Text(
              'Mood de tu mascota',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unlockedMoods.map((mood) {
                final isSelected = selectedMood == mood;
                return GestureDetector(
                  onTap: () => setLocal(() => selectedMood = mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryContainer
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(999),
                      border: isSelected
                          ? Border.all(color: AppTheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      mood,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFF6B6B6B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Address
            Text(
              'Dirección de envío',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nombre completo',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFFBBBBBB),
                ),
              ),
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Dirección completa, ciudad, país, código postal',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Icon(Icons.location_on_outlined, size: 18),
                ),
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFFBBBBBB),
                ),
              ),
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('📦', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tiempo estimado: 5-7 días hábiles para impresión + envío internacional 10-15 días.',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: const Color(0xFF5A4A00),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _expandedComboIndex = null);
                  _showOrderConfirmation(combo);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Confirmar pedido · \$${combo['price']}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DProcessSection() {
    final steps = [
      {
        'icon': '🎨',
        'title': 'Seleccionas tu combo',
        'desc': 'Elige el aspecto y mood de tu mascota',
      },
      {
        'icon': '🖨️',
        'title': 'Imprimimos en 3D',
        'desc': 'Proceso artesanal de 5-7 días hábiles',
      },
      {
        'icon': '🎁',
        'title': 'Empacamos con amor',
        'desc': 'Caja regalo personalizada con tu historia',
      },
      {
        'icon': '🚚',
        'title': 'Enviamos a tu puerta',
        'desc': 'Envío internacional incluido en el precio',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo funciona?',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        step['icon']!,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ${step['title']!}',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          step['desc']!,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showOrderConfirmation(Map<String, dynamic> combo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                '¡Pedido enviado!',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recibirás un correo de confirmación con los detalles de tu ${combo['name']}.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF6B6B6B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📦', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Entrega estimada: 15-22 días',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('¡Perfecto!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Accessories ─────────────────────────────────────────────────────────────

  Widget _buildAccessoryCard(Map<String, dynamic> item, int index) {
    final owned = item['owned'] as bool;
    final canAfford = _coins >= (item['price'] as int);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (owned)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(right: 12, top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Tuyo',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 27),
          Text(item['emoji'] as String, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            item['name'] as String,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            item['category'] as String,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: owned ? null : () => _buyWithCoins(item, index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: owned
                    ? AppTheme.surfaceVariantLight
                    : canAfford
                    ? AppTheme.primary
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!owned) ...[
                    const Text('🪙', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    owned ? 'Equipado' : '${item['price']}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: owned
                          ? const Color(0xFF9E9E9E)
                          : canAfford
                          ? Colors.white
                          : const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mystery Box ──────────────────────────────────────────────────────────────

  Widget _buildMysteryBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8547A), Color(0xFFFF8FAB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mystery Box',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Items basados en lo que\nhan desbloqueado juntos',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white.withAlpha(220),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Text('🎁', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }

  Widget _buildMysteryBoxCard(Map<String, dynamic> box) {
    final isReal = box['currency'] == 'real';
    final colors = (box['gradient'] as List<int>).map((c) => Color(c)).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(box['rarityColor'] as int).withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Text(box['emoji'] as String, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        box['name'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Color(box['rarityColor'] as int).withAlpha(30),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          box['rarity'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(box['rarityColor'] as int),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    box['description'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF5A5A5A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _showBoxOpenAnimation(box),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isReal ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isReal ? '\$${box['price']}' : '🪙 ${box['price']}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isReal ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Abrir',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: isReal
                            ? Colors.white.withAlpha(200)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBoxOpenAnimation(Map<String, dynamic> box) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                '¡Caja abierta!',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Has obtenido: 🌸 Sombrero de flores',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF5A5A5A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('¡Genial!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Coins ────────────────────────────────────────────────────────────────────

  Widget _buildCoinsBalance() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB347).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus monedas',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white.withAlpha(200),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(
                    '$_coins',
                    style: GoogleFonts.dmSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+20 hoy',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.white.withAlpha(200),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Ver historial',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinPackCard(Map<String, dynamic> pack) {
    final isPopular = pack['popular'] as bool;
    final bonus = pack['bonus'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: AppTheme.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Text('🪙', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${pack['amount']} monedas',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (bonus > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+$bonus bonus',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isPopular)
                  Text(
                    '⭐ Más popular',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isPopular ? AppTheme.primary : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '\$${pack['price']}',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isPopular ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnCoinsSection() {
    final ways = [
      {'emoji': '💬', 'action': 'Enviar un mensaje diario', 'coins': '+5'},
      {'emoji': '📸', 'action': 'Compartir un recuerdo', 'coins': '+10'},
      {'emoji': '🎯', 'action': 'Completar una actividad', 'coins': '+20'},
      {'emoji': '🗓️', 'action': 'Racha de 7 días', 'coins': '+50'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gana monedas gratis',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: ways.asMap().entries.map((entry) {
              final i = entry.key;
              final way = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          way['emoji']!,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            way['action']!,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFF2A2A2A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            way['coins']!,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < ways.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
