import '../../services/app_language.dart';
import '../../widgets/twohearts_ui.dart';
import '../../widgets/private_memory_image.dart';
import '../../widgets/rose_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/home_widget_service.dart';
import '../../services/memory_album_service.dart';
import '../../services/profile_change_notifier.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen/widgets/couple_map_widget.dart';
import '../home_screen/widgets/daily_quote_widget.dart';
import '../home_screen/widgets/couple_header_widget.dart';
import './widgets/create_album_sheet.dart';

class MemoriesScreen extends StatefulWidget {
  final List<MemoryAlbum>? previewAlbums;
  const MemoriesScreen({super.key,this.previewAlbums});

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
    if(widget.previewAlbums==null) _loadCoupleData(); else { _loadingProfile=false;_coupleData={..._coupleData,'myName':'Tú','partnerName':'Tu pareja','myNickname':'Tú','partnerNickname':'Tu pareja','startDate':DateTime.now().subtract(const Duration(days:365)),'myCity':'Quito, Ecuador','partnerCity':'Barcelona, España','distanceKm':9350}; }
    ProfileChangeNotifier.instance.addListener(_onProfileChanged);
  }

  void _onProfileChanged() {
    _loadCoupleData();
  }

  Future<void> _loadCoupleData() async {
    try {
      final data = await SupabaseService.instance.getCoupleData();
      final myProfile = await SupabaseService.instance.getMyProfile();
      final partnerProfile = await SupabaseService.instance.getPartnerProfile();
      if (mounted) {
        final myNick = (myProfile?['nickname'] as String?)?.isNotEmpty == true
            ? myProfile!['nickname'] as String
            : data['myName'] as String;
        final partnerNick =
            (partnerProfile?['nickname'] as String?)?.isNotEmpty == true
            ? partnerProfile!['nickname'] as String
            : data['partnerName'] as String;

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

  String _getDailyQuote(){final quotes=AppLanguage.instance.quotes;final now=DateTime.now();return quotes[now.difference(DateTime(now.year)).inDays%quotes.length]['text']!;}

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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HeartHeader(title:'Nuestro Nido',subtitle:coupleLabel,leading:const Icon(Icons.cottage_rounded,color:AppTheme.primary,size:30),actions:[HeartIconButton(icon:Icons.settings_outlined,tooltip:'Ajustes',onPressed:()=>context.push(AppRoutes.profileScreen))]),
            const SizedBox(height: 16),
            Expanded(
              child: _AlbumJuntosTab(
                coupleData: _coupleData,
                previewAlbums:widget.previewAlbums,
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

// ─────────────────────────────────────────────────────────────────────────────
// Album View Mode
// ─────────────────────────────────────────────────────────────────────────────

enum _AlbumViewMode { todos, lugares, fechas, especiales }

// ─────────────────────────────────────────────────────────────────────────────
// Main Tab
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumJuntosTab extends StatefulWidget {
  final Map<String, dynamic> coupleData;
  final List<MemoryAlbum>? previewAlbums;
  final int daysTogether;
  final bool realtimeDistance;
  final ValueChanged<bool> onRealtimeToggle;

  const _AlbumJuntosTab({
    required this.coupleData,
    this.previewAlbums,
    required this.daysTogether,
    required this.realtimeDistance,
    required this.onRealtimeToggle,
  });

  @override
  State<_AlbumJuntosTab> createState() => _AlbumJuntosTabState();
}

class _AlbumJuntosTabState extends State<_AlbumJuntosTab> {
  _AlbumViewMode _viewMode = _AlbumViewMode.todos;
  late Stream<List<MemoryAlbum>> _albumsStream;
  late Stream<List<Map<String, dynamic>>> _tripsStream;

  @override
  void initState() {
    super.initState();
    _albumsStream = widget.previewAlbums!=null?Stream.value(widget.previewAlbums!):MemoryAlbumService.instance.albumsStream();
    _tripsStream = widget.previewAlbums!=null?Stream.value([]):SupabaseService.instance.tripsStream();
  }

  void _showCreateAlbumSheet(BuildContext context) {
    showModalBottomSheet(useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateAlbumSheet(
        onAlbumCreated: () {
          if (mounted)
            setState(() {
              _albumsStream = MemoryAlbumService.instance.albumsStream();
            });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MemoryAlbum>>(
      stream: _albumsStream,
      builder: (context, albumSnap) {
        final albums = albumSnap.data ?? [];
        if (albumSnap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No pudimos cargar los álbumes.'),
                TextButton(
                  onPressed: () => setState(() {
                    _albumsStream = MemoryAlbumService.instance.albumsStream();
                  }),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _tripsStream,
          builder: (context, tripsSnap) {
            final trips = tripsSnap.data ?? [];
            final travelCities = trips
                .map((t) => t['city'] as String? ?? '')
                .where((c) => c.isNotEmpty)
                .toList();

            return NidoWelcomeSurface(child:SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DailyQuoteWidget(),

                  // Couple stats header
                  CoupleHeaderWidget(
                    myName: widget.coupleData['myName'] as String,
                    partnerName: widget.coupleData['partnerName'] as String,
                    daysTogether: widget.daysTogether,
                    distanceKm: widget.coupleData['distanceKm'] as int,
                    myCity: widget.coupleData['myCity'] as String,
                    partnerCity: widget.coupleData['partnerCity'] as String,
                  ),

                  // Map
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text(
                      'Nuestro mapa',
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

                  // ── NUESTRO ÁLBUM JUNTOS ──────────────────────────────────
                  const SizedBox(height: 24),
                  _buildAlbumHeader(context),
                  const SizedBox(height: 16),
                  _buildViewFilterChips(),
                  const SizedBox(height: 16),
                  if (albumSnap.connectionState == ConnectionState.waiting && !albumSnap.hasData) const Padding(padding: EdgeInsets.all(20), child: RoseLoading(label: 'Preparamos su álbum…')) else _buildAlbumContent(context, albums, trips),
                  if (_viewMode == _AlbumViewMode.todos) _legacyPhotos(),
                ],
              ),
            ));
          },
        );
      },
    );
  }

  Widget _legacyPhotos() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.instance.memoriesStream(),
      builder: (context, snap) {
        final photos = snap.data ?? [];
        if (photos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recuerdos anteriores'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: photos
                    .map(
                      (p) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PrivateMemoryImage(
                          p['image_url'] as String? ?? '',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 96,
                            height: 96,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumHeader(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:Row(children:[const Expanded(child:Text('Nuestro álbum',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700))),HeartButton(label:'Crear',icon:Icons.add, onPressed:()=>_showCreateAlbumSheet(context))]));

  Widget _buildViewFilterChips() {
    final filters = [
      (_AlbumViewMode.todos, '🗂️', 'Todos'),
      (_AlbumViewMode.lugares, '📍', 'Lugares'),
      (_AlbumViewMode.fechas, '📅', 'Fechas'),
      (_AlbumViewMode.especiales, '⭐', 'Especiales'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (mode, emoji, label) = filters[i];
          final isSelected = _viewMode == mode;
          return GestureDetector(
            onTap: () => setState(() => _viewMode = mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : const Color(0xFFEEEEEE),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF5A5A5A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumContent(
    BuildContext context,
    List<MemoryAlbum> albums,
    List<Map<String, dynamic>> trips,
  ) {
    switch (_viewMode) {
      case _AlbumViewMode.todos:
        return _buildTodosView(context, albums, trips);
      case _AlbumViewMode.lugares:
        return _buildLugaresView(context, albums, trips);
      case _AlbumViewMode.fechas:
        return _buildFechasView(context, albums);
      case _AlbumViewMode.especiales:
        return _buildEspecialesView(context, albums);
    }
  }

  // ── TODOS view: carousels by category ─────────────────────────────────────

  Widget _buildTodosView(
    BuildContext context,
    List<MemoryAlbum> albums,
    List<Map<String, dynamic>> trips,
  ) {
    if (albums.isEmpty && trips.isEmpty) {
      return _buildEmptyAlbumState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Albums carousel
        if (albums.isNotEmpty) ...[
          _buildCarouselSection(
            context,
            title: 'Álbumes de fotos',
            emoji: '🗂️',
            child: _buildAlbumsCarousel(context, albums),
          ),
          const SizedBox(height: 20),
        ],

        // Trips carousel
        if (trips.isNotEmpty) ...[
          _buildCarouselSection(
            context,
            title: 'Viajes',
            emoji: '✈️',
            child: _buildTripsCarousel(context, trips),
          ),
          const SizedBox(height: 20),
        ],

        // Add first album CTA if no albums
        if (albums.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCreateFirstAlbumCard(context),
          ),
      ],
    );
  }

  // ── LUGARES view ──────────────────────────────────────────────────────────

  Widget _buildLugaresView(
    BuildContext context,
    List<MemoryAlbum> albums,
    List<Map<String, dynamic>> trips,
  ) {
    albums = albums
        .where((a) => a.category == 'lugar' || a.category == 'viaje')
        .toList();
    // Group albums by location tag (use album name as location hint)
    // Also show trips as location cards
    if (albums.isEmpty && trips.isEmpty) {
      return _buildEmptyFilterState(
        context,
        '📍',
        'Aún no hay recuerdos por lugar',
        'Crea un álbum con el nombre del lugar para organizarlo aquí',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trips as location cards
        if (trips.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Lugares visitados',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A5A5A),
              ),
            ),
          ),
          ...trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _LocationCard(trip: trip),
            ),
          ),
        ],

        // Albums as location albums
        if (albums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Álbumes por lugar',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A5A5A),
              ),
            ),
          ),
          ...albums.map(
            (album) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _AlbumCard(album: album),
            ),
          ),
        ],
      ],
    );
  }

  // ── FECHAS view ───────────────────────────────────────────────────────────

  Widget _buildFechasView(BuildContext context, List<MemoryAlbum> albums) {
    if (albums.isEmpty) {
      return _buildEmptyFilterState(
        context,
        '📅',
        'Aún no hay álbumes por fecha',
        'Los álbumes aparecerán ordenados por fecha de creación',
      );
    }

    // Sort albums by creation date descending
    final sorted = List<MemoryAlbum>.from(albums)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Group by month/year
    final Map<String, List<MemoryAlbum>> grouped = {};
    for (final album in sorted) {
      final key = _monthYearLabel(album.createdAt);
      grouped.putIfAbsent(key, () => []).add(album);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.key,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map(
              (album) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _AlbumCard(album: album),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  // ── ESPECIALES view ───────────────────────────────────────────────────────

  Widget _buildEspecialesView(BuildContext context, List<MemoryAlbum> albums) {
    // Special days: albums with Spotify song or with keywords in name
    final specialKeywords = [
      'aniversario',
      'cumpleaños',
      'navidad',
      'año nuevo',
      'san valentín',
      'reencuentro',
      'primera',
      'primer',
      'especial',
      'boda',
      'compromiso',
    ];

    final specialAlbums = albums.where((a) {
      final nameLower = a.albumName.toLowerCase();
      final hasSpotify =
          a.spotifyTrackName != null && a.spotifyTrackName!.isNotEmpty;
      final hasKeyword = specialKeywords.any((k) => nameLower.contains(k));
      return a.category == 'especial' ||
          a.category == 'cita' ||
          hasSpotify ||
          hasKeyword;
    }).toList();

    // Built-in special days timeline
    final startDate = widget.coupleData['startDate'] as DateTime;
    final specialDays = _getSpecialDays(startDate);

    if (specialAlbums.isEmpty && specialDays.isEmpty) {
      return _buildEmptyFilterState(
        context,
        '⭐',
        'Aún no hay días especiales',
        'Los álbumes con canciones o palabras clave como "aniversario" aparecerán aquí',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Special days timeline
        if (specialDays.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Días especiales',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A5A5A),
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: specialDays.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _SpecialDayChip(day: specialDays[i]),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Special albums
        if (specialAlbums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Álbumes especiales',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A5A5A),
              ),
            ),
          ),
          ...specialAlbums.map(
            (album) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _AlbumCard(album: album),
            ),
          ),
        ],
      ],
    );
  }

  List<Map<String, String>> _getSpecialDays(DateTime startDate) {
    return [
      {'emoji': '💑', 'label': 'Primer día', 'date': _formatDate(startDate)},
      {
        'emoji': '🎂',
        'label': '1 mes juntos',
        'date': _formatDate(startDate.add(const Duration(days: 30))),
      },
      {
        'emoji': '🥂',
        'label': '100 días',
        'date': _formatDate(startDate.add(const Duration(days: 100))),
      },
      {
        'emoji': '🎉',
        'label': '6 meses',
        'date': _formatDate(startDate.add(const Duration(days: 180))),
      },
      {
        'emoji': '💍',
        'label': '1 año',
        'date': _formatDate(startDate.add(const Duration(days: 365))),
      },
    ];
  }

  String _formatDate(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _monthYearLabel(DateTime dt) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  // ── Carousel section wrapper ───────────────────────────────────────────────

  Widget _buildCarouselSection(
    BuildContext context, {
    required String title,
    required String emoji,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // ── Albums horizontal carousel ─────────────────────────────────────────────

  Widget _buildAlbumsCarousel(BuildContext context, List<MemoryAlbum> albums) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: LayoutBuilder(builder: (context, constraints) => Wrap(spacing: 12, runSpacing: 12, children: [
      for (final album in albums) SizedBox(width: (constraints.maxWidth - 12) / 2, child: _AlbumCarouselCard(album: album)),
    ])),
  );

  // ── Trips horizontal carousel ──────────────────────────────────────────────

  Widget _buildTripsCarousel(
    BuildContext context,
    List<Map<String, dynamic>> trips,
  ) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _TripCarouselCard(trip: trips[i]),
      ),
    );
  }

  // ── Empty states ───────────────────────────────────────────────────────────

  Widget _buildEmptyAlbumState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildCreateFirstAlbumCard(context),
    );
  }

  Widget _buildCreateFirstAlbumCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCreateAlbumSheet(context),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withAlpha(20),
              AppTheme.secondary.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withAlpha(40),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            const Text('📷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Crea su primer álbum juntos',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega fotos, un título y una descripción para guardar sus recuerdos',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF6B6B6B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+ Crear álbum',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
              title,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF746874),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Album Carousel Card (compact horizontal card)
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumCarouselCard extends StatefulWidget {
  final MemoryAlbum album;
  const _AlbumCarouselCard({required this.album});

  @override
  State<_AlbumCarouselCard> createState() => _AlbumCarouselCardState();
}

class _AlbumCarouselCardState extends State<_AlbumCarouselCard> {
  final bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final hasPhotos = album.photoUrls.isNotEmpty;

    return GestureDetector(
      onTap: () => _showAlbumDetail(context, album),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: hasPhotos
                  ? PrivateMemoryImage(
                      album.photoUrls.first,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 140,
                        color: AppTheme.primaryContainer,
                        child: const Center(
                          child: Text('📸', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 140,
                      color: AppTheme.primaryContainer,
                      child: const Center(
                        child: Text('📸', style: TextStyle(fontSize: 32)),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.albumName,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 11,
                        color: Color(0xFF746874),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${album.photoUrls.length} foto${album.photoUrls.length != 1 ? 's' : ''}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF746874),
                        ),
                      ),
                      if (album.spotifyTrackName?.isNotEmpty == true) ...[
                        const SizedBox(width: 6),
                        const Text('🎵', style: TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlbumDetail(BuildContext context, MemoryAlbum album) {
    showModalBottomSheet(useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlbumDetailSheet(album: album),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trip Carousel Card
// ─────────────────────────────────────────────────────────────────────────────

class _TripCarouselCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripCarouselCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        trip['image_url'] as String? ??
        'https://images.unsplash.com/photo-1703457428215-96a08a7e81c5';
    final city = trip['city'] as String? ?? '';
    final emoji = trip['country_emoji'] as String? ?? '🌍';
    final date = trip['trip_date'] as String? ?? '';

    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PrivateMemoryImage(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.primaryContainer),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(180)],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$emoji $city',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Album Card (full width, expandable)
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumCard extends StatefulWidget {
  final MemoryAlbum album;
  const _AlbumCard({required this.album});

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final hasPhotos = album.photoUrls.isNotEmpty;
    final hasSpotify =
        album.spotifyTrackName != null && album.spotifyTrackName!.isNotEmpty;

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
              color: AppTheme.primary.withAlpha(18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasPhotos
                        ? PrivateMemoryImage(
                            album.photoUrls.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: AppTheme.primaryContainer,
                              child: const Center(
                                child: Text(
                                  '📸',
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppTheme.primaryContainer,
                            child: const Center(
                              child: Text('📸', style: TextStyle(fontSize: 24)),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.albumName,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: 12,
                              color: Color(0xFF746874),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${album.photoUrls.length} foto${album.photoUrls.length != 1 ? 's' : ''}',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: const Color(0xFF746874),
                              ),
                            ),
                            if (hasSpotify) ...[
                              const SizedBox(width: 8),
                              const Text('🎵', style: TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                        if (album.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            album.description,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFF6B6B6B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF746874),
                    size: 22,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              if (hasPhotos)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemCount: album.photoUrls.length,
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: PrivateMemoryImage(
                        album.photoUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.primaryContainer,
                          child: const Center(
                            child: Text('📸', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasSpotify)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1DB954).withAlpha(50),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🎵', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.spotifyTrackName!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (album.spotifyArtistName != null)
                                Text(
                                  album.spotifyArtistName!,
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
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location Card (for trips in Lugares view)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _LocationCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final city = trip['city'] as String? ?? '';
    final emoji = trip['country_emoji'] as String? ?? '🌍';
    final date = trip['trip_date'] as String? ?? '';
    final note = trip['note'] as String? ?? '';
    final imageUrl =
        trip['image_url'] as String? ??
        'https://images.unsplash.com/photo-1703457428215-96a08a7e81c5';
    final rating = trip['rating'] as int? ?? 5;

    return Container(
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: PrivateMemoryImage(
              imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppTheme.primaryContainer,
                child: const Center(
                  child: Text('📍', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          city,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
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
                        size: 13,
                        color: i < rating
                            ? const Color(0xFFFFB347)
                            : const Color(0xFFDDDDDD),
                      ),
                    ),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF6B6B6B),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: const Color(0xFF746874),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Special Day Chip
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialDayChip extends StatelessWidget {
  final Map<String, String> day;
  const _SpecialDayChip({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withAlpha(25),
            AppTheme.secondary.withAlpha(18),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day['emoji'] ?? '⭐', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            day['label'] ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            day['date'] ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: const Color(0xFF746874),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Album Detail Bottom Sheet (full photo view)
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumDetailSheet extends StatefulWidget {
  final MemoryAlbum album;
  const _AlbumDetailSheet({required this.album});

  @override
  State<_AlbumDetailSheet> createState() => _AlbumDetailSheetState();
}

class _AlbumDetailSheetState extends State<_AlbumDetailSheet> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final hasPhotos = album.photoUrls.isNotEmpty;
    final hasSpotify =
        album.spotifyTrackName != null && album.spotifyTrackName!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.albumName,
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          if (album.description.isNotEmpty)
                            Text(
                              album.description,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: const Color(0xFF6B6B6B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: const Color(0xFF746874),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo carousel
                      if (hasPhotos) ...[
                        SizedBox(
                          height: 260,
                          child: PageView.builder(
                            itemCount: album.photoUrls.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPhotoIndex = i),
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: PrivateMemoryImage(
                                  album.photoUrls[i],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.primaryContainer,
                                    child: const Center(
                                      child: Text(
                                        '📸',
                                        style: TextStyle(fontSize: 48),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (album.photoUrls.length > 1) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              album.photoUrls.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: i == _currentPhotoIndex ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _currentPhotoIndex
                                      ? AppTheme.primary
                                      : AppTheme.primary.withAlpha(60),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // Spotify track
                      if (hasSpotify) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB954).withAlpha(15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF1DB954).withAlpha(50),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    '🎵',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      album.spotifyTrackName!,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (album.spotifyArtistName != null)
                                      Text(
                                        album.spotifyArtistName!,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: const Color(0xFF6B6B6B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Photo grid (thumbnails)
                      if (hasPhotos && album.photoUrls.length > 1) ...[
                        Text(
                          'Todas las fotos',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 1,
                              ),
                          itemCount: album.photoUrls.length,
                          itemBuilder: (context, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: PrivateMemoryImage(
                              album.photoUrls[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: AppTheme.primaryContainer),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
