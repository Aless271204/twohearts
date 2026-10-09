import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';
import '../../core/pet_model_catalog.dart';
import './widgets/virtual_pet_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic> _coupleData = {
    'myName': '',
    'partnerName': '',
    'startDate': DateTime.now().subtract(const Duration(days: 1)),
    'myCity': '',
    'partnerCity': '',
    'petName': 'Nuestra mascota',
    'petModelPath': PetModelCatalog.penguinModelPath,
    'petHappiness': 78,
    'petLevel': 3,
  };

  bool _loadingProfile = true;

  late AnimationController _bgController;
  late Animation<double> _bgAnim;

  int get _daysTogether {
    final start = _coupleData['startDate'] as DateTime;
    return DateTime.now().difference(start).inDays;
  }

  String get _timeTogetherLabel {
    final days = _daysTogether;
    if (days < 30) return '$days días';
    if (days < 365) return '${(days / 30).floor()} meses';
    final years = (days / 365).floor();
    final months = ((days % 365) / 30).floor();
    return months > 0
        ? '$years año${years > 1 ? 's' : ''} y $months mes${months > 1 ? 'es' : ''}'
        : '$years año${years > 1 ? 's' : ''}';
  }

  String get _meetDateLabel {
    final d = _coupleData['startDate'] as DateTime;
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _loadCoupleData();
  }

  Future<void> _loadCoupleData() async {
    try {
      final data = await SupabaseService.instance.getCoupleData();
      if (mounted) {
        setState(() {
          _coupleData = {
            ..._coupleData,
            'myName': data['myName'],
            'partnerName': data['partnerName'],
            'startDate': data['startDate'],
            'myCity': data['myCity'],
            'partnerCity': data['partnerCity'],
            'partnerId': data['partnerId'],
            'petName': 'Nuestra mascota',
            'petModelPath': PetModelCatalog.penguinModelPath,
          };
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  void _showEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        myName: _coupleData['myName'] as String,
        myCity: _coupleData['myCity'] as String,
        onSaved: (name, city) {
          setState(() {
            _coupleData['myName'] = name;
            _coupleData['myCity'] = city;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      body: Stack(
        children: [
          // ── Animated cozy room background ──────────────────────────────
          _buildRoomBackground(size),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top couple info bar (non-intrusive)
                _buildTopInfoBar(),
                // Pet takes all remaining space
                Expanded(
                  child: VirtualPetWidget(
                    petName: _coupleData['petName'] as String,
                    petModelPath: _coupleData['petModelPath'] as String,
                    happiness: _coupleData['petHappiness'] as int,
                    level: _coupleData['petLevel'] as int,
                    onFeed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated cozy room background ──────────────────────────────────────────
  Widget _buildRoomBackground(Size size) {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) {
        final t = _bgAnim.value;
        return Stack(
          children: [
            // Sky gradient (shifts subtly)
            Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFF87CEEB),
                      const Color(0xFFB0E0FF),
                      t,
                    )!,
                    Color.lerp(
                      const Color(0xFFE8F4FD),
                      const Color(0xFFF5E6FF),
                      t,
                    )!,
                    Color.lerp(
                      const Color(0xFFFFF0E8),
                      const Color(0xFFFFE4F0),
                      t,
                    )!,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Floor
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        const Color(0xFFD4A574),
                        const Color(0xFFE8B888),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFFC49060),
                        const Color(0xFFD4A070),
                        t,
                      )!,
                    ],
                  ),
                ),
              ),
            ),
            // Floor pattern (wood planks)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: size.height * 0.28,
                child: CustomPaint(painter: _WoodFloorPainter()),
              ),
            ),
            // Wall
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFFFFF8F0),
                        const Color(0xFFFFF0F8),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFFFFF0E8),
                        const Color(0xFFFFE8F5),
                        t,
                      )!,
                    ],
                  ),
                ),
              ),
            ),
            // Wallpaper subtle pattern
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: size.height * 0.72,
                child: CustomPaint(painter: _WallpaperPainter(t)),
              ),
            ),
            // Window on the left
            Positioned(
              top: size.height * 0.12,
              left: 20,
              child: _buildWindow(t),
            ),
            // Bookshelf on the right
            Positioned(
              top: size.height * 0.10,
              right: 16,
              child: _buildBookshelf(),
            ),
            // Small plant bottom left
            Positioned(
              bottom: size.height * 0.24,
              left: 24,
              child: const Text('🪴', style: TextStyle(fontSize: 36)),
            ),
            // Small lamp bottom right
            Positioned(
              bottom: size.height * 0.24,
              right: 24,
              child: const Text('🪑', style: TextStyle(fontSize: 32)),
            ),
            // Floating hearts decoration
            Positioned(
              top: size.height * 0.08,
              right: size.width * 0.35,
              child: AnimatedBuilder(
                animation: _bgAnim,
                builder: (_, __) => Opacity(
                  opacity: 0.3 + _bgAnim.value * 0.2,
                  child: Transform.translate(
                    offset: Offset(0, -_bgAnim.value * 4),
                    child: const Text('💕', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWindow(double t) {
    return Container(
      width: 70,
      height: 80,
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFFB8E4FF), const Color(0xFFD4F0FF), t),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4A574), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Window cross
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 1,
                  color: const Color(0xFFD4A574).withAlpha(120),
                ),
              ],
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 1,
                  height: 80,
                  color: const Color(0xFFD4A574).withAlpha(120),
                ),
              ],
            ),
          ),
          // Sun outside
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) => Opacity(
                opacity: 0.6 + _bgAnim.value * 0.4,
                child: const Text('☀️', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookshelf() {
    return Container(
      width: 55,
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFFD4A574),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(-2, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBookRow(['❤️', '📘', '📗']),
          _buildBookRow(['📕', '💛', '📙']),
        ],
      ),
    );
  }

  Widget _buildBookRow(List<String> books) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: books
          .map((b) => Text(b, style: const TextStyle(fontSize: 12)))
          .toList(),
    );
  }

  // ── Top couple info bar ─────────────────────────────────────────────────────
  Widget _buildTopInfoBar() {
    final myName = _coupleData['myName'] as String;
    final partnerName = _coupleData['partnerName'] as String;
    final hasPartner =
        (_coupleData['partnerId'] as String?) != null ||
        partnerName.isNotEmpty && partnerName != 'Tu pareja';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Nido mascota label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪺', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  'Mascota',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Show pairing button if no partner
          if (!hasPartner)
            GestureDetector(
              onTap: () => context.push(AppRoutes.pairingScreen),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(220),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔗', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Enlazar Nido',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (myName.isNotEmpty || partnerName.isNotEmpty)
            GestureDetector(
              onTap: _showEditProfileSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      myName.isNotEmpty ? myName : 'Tú',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    if (partnerName.isNotEmpty) ...[
                      Text(
                        ' & $partnerName',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF8D6E63),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: Color(0xFF8D6E63),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Edit Profile Bottom Sheet ──────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final String myName;
  final String myCity;
  final void Function(String name, String city) onSaved;

  const _EditProfileSheet({
    required this.myName,
    required this.myCity,
    required this.onSaved,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.myName);
    _cityCtrl = TextEditingController(text: widget.myCity);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre no puede estar vacío');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SupabaseService.instance.updateProfile({
        'full_name': name,
        'city': city,
      });
      widget.onSaved(name, city);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Error al guardar. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Editar mi perfil',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tu nombre y ciudad aparecerán en la app',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 24),
            _buildField('Tu nombre', _nameCtrl, '¿Cómo te llamas?', '👤'),
            const SizedBox(height: 16),
            _buildField('Tu ciudad', _cityCtrl, 'Ej: Madrid, España', '📍'),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.dmSans(fontSize: 13, color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Guardar cambios',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint,
    String emoji,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: GoogleFonts.dmSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFFBBBBBB),
            ),
            prefixText: '$emoji  ',
            prefixStyle: const TextStyle(fontSize: 16),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Custom Painters ────────────────────────────────────────────────────────────

class _WoodFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(12)
      ..strokeWidth = 1;
    // Horizontal plank lines
    for (int i = 0; i < 6; i++) {
      final y = (size.height / 6) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical plank joints (staggered)
    final jointPaint = Paint()
      ..color = Colors.black.withAlpha(8)
      ..strokeWidth = 1;
    for (int row = 0; row < 6; row++) {
      final y = (size.height / 6) * row;
      final offset = (row % 2 == 0) ? 0.0 : size.width * 0.25;
      for (double x = offset; x < size.width; x += size.width * 0.5) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + size.height / 6),
          jointPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WallpaperPainter extends CustomPainter {
  final double t;
  _WallpaperPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withAlpha(8)
      ..style = PaintingStyle.fill;
    // Subtle polka dot pattern
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x + (y / spacing % 2) * 20, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WallpaperPainter old) => old.t != t;
}
