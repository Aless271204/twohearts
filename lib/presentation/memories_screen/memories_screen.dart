import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/home_widget_service.dart';
import '../../routes/app_routes.dart';
import '../../services/profile_change_notifier.dart';
import '../home_screen/widgets/daily_quote_widget.dart';
import '../home_screen/widgets/couple_map_widget.dart';
import '../home_screen/widgets/couple_header_widget.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  Map<String, dynamic> _coupleData = {
    'myName': '',
    'partnerName': '',
    'myNickname': '',
    'partnerNickname': '',
    'startDate': DateTime.now().subtract(const Duration(days: 1)),
    'myCity': '',
    'partnerCity': '',
    'distanceKm': 0,
  };

  bool _loadingProfile = true;
  bool _realtimeDistance = false;

  int get _daysTogether {
    final start = _coupleData['startDate'] as DateTime;
    return DateTime.now().difference(start).inDays;
  }

  @override
  void initState() {
    super.initState();
    _loadCoupleData();
    // Listen for profile changes (e.g. nickname updated in ProfileScreen)
    ProfileChangeNotifier.instance.addListener(_onProfileChanged);
  }

  void _onProfileChanged() {
    _loadCoupleData();
  }

  Future<void> _loadCoupleData() async {
    try {
      final data = await SupabaseService.instance.getCoupleData();
      if (mounted) {
        final myNick = data['myName'] as String;
        final partnerNick = data['partnerName'] as String;

        setState(() {
          _coupleData = {
            'myName': data['myName'],
            'partnerName': data['partnerName'],
            'myNickname': myNick,
            'partnerNickname': partnerNick,
            'startDate': data['startDate'],
            'myCity': data['myCity'],
            'partnerCity': data['partnerCity'],
            'distanceKm': _coupleData['distanceKm'],
          };
          _loadingProfile = false;
        });

        // Update home screen widgets with fresh data
        final daysTogether = DateTime.now()
            .difference(data['startDate'] as DateTime)
            .inDays;
        HomeWidgetService.instance.updateAllWidgets(
          daysTogether: daysTogether,
          distanceKm: (_coupleData['distanceKm'] as int?) ?? 0,
          dailyQuote: _getDailyQuote(),
          myNickname: myNick,
          partnerNickname: partnerNick,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _getDailyQuote() {
    const quotes = [
      'La distancia no es un obstáculo, es solo una prueba de cuánto vale su amor.',
      'Cada kilómetro que nos separa es un paso más cerca de nuestro reencuentro.',
      'El amor verdadero no conoce fronteras ni distancias.',
      'Aunque estemos lejos, nuestros corazones laten al mismo ritmo.',
      'La espera hace que cada momento juntos sea aún más especial.',
      'El amor a distancia es para los valientes que creen en algo más grande.',
      'Cada mensaje tuyo es un abrazo que llega a través de la pantalla.',
      'La distancia es temporal, pero nuestro amor es eterno.',
      'Te extraño tanto que hasta el silencio tiene tu nombre.',
      'Somos la prueba de que el amor puede con todo.',
      'Cada noche que dormimos bajo las mismas estrellas, no estamos tan lejos.',
      'El amor verdadero espera, confía y nunca se rinde.',
    ];
    final idx =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays %
        quotes.length;
    return quotes[idx];
  }

  @override
  void dispose() {
    ProfileChangeNotifier.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myNick = _coupleData['myNickname'] as String;
    final partnerNick = _coupleData['partnerNickname'] as String;
    final coupleLabel = (myNick.isNotEmpty && partnerNick.isNotEmpty)
        ? '$myNick & $partnerNick'
        : (myNick.isNotEmpty ? myNick : '💑 Nosotros');

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar — "Nuestro Nido"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🪺', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            'Nuestro Nido',
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      _loadingProfile
                          ? Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(60),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            )
                          : Text(
                              coupleLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ],
                  ),
                  const Spacer(),
                  // Settings / Profile button
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.profileScreen),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFFFF7A9A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: _SyncedRecuerdosTab(
                coupleData: _coupleData,
                daysTogether: _daysTogether,
                realtimeDistance: _realtimeDistance,
                onRealtimeToggle: (val) =>
                    setState(() => _realtimeDistance = val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Synced Recuerdos Tab ─────────────────────────────────────────────────────

class _SyncedRecuerdosTab extends StatefulWidget {
  final Map<String, dynamic> coupleData;
  final int daysTogether;
  final bool realtimeDistance;
  final ValueChanged<bool> onRealtimeToggle;

  const _SyncedRecuerdosTab({
    required this.coupleData,
    required this.daysTogether,
    required this.realtimeDistance,
    required this.onRealtimeToggle,
  });

  @override
  State<_SyncedRecuerdosTab> createState() => _SyncedRecuerdosTabState();
}

class _SyncedRecuerdosTabState extends State<_SyncedRecuerdosTab> {
  late Stream<List<Map<String, dynamic>>> _memoriesStream;
  late Stream<List<Map<String, dynamic>>> _tripsStream;
  late Stream<List<Map<String, dynamic>>> _datesStream;

  @override
  void initState() {
    super.initState();
    _memoriesStream = SupabaseService.instance.memoriesStream();
    _tripsStream = SupabaseService.instance.tripsStream();
    _datesStream = SupabaseService.instance.datesStream();
  }

  List<String> _extractTravelCities(List<Map<String, dynamic>> trips) {
    return trips
        .map((t) => t['city'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _tripsStream,
      builder: (context, tripsSnapshot) {
        final trips = tripsSnapshot.data ?? [];
        final travelCities = _extractTravelCities(trips);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Couple stats
              CoupleHeaderWidget(
                myName: widget.coupleData['myName'] as String,
                partnerName: widget.coupleData['partnerName'] as String,
                daysTogether: widget.daysTogether,
                distanceKm: widget.coupleData['distanceKm'] as int,
                myCity: widget.coupleData['myCity'] as String,
                partnerCity: widget.coupleData['partnerCity'] as String,
              ),

              // 2. Interactive map with travel pins
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  '🗺️ Mapa interactivo',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              CoupleMapWidget(
                myCity: widget.coupleData['myCity'] as String,
                partnerCity: widget.coupleData['partnerCity'] as String,
                travelCities: travelCities,
                realtimeEnabled: widget.realtimeDistance,
                onRealtimeToggle: widget.onRealtimeToggle,
              ),

              // 3. Daily quote
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  '✨ Frase del día',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const DailyQuoteWidget(),

              // 4. Send reminder card
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: _buildSendReminderCard(context),
              ),

              // 5. Photo album — REAL-TIME SYNCED
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Álbum juntos',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showAddMemorySheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Agregar',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _memoriesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final memories = snapshot.data ?? [];
                    if (memories.isEmpty) {
                      return _buildEmptyState(
                        '📸',
                        'Aún no hay fotos. ¡Agrega la primera!',
                      );
                    }
                    return _buildPhotoGrid(context, memories);
                  },
                ),
              ),

              // 6. Trips — REAL-TIME SYNCED
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    const Text('🗺️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Viajes',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showAddTripSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Agregar',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: trips.isEmpty
                    ? _buildEmptyState('🗺️', 'Aún no hay viajes registrados.')
                    : _buildTripsList(trips),
              ),

              // 7. Citas — REAL-TIME SYNCED
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    const Text('🗓️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Citas & Veces que nos vimos',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showAddCitaSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Agregar',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _datesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final dates = snapshot.data ?? [];
                    if (dates.isEmpty) {
                      return _buildEmptyState(
                        '🗓️',
                        'Aún no hay citas registradas.',
                      );
                    }
                    return _buildDatesList(dates);
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendReminderCard(BuildContext context) {
    final partnerName = widget.coupleData['partnerNickname'] as String;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withAlpha(31),
            AppTheme.secondary.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withAlpha(38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Recordatorio del día',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              const Text('💌', style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Envía algo que te haya hecho pensar en ${partnerName.isNotEmpty ? partnerName : 'tu pareja'} hoy',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aparecerá en su pantalla como widget',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReminderTypeButton(
                  emoji: '📷',
                  label: 'Foto',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReminderTypeButton(
                  emoji: '✏️',
                  label: 'Dibujo',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReminderTypeButton(
                  emoji: '💬',
                  label: 'Frase',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    List<Map<String, dynamic>> memories,
  ) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: memories.length,
      itemBuilder: (context, i) => _PhotoCard(
        photo: {
          'imageUrl': memories[i]['image_url'] ?? '',
          'semanticLabel': memories[i]['caption'] ?? 'Recuerdo compartido',
          'date': memories[i]['memory_date'] ?? '',
          'caption': memories[i]['caption'] ?? '',
          'likes': memories[i]['likes'] ?? 0,
        },
      ),
    );
  }

  Widget _buildTripsList(List<Map<String, dynamic>> trips) {
    return Column(
      children: trips.map((trip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TravelCard(
            travel: {
              'city': trip['city'] ?? '',
              'emoji': trip['country_emoji'] ?? '🌍',
              'date': trip['trip_date'] ?? '',
              'rating': trip['rating'] ?? 5,
              'hotel': trip['hotel'] ?? '',
              'note': trip['note'] ?? '',
              'imageUrl':
                  trip['image_url'] ??
                  'https://images.unsplash.com/photo-1703457428215-96a08a7e81c5',
              'semanticLabel': '${trip['city'] ?? ''} viaje',
              'expanded': false,
            },
            onToggle: () {},
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatesList(List<Map<String, dynamic>> dates) {
    return Column(
      children: dates.map((date) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CitaCard(
            cita: {
              'title': date['title'] ?? '',
              'description': date['description'] ?? '',
              'date': date['date_on'] ?? '',
              'photos': (date['photos'] as List?)?.cast<String>() ?? <String>[],
              'expanded': false,
            },
            onToggle: () {},
          ),
        );
      }).toList(),
    );
  }

  void _showAddMemorySheet(BuildContext context) {
    final captionController = TextEditingController();
    final imageUrlController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nueva foto 📸',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  hintText: 'URL de la imagen',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFBBBBBB),
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Descripción del recuerdo...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFBBBBBB),
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (captionController.text.isNotEmpty) {
                      await SupabaseService.instance.addMemory(
                        imageUrl: imageUrlController.text.isNotEmpty
                            ? imageUrlController.text
                            : 'https://images.unsplash.com/photo-1673973655340-d735897a7cdf',
                        caption: captionController.text,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Guardar foto',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTripSheet(BuildContext context) {
    final cityController = TextEditingController();
    final noteController = TextEditingController();
    final hotelController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nuevo viaje 🗺️',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  hintText: 'Ciudad, País (ej: Madrid, España)',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFBBBBBB),
                  ),
                  helperText: 'Se marcará en el mapa automáticamente',
                  helperStyle: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppTheme.primary,
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hotelController,
                decoration: InputDecoration(
                  hintText: 'Hotel o alojamiento',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFBBBBBB),
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Nota del viaje...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFBBBBBB),
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (cityController.text.isNotEmpty) {
                      await SupabaseService.instance.addTrip(
                        city: cityController.text,
                        countryEmoji: '🌍',
                        tripDate: DateTime.now().toString().substring(0, 7),
                        hotel: hotelController.text,
                        note: noteController.text,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Guardar viaje',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCitaSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nueva cita 🗓️',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Título (ej: Reencuentro en Madrid)',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFBBBBBB),
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Descripción de ese momento especial...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFBBBBBB),
                  ),
                ),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      await SupabaseService.instance.addDate(
                        title: titleController.text,
                        description: descController.text,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Guardar cita',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _ReminderTypeButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ReminderTypeButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final Map<String, dynamic> photo;
  const _PhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo['imageUrl'] as String,
              fit: BoxFit.cover,
              semanticLabel: photo['semanticLabel'] as String,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.primaryContainer),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(153)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      photo['caption'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${photo['likes']}',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
}

class _TravelCard extends StatefulWidget {
  final Map<String, dynamic> travel;
  final VoidCallback onToggle;

  const _TravelCard({required this.travel, required this.onToggle});

  @override
  State<_TravelCard> createState() => _TravelCardState();
}

class _TravelCardState extends State<_TravelCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rating = widget.travel['rating'] as int;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.travel['imageUrl'] as String,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      semanticLabel: widget.travel['semanticLabel'] as String,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppTheme.primaryContainer,
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
                              widget.travel['emoji'] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.travel['city'] as String,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: i < rating
                                  ? const Color(0xFFFFB347)
                                  : const Color(0xFFDDDDDD),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.travel['date'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded && (widget.travel['note'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  widget.travel['note'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF5A5A5A),
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CitaCard extends StatefulWidget {
  final Map<String, dynamic> cita;
  final VoidCallback onToggle;

  const _CitaCard({required this.cita, required this.onToggle});

  @override
  State<_CitaCard> createState() => _CitaCardState();
}

class _CitaCardState extends State<_CitaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🗓️', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cita['title'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        widget.cita['date'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF9E9E9E),
                ),
              ],
            ),
            if (_expanded &&
                (widget.cita['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.cita['description'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF5A5A5A),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
