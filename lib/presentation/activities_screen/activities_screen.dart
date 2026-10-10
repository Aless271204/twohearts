import '../../widgets/twohearts_ui.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../theme/app_theme.dart';
import '../../services/scene_audio_policy.dart';
import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';
import '../games/game_hub_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  final bool previewMode;
  const ActivitiesScreen({super.key,this.previewMode=false});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  bool _isSpinning = false;
  int _selectedRouletteCategory = 0;
  String? _currentActivity;
  int _spinCount = 0;

  // Audio players
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final AudioPlayer _spinSoundPlayer = AudioPlayer();
  bool _musicPlaying = false;
  bool _audioReady = false;
  int _audioGeneration = 0;

  final List<String> _categories = ['Chill 🌿', 'Spark ✨', 'Tryhard 🔥'];
  final List<Color> _categoryColors = [
    const Color(0xFF3D7A5E),
    const Color(0xFF7B5EA7),
    AppTheme.primary,
  ];

  // Infinite activity pool — all categories combined
  static const List<Map<String, String>> _chillActivities = [
    {'emoji': '🎵', 'text': 'Escuchen la misma playlist en silencio'},
    {'emoji': '📖', 'text': 'Léanse un capítulo de un libro por voz'},
    {'emoji': '🌙', 'text': 'Cuéntense cómo fue su día con detalle'},
    {'emoji': '🍵', 'text': 'Tomen té/café juntos por videollamada'},
    {'emoji': '🌅', 'text': 'Vean el amanecer o atardecer juntos'},
    {'emoji': '🎨', 'text': 'Dibujen lo mismo y comparen resultados'},
    {'emoji': '🌿', 'text': 'Mediten juntos con una app de meditación'},
    {'emoji': '🌟', 'text': 'Cuéntense sus 3 mejores recuerdos juntos'},
    {'emoji': '🕯️', 'text': 'Cenen con velas por videollamada'},
    {'emoji': '🌈', 'text': 'Hagan una lista de sueños compartidos'},
    {'emoji': '🎧', 'text': 'Escuchen un podcast juntos y comenten'},
    {'emoji': '🌸', 'text': 'Envíense fotos de su lugar favorito'},
    {'emoji': '☕', 'text': 'Desayunen juntos por videollamada'},
    {'emoji': '🌙', 'text': 'Lean el horóscopo juntos y rían'},
    {'emoji': '🎶', 'text': 'Creen una playlist de "nuestra música"'},
    {'emoji': '📝', 'text': 'Escriban una carta y léanla en voz alta'},
    {'emoji': '🌺', 'text': 'Cuéntense qué les gusta del otro'},
    {'emoji': '🍃', 'text': 'Hagan una caminata y llámense'},
    {'emoji': '🌊', 'text': 'Vean videos de naturaleza juntos'},
    {'emoji': '🎠', 'text': 'Recuerden su primera cita con detalle'},
  ];

  static const List<Map<String, String>> _sparkActivities = [
    {'emoji': '🎬', 'text': 'Vean una película y graben sus reacciones'},
    {'emoji': '🍳', 'text': 'Cocinen la misma receta en simultáneo'},
    {'emoji': '🎮', 'text': 'Jueguen un videojuego juntos online'},
    {'emoji': '📸', 'text': 'Hagan una sesión de fotos con el mismo tema'},
    {'emoji': '🎤', 'text': 'Canten karaoke juntos por videollamada'},
    {'emoji': '🧩', 'text': 'Resuelvan un puzzle online colaborativo'},
    {'emoji': '🎯', 'text': 'Jueguen trivia de pareja por 30 minutos'},
    {'emoji': '🎲', 'text': 'Jueguen ajedrez o damas online'},
    {'emoji': '🌍', 'text': 'Exploren Google Earth juntos'},
    {'emoji': '🎪', 'text': 'Vean un show de comedia juntos'},
    {'emoji': '🏆', 'text': 'Compitan en un juego de palabras'},
    {'emoji': '🎭', 'text': 'Improvisen una historia juntos'},
    {'emoji': '🎸', 'text': 'Aprendan los acordes de una canción'},
    {'emoji': '🌮', 'text': 'Pidan la misma comida a domicilio'},
    {'emoji': '🎡', 'text': 'Hagan un tour virtual de un museo'},
    {'emoji': '🎻', 'text': 'Escuchen un concierto en vivo online'},
    {'emoji': '🏄', 'text': 'Vean un documental de aventura'},
    {'emoji': '🎪', 'text': 'Hagan un concurso de memes'},
    {'emoji': '🌟', 'text': 'Jueguen "¿Quién me conoce mejor?"'},
    {'emoji': '🎠', 'text': 'Vean fotos antiguas y recuerden'},
  ];

  static const List<Map<String, String>> _tryhardActivities = [
    {'emoji': '💌', 'text': 'Escríbanse una carta de amor de 3 páginas'},
    {'emoji': '🎭', 'text': 'Actúen una escena de su película favorita'},
    {'emoji': '💃', 'text': 'Aprendan y bailen la misma coreografía'},
    {'emoji': '🌍', 'text': 'Planifiquen su próximo viaje al detalle'},
    {'emoji': '🎁', 'text': 'Sorpréndanse con un regalo por correo'},
    {'emoji': '🔥', 'text': 'Reto: 30 días de mensajes de voz cada noche'},
    {'emoji': '🏋️', 'text': 'Hagan el mismo entrenamiento en simultáneo'},
    {'emoji': '📚', 'text': 'Lean el mismo libro y hagan un club'},
    {'emoji': '🎓', 'text': 'Aprendan un idioma nuevo juntos'},
    {'emoji': '🌱', 'text': 'Planten algo y cuídenlo juntos'},
    {'emoji': '🎨', 'text': 'Pinten un cuadro y envíenselo'},
    {'emoji': '🏃', 'text': 'Corran 5km el mismo día y comparen'},
    {'emoji': '🍰', 'text': 'Horneen el mismo pastel y comparen'},
    {'emoji': '📷', 'text': 'Hagan un proyecto fotográfico de 30 días'},
    {'emoji': '🎵', 'text': 'Compongan una canción juntos'},
    {'emoji': '🌟', 'text': 'Creen un álbum de recuerdos físico'},
    {'emoji': '🎯', 'text': 'Establezcan 3 metas de pareja para el año'},
    {'emoji': '💪', 'text': 'Reto de 7 días: un detalle diferente cada día'},
    {'emoji': '🌈', 'text': 'Creen un "bucket list" de pareja'},
    {'emoji': '🏆', 'text': 'Organicen una cita virtual perfecta'},
  ];

  List<Map<String, String>> get _currentPool {
    switch (_selectedRouletteCategory) {
      case 0:
        return _chillActivities;
      case 1:
        return _sparkActivities;
      case 2:
        return _tryhardActivities;
      default:
        return _chillActivities;
    }
  }

  final List<Map<String, dynamic>> _trips = [
    {
      'city': 'Barcelona',
      'country': 'España',
      'emoji': '🏖️',
      'date': 'Próximo viaje',
      'status': 'planned',
      'image': 'https://images.unsplash.com/photo-1609673546199-18c44a4fe406',
      'imageLabel':
          'Barcelona beach with colorful buildings and blue Mediterranean sea',
    },
    {
      'city': 'Quito',
      'country': 'Ecuador',
      'emoji': '🏔️',
      'date': 'Mar 2024',
      'status': 'visited',
      'image': 'https://images.unsplash.com/photo-1718679959891-398f67411b8c',
      'imageLabel':
          'Historic city center with colonial architecture and mountains',
    },
  ];

  // Netflix sync state
  final bool _netflixCountdownActive = false;
  final int _netflixCountdown = 5;
  late AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    SceneAudioPolicy.instance.addListener(_visibilityChanged);
  }

  Future<void> _initAudio() async {
    try {
      // Background music — looping ambient/romantic track
      await _bgMusicPlayer.setUrl(
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      );
      await _bgMusicPlayer.setLoopMode(LoopMode.one);
      await _bgMusicPlayer.setVolume(0.3);
      _audioReady = true;
    } catch (_) {
      // Audio not critical — fail silently
    }
  }

  Future<void> _playSpinSound() async {
    if (!SceneAudioPolicy.instance.activitiesVisible) return;
    final generation = _audioGeneration;
    try {
      // Short spin/tick sound using a free sound URL
      await _spinSoundPlayer.setUrl(
        'https://www.soundjay.com/misc/sounds/magic-chime-02.mp3',
      );
      if (!mounted || generation != _audioGeneration || !SceneAudioPolicy.instance.activitiesVisible) return;
      await _spinSoundPlayer.seek(Duration.zero);
      if (!mounted || generation != _audioGeneration || !SceneAudioPolicy.instance.activitiesVisible) return;
      await _spinSoundPlayer.play();
    } catch (_) {
      // Fallback: haptic feedback
      HapticFeedback.mediumImpact();
    }
  }

  void _visibilityChanged() {
    if (SceneAudioPolicy.instance.activitiesVisible) return;
    _audioGeneration++;
    _bgMusicPlayer.stop();
    _spinSoundPlayer.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _musicPlaying = false); });
  }

  Future<void> _toggleMusic() async {
    if (!SceneAudioPolicy.instance.activitiesVisible) return;
    if (_musicPlaying) {
      _audioGeneration++;
      await _bgMusicPlayer.stop();
      if (mounted) setState(() => _musicPlaying = false);
      return;
    }
    final generation = ++_audioGeneration;
    if (!_audioReady) await _initAudio();
    if (!mounted || generation != _audioGeneration || !SceneAudioPolicy.instance.activitiesVisible || !_audioReady) return;
    setState(() => _musicPlaying = true);
    _bgMusicPlayer.play().catchError((Object _) { if (mounted) setState(() => _musicPlaying = false); });
  }

  @override
  void dispose() {
    _audioGeneration++;
    SceneAudioPolicy.instance.removeListener(_visibilityChanged);
    _spinController.dispose();
    _countdownController.dispose();
    _bgMusicPlayer.dispose();
    _spinSoundPlayer.dispose();
    super.dispose();
  }

  void _spinRoulette() {
    if (_isSpinning) return;
    setState(() {
      _isSpinning = true;
      _currentActivity = null;
      _spinCount++;
    });
    _playSpinSound();
    _spinController.reset();
    _spinController.forward().then((_) {
      final random = Random();
      final pool = _currentPool;
      final idx = (random.nextInt(pool.length) + _spinCount) % pool.length;
      final picked = pool[idx];
      // Play a chime sound when result appears
      HapticFeedback.lightImpact();
      setState(() {
        _isSpinning = false;
        _currentActivity = '${picked['emoji']} ${picked['text']}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildHeader(),
              // Tab bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      gradient: heartGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6B6B6B),
                    labelStyle: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: const [
                      Tab(child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.sports_esports_outlined,size:20),SizedBox(width:7),Text('Juegos')])),
                      Tab(child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.calendar_today_outlined,size:18),SizedBox(width:7),Text('Actividades')])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 0: Game Hub
                    GameHubScreen(previewMode:widget.previewMode),
                    // Tab 1: Original activities
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildRoulette()),
                        SliverToBoxAdapter(child: _buildConnectSection()),
                        SliverToBoxAdapter(child: _buildTripsSection()),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => HeartHeader(title:'Actividades',subtitle:'Hagan cosas juntos ♡',actions:[HeartIconButton(icon:_musicPlaying?Icons.music_note_rounded:Icons.music_off_rounded,tooltip:_musicPlaying?'Apagar música':'Música de actividades',onPressed:_toggleMusic)]);

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cerrar sesión',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Seguro que quieres salir?',
          style: GoogleFonts.dmSans(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmSans(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await SupabaseService.instance.signOut();
              if (context.mounted) context.go(AppRoutes.signUpLogin);
            },
            child: Text(
              'Salir',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoulette() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ruleta de actividades',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_currentPool.length} actividades',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category selector
          Row(
            children: List.generate(_categories.length, (i) {
              final isSelected = i == _selectedRouletteCategory;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedRouletteCategory = i;
                  _currentActivity = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _categoryColors[i]
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _categories[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF716671),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Roulette card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _categoryColors[_selectedRouletteCategory].withAlpha(30),
                  _categoryColors[_selectedRouletteCategory].withAlpha(10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _categoryColors[_selectedRouletteCategory].withAlpha(60),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _spinAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _isSpinning ? _spinAnimation.value * 8 * pi : 0,
                      child: Text(
                        _isSpinning
                            ? '🎲'
                            : (_currentActivity != null ? '✨' : '🎯'),
                        style: const TextStyle(fontSize: 52),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _currentActivity != null
                      ? Text(
                          _currentActivity!,
                          key: ValueKey(_currentActivity),
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          _isSpinning
                              ? 'Eligiendo actividad...'
                              : '¿Qué harán hoy?',
                          key: const ValueKey('placeholder'),
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: const Color(0xFF716671),
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _spinRoulette,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _isSpinning
                          ? _categoryColors[_selectedRouletteCategory]
                                .withAlpha(120)
                          : _categoryColors[_selectedRouletteCategory],
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: _categoryColors[_selectedRouletteCategory]
                              .withAlpha(60),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _isSpinning ? 'Girando...' : '¡Girar ruleta!',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (_currentActivity != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _spinRoulette,
                    child: Text(
                      'Otra actividad',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: _categoryColors[_selectedRouletteCategory],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conectar juntos',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildConnectCard(
                  emoji: '🎵',
                  title: 'Spotify Jam',
                  subtitle: 'Escuchen música en sincronía',
                  color: const Color(0xFF1DB954),
                  onTap: () => _showSpotifySheet(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConnectCard(
                  emoji: '🎬',
                  title: 'Netflix Sync',
                  subtitle: 'Inicien la misma película juntos',
                  color: const Color(0xFFE50914),
                  onTap: () => _showNetflixSheet(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFF716671),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Iniciar',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
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

  Widget _buildTripsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                onTap: () => _showAddTripSheet(),
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
                      const Icon(Icons.add, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Planificar',
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
          const SizedBox(height: 12),
          ..._trips.map((trip) => _buildTripCard(trip)),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final isPlanned = trip['status'] == 'planned';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              trip['image'] as String,
              fit: BoxFit.cover,
              semanticLabel: trip['imageLabel'] as String,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.surfaceVariantLight),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(160),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Text(
                    trip['emoji'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip['city']}, ${trip['country']}',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          trip['date'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPlanned ? AppTheme.primary : AppTheme.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isPlanned ? 'Planificado' : 'Visitado',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  void _showSpotifySheet() {
    showModalBottomSheet(useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎵', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              'Spotify Jam',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una sesión Jam en Spotify y comparte el enlace con tu pareja para escuchar música en sincronía.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF5A5A5A),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Open Spotify deep link
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // Try Spotify app deep link, fallback to web
                  try {
                    await SystemChannels.platform.invokeMethod<void>(
                      'SystemNavigator.routeInformationUpdated',
                    );
                  } catch (_) {}
                  // Open Spotify Jam feature
                  _launchUrl('spotify://');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Abrir Spotify',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchUrl('https://open.spotify.com');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1DB954)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Abrir en navegador',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1DB954),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: GoogleFonts.dmSans(color: const Color(0xFF716671)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNetflixSheet() {
    showModalBottomSheet(useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NetflixSyncSheet(),
    );
  }

  void _launchUrl(String url) {
    // Use platform channel to open URL
    const platform = MethodChannel('flutter/url_launcher');
    platform.invokeMethod('launch', {'url': url}).catchError((_) {});
  }

  void _showAddTripSheet() {
    showModalBottomSheet(useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planificar viaje ✈️',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Destino (ciudad, país)',
                prefixIcon: const Icon(
                  Icons.place_outlined,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Fecha aproximada',
                prefixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Guardar viaje'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Netflix Sync Sheet ───────────────────────────────────────────────────────

class _NetflixSyncSheet extends StatefulWidget {
  const _NetflixSyncSheet();

  @override
  State<_NetflixSyncSheet> createState() => _NetflixSyncSheetState();
}

class _NetflixSyncSheetState extends State<_NetflixSyncSheet>
    with SingleTickerProviderStateMixin {
  int _countdown = 0;
  bool _counting = false;
  bool _launched = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _counting = true;
      _countdown = 5;
      _launched = false;
    });
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown > 0) {
        _tick();
      } else {
        setState(() {
          _counting = false;
          _launched = true;
        });
        // Open Netflix
        const platform = MethodChannel('flutter/url_launcher');
        platform.invokeMethod('launch', {'url': 'netflix://'}).catchError((_) {
          platform
              .invokeMethod('launch', {'url': 'https://www.netflix.com'})
              .catchError((_) {});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎬', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            'Netflix Sync',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ambos presionan "Iniciar" al mismo tiempo. Una cuenta regresiva de 5 segundos abrirá Netflix en sincronía.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF5A5A5A),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_counting)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: GoogleFonts.dmSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (_launched)
            Column(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  '¡Netflix abierto! Disfruten la película 🍿',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startCountdown,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Iniciar cuenta regresiva',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (!_counting)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: GoogleFonts.dmSans(color: const Color(0xFF716671)),
              ),
            ),
        ],
      ),
    );
  }
}
