import '../../../widgets/rose_ui.dart';
import '../../../widgets/twohearts_ui.dart';
import '../../../theme/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/shared_pet_service.dart';
import '../../../widgets/pet_messages_sheet.dart';
import '../../../widgets/pet_family_sheet.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/pet_model_catalog.dart';
import '../../../widgets/pet_3d_viewer.dart';
import '../../../services/inventory_service.dart';
import '../../../widgets/inventory_scene.dart';
import '../../shop_screen/inventory_screen.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class PetEvolutionStage {
  final String name;
  final String emoji;
  final String description;
  final int requiredLevel;
  final Color accentColor;

  const PetEvolutionStage({
    required this.name,
    required this.emoji,
    required this.description,
    required this.requiredLevel,
    required this.accentColor,
  });
}

class CollectibleMood {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String unlockHint;
  final bool unlocked;
  final Color color;

  const CollectibleMood({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.unlockHint,
    required this.unlocked,
    required this.color,
  });

  CollectibleMood copyWith({bool? unlocked}) => CollectibleMood(
    id: id,
    name: name,
    emoji: emoji,
    description: description,
    unlockHint: unlockHint,
    unlocked: unlocked ?? this.unlocked,
    color: color,
  );
}

// ─── Constants ────────────────────────────────────────────────────────────────

const List<PetEvolutionStage> kEvolutionStages = [
  PetEvolutionStage(name:'Cría',emoji:'🌱',description:'Pequeña y acompañada por sus cuidados.',requiredLevel:1,accentColor:Color(0xFFFFD6A5)),
  PetEvolutionStage(name:'Juvenil',emoji:'🌿',description:'Crece con el cuidado de los dos.',requiredLevel:5,accentColor:Color(0xFFFFE066)),
  PetEvolutionStage(name:'Adulta',emoji:'🌳',description:'Una compañera que han criado juntos.',requiredLevel:10,accentColor:Color(0xFF90CAF9)),
];

const List<CollectibleMood> kDefaultMoods = [
  CollectibleMood(
    id: 'fitness',
    name: 'Fitness',
    emoji: '🏋️',
    description: 'Disciplina hoy, resultados mañana.',
    unlockHint: 'Haz ejercicio juntos',
    unlocked: true,
    color: Color(0xFFA5D6A7),
  ),
  CollectibleMood(
    id: 'cinema',
    name: 'Cine',
    emoji: '🎬',
    description: 'Las mejores historias... contigo.',
    unlockHint: 'Ve una película juntos',
    unlocked: true,
    color: Color(0xFF9FA8DA),
  ),
  CollectibleMood(
    id: 'food',
    name: 'Comida',
    emoji: '🍳',
    description: 'La vida sabe mejor en pareja.',
    unlockHint: 'Cocinen algo juntos',
    unlocked: false,
    color: Color(0xFFFFCC80),
  ),
  CollectibleMood(
    id: 'travel',
    name: 'Viajes',
    emoji: '✈️',
    description: 'Coleccionando lugares y momentos.',
    unlockHint: 'Planifica un viaje',
    unlocked: false,
    color: Color(0xFF80DEEA),
  ),
  CollectibleMood(
    id: 'music',
    name: 'Música',
    emoji: '🎵',
    description: 'Buenas vibras, siempre.',
    unlockHint: 'Escuchen música juntos',
    unlocked: true,
    color: Color(0xFFF48FB1),
  ),
  CollectibleMood(
    id: 'series',
    name: 'Series',
    emoji: '📺',
    description: 'Tú, yo y una buena serie.',
    unlockHint: 'Maratón de series',
    unlocked: false,
    color: Color(0xFFB39DDB),
  ),
  CollectibleMood(
    id: 'rainy',
    name: 'Lluvia',
    emoji: '🌧️',
    description: 'Incluso la lluvia es mejor contigo.',
    unlockHint: 'Día de lluvia juntos',
    unlocked: false,
    color: Color(0xFF90CAF9),
  ),
  CollectibleMood(
    id: 'angry',
    name: 'Enojados',
    emoji: '😤',
    description: 'También es parte del amor.',
    unlockHint: 'Registra un mal día',
    unlocked: false,
    color: Color(0xFFEF9A9A),
  ),
  CollectibleMood(
    id: 'happy',
    name: 'Felices',
    emoji: '😊',
    description: 'Contigo todo es más bonito.',
    unlockHint: 'Registra un día feliz',
    unlocked: true,
    color: Color(0xFFFFE082),
  ),
];

// ─── Main Widget ──────────────────────────────────────────────────────────────

class VirtualPetWidget extends StatefulWidget {
  final String petName;
  final String petModelPath;
  final int happiness;
  final int level;
  final VoidCallback onFeed;
  final bool previewMode;

  const VirtualPetWidget({
    super.key,
    required this.petName,
    this.petModelPath = PetModelCatalog.defaultModelPath,
    required this.happiness,
    required this.level,
    required this.onFeed,
    this.previewMode=false,
  });

  @override
  State<VirtualPetWidget> createState() => _VirtualPetWidgetState();
}

class _VirtualPetWidgetState extends State<VirtualPetWidget>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _tapController;
  late AnimationController _heartController;
  late AnimationController _glowController;

  late Animation<double> _idleAnim;
  late Animation<double> _tapScaleAnim;
  late Animation<double> _heartAnim;
  late Animation<double> _glowAnim;

  bool _showHearts = false;
  bool _showFeedEffect = false;
  String _activeMoodId = 'happy';
  final List<CollectibleMood> _moods = List.from(kDefaultMoods);
  final _pet = SharedPetService.instance;
  Timer? _carePoll;
  bool _careBusy = false;
  int get _hunger => _pet.hunger;
  int get _energy => _pet.energy;

  @override
  void initState() {
    super.initState();
    InventoryService.instance.addListener(_inventoryChanged);
    _pet.addListener(_inventoryChanged);
    if(!widget.previewMode) _pet.refresh().catchError((Object _) {});
    if(!widget.previewMode) _carePoll = Timer.periodic(const Duration(seconds: 20), (_) {
      _pet.refresh().catchError((Object _) {});
      if(!widget.previewMode) InventoryService.instance.refresh().catchError((Object _) {});
    });
    if(!widget.previewMode) InventoryService.instance.refresh().catchError((Object _) {});

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _idleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    _tapScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.025), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.025, end: 0.985), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.985, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));

    _heartAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));

    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _inventoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    InventoryService.instance.removeListener(_inventoryChanged);
    _pet.removeListener(_inventoryChanged);
    _carePoll?.cancel();
    _idleController.dispose();
    _tapController.dispose();
    _heartController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  PetEvolutionStage get _currentStage {
    PetEvolutionStage stage = kEvolutionStages.first;
    for (final s in kEvolutionStages) {
      if (_pet.level >= s.requiredLevel) stage = s;
    }
    return stage;
  }

  PetEvolutionStage? get _nextStage {
    for (final s in kEvolutionStages) {
      if (_pet.level < s.requiredLevel) return s;
    }
    return null;
  }

  CollectibleMood get _activeMood => _moods.firstWhere(
    (m) => m.id == _activeMoodId,
    orElse: () => _moods.first,
  );

  void _handlePetTap() {
    _care('stroke');
    HapticFeedback.lightImpact();
    _tapController.forward(from: 0);
    setState(() => _showHearts = true);
    _heartController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showHearts = false);
    });
  }

  Future<void> _care(String action) async {
    if(widget.previewMode){_tapController.forward(from:0);return;}
    if (_careBusy) return;
    _careBusy = true;
    try {
      await _pet.care(action);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() => _showFeedEffect = action == 'feed');
      _tapController.forward(from: 0);
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _showFeedEffect = false); });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se guardó el cuidado. Comprueba la conexión o espera 30 segundos antes de repetirlo.')));
    } finally { _careBusy = false; }
  }
  void _handleFeed() { _care('feed'); }

  Color _meterColor(int v) {
    if (v >= 70) return const Color(0xFF4CAF50);
    if (v >= 40) return const Color(0xFFFFB347);
    return const Color(0xFFE8547A);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder:(context,c)=>SingleChildScrollView(child:Column(children:[
    Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:ClipRRect(borderRadius:BorderRadius.circular(26),child:SizedBox(height:(c.maxWidth*1.10).clamp(310.0,470.0),child:PetRoomStage(loadout:InventoryService.instance.loadout,onTap:_handlePetTap,pet:Pet3DViewer(modelPath:PetModelCatalog.modelPathFor(_pet.species),petLevel:_pet.level,altText:'${_pet.displayName}, mascota compartida',autoPlay:true,cameraControls:false,animationName:'Natural_Rest'))))),
    Padding(padding:const EdgeInsets.fromLTRB(12,8,12,0),child:Card(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:14),leading:const Icon(Icons.favorite_rounded,color:AppTheme.primary,size:32),title:Text(_pet.displayName,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Row(children:[Text('Nivel ${_pet.level}',style:const TextStyle(fontSize:12)),const SizedBox(width:10),Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(99),child:LinearProgressIndicator(value:(_pet.level%5)/5,minHeight:5,backgroundColor:Color(0xFFF5E5EB),color:AppTheme.primary)))]),trailing:const Icon(Icons.chevron_right_rounded),onTap:()=>showModalBottomSheet(useRootNavigator:true,context:context,isScrollControlled:true,builder:(_)=>const PetFamilySheet())))),
    Padding(padding:const EdgeInsets.symmetric(vertical:14),child:_buildBottomHUD()),
    Container(margin:const EdgeInsets.fromLTRB(12,0,12,16),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:Column(children:[
      Row(children:[const Text('Accesorios',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700)),const Spacer(),HeartButton(label:'Decorar',icon:Icons.edit_outlined,outlined:true,onPressed:()=>Navigator.of(context,rootNavigator:true).push(MaterialPageRoute<void>(builder:(_)=>ShopScreen(initialScope:'room',previewMode:widget.previewMode))))]),
      const SizedBox(height:8),
      SizedBox(height:68,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:InventoryService.instance.catalog.where((i)=>i.scope=='pet').take(8).length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i){final item=InventoryService.instance.catalog.where((i)=>i.scope=='pet').take(8).elementAt(i);return InkWell(onTap:()=>Navigator.of(context,rootNavigator:true).push(MaterialPageRoute<void>(builder:(_)=>ShopScreen(previewMode:widget.previewMode))),borderRadius:BorderRadius.circular(16),child:ClipRRect(borderRadius:BorderRadius.circular(16),child:SizedBox(width:68,child:ProductThumbnail(item:item))));})),
      const SizedBox(height:8),
      Wrap(alignment:WrapAlignment.center,spacing:4,children:[TextButton.icon(onPressed:_showCareMeterSheet,icon:const Icon(Icons.favorite_border_rounded,size:16),label:const Text('Cuidados')),TextButton.icon(onPressed:_showEvolutionSheet,icon:const Icon(Icons.auto_awesome_outlined,size:16),label:const Text('Evolución')),TextButton.icon(onPressed:_showMoodSelector,icon:const Icon(Icons.mood_rounded,size:16),label:const Text('Ánimo'))]),
    ])),
  ])));

  // ── Pet Character ──────────────────────────────────────────────────────────

  Widget _buildPetCharacter() {
    final stage = _currentStage;
    return Positioned.fill(
      child: GestureDetector(
        onTap: _handlePetTap,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow circle behind pet
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: 220 + _glowAnim.value * 20,
                height: 220 + _glowAnim.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      stage.accentColor.withAlpha(
                        80 + (_glowAnim.value * 40).toInt(),
                      ),
                      stage.accentColor.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),

            // Centered 3D pet model
            AnimatedBuilder(
              animation: Listenable.merge([_idleAnim, _tapScaleAnim]),
              builder: (_, child) {
                final idleOffset = 0.0;
                final scale = _tapController.isAnimating
                    ? _tapScaleAnim.value
                    : 1.0;
                return Transform.translate(
                  offset: Offset(0, idleOffset),
                  child: Transform.scale(scale: scale, alignment: Alignment.bottomCenter, child: child),
                );
              },
              child: FractionallySizedBox(
                alignment: Alignment.bottomCenter,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Pet3DViewer(
                      modelPath: PetModelCatalog.modelPathFor(_pet.species),
                      petLevel: _pet.level,
                      altText: '${_pet.displayName}, mascota 3D compartida',
                      autoPlay: true,
                      cameraControls: false,
                      cameraOrbit:
                          widget.petModelPath ==
                              PetModelCatalog.penguinModelPath
                          ? '0deg 75deg 105%'
                          : null,
                      animationName:
                          widget.petModelPath ==
                              PetModelCatalog.penguinModelPath
                          ? 'Idle_9'
                          : 'Idle_11',
                    ),

                  ],
                ),
              ),
            ),

            if (_showFeedEffect)
              const Positioned(
                top: 110,
                right: 64,
                child: Text('🍎', style: TextStyle(fontSize: 28)),
              ),

            // Floating hearts on tap
            if (_showHearts)
              AnimatedBuilder(
                animation: _heartAnim,
                builder: (_, __) {
                  return Stack(
                    children: [
                      for (int i = 0; i < 5; i++)
                        Positioned(
                          left:
                              MediaQuery.of(context).size.width / 2 -
                              60 +
                              i * 30.0,
                          top:
                              MediaQuery.of(context).size.height / 2 -
                              80 -
                              _heartAnim.value * 120,
                          child: Opacity(
                            opacity: (1 - _heartAnim.value).clamp(0.0, 1.0),
                            child: Text(
                              ['💕', '✨', '💖', '🌸', '💝'][i],
                              style: TextStyle(fontSize: 18 + (i % 3) * 4.0),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

            // Tap hint
            Positioned(
              bottom: 60,
              child: AnimatedBuilder(
                animation: _idleAnim,
                builder: (_, __) => Opacity(
                  opacity: 0.4 + _idleAnim.value * 0.3,
                  child: Text(
                    '¡Tócame! 👆',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF6B6B6B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HUD Widgets ────────────────────────────────────────────────────────────

  Widget _buildLevelBadge() {
    final stage = _currentStage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: stage.accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${_pet.level}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            stage.name,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '${InventoryService.instance.coins}',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB8860B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HudActionButton(
            emoji: '🍎',
            label: 'Alimentar',
            color: const Color(0xFFFF6B6B),
            onTap: _handleFeed,
          ),
          _HudActionButton(
            emoji: '🎮',
            label: 'Jugar',
            color: const Color(0xFF6B9FFF),
            onTap: () {
              HapticFeedback.lightImpact();
              _care('play');
            },
          ),
          _HudActionButton(
            emoji: '💌',
            label: 'Mensajes',
            color: const Color(0xFF6BDDFF),
            onTap: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(useRootNavigator: true, context: context, isScrollControlled: true, builder: (_) => const PetMessagesSheet());
            },
          ),
          _HudActionButton(
            emoji: '💤',
            label: 'Descansar',
            color: const Color(0xFFB39DDB),
            onTap: () {
              HapticFeedback.lightImpact();
              _care('rest');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCareMeterIcon() {
    return GestureDetector(
      onTap: () => _showCareMeterSheet(),
      child: _HudCircleButton(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text('❤️', style: TextStyle(fontSize: 22)),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _meterColor(_pet.joy),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodsIcon() {
    return GestureDetector(
      onTap: () => _showMoodSelector(),
      child: _HudCircleButton(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(_activeMood.emoji, style: const TextStyle(fontSize: 22)),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Center(
                  child: Text('⭐', style: TextStyle(fontSize: 7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionIcon() {
    final next = _nextStage;
    final stage = _currentStage;
    final xpProgress = next != null
        ? (_pet.level - stage.requiredLevel) /
              (next.requiredLevel - stage.requiredLevel)
        : 1.0;

    return GestureDetector(
      onTap: () => _showEvolutionSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(stage.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nv. ${_pet.level}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: xpProgress.clamp(0.0, 1.0),
                      backgroundColor: Colors.black.withAlpha(15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        stage.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 14,
              color: Color(0xFF716671),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Sheets ──────────────────────────────────────────────────────────

  void _showCareMeterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CareMeterSheet(
        happiness: _pet.joy,
        hunger: _hunger,
        energy: _energy,
        meterColor: _meterColor,
        onFeed: _handleFeed,
        onPlay: () {
          _care('play');
          Navigator.pop(context);
        },
        onSleep: () {
          _care('rest');
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMoodSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoodSelectorSheet(
        moods: _moods,
        activeMoodId: _activeMoodId,
        onSelect: (id) {
          setState(() => _activeMoodId = id);
          Navigator.pop(context);
        },
        onUnlockHint: (mood) {
          Navigator.pop(context);
          _showUnlockHint(mood);
        },
      ),
    );
  }

  void _showEvolutionSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _EvolutionSheet(currentLevel: _pet.level, stages: kEvolutionStages),
    );
  }

  void _showUnlockHint(CollectibleMood mood) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${mood.emoji} ${mood.name}',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mood.description,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mood.color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Para desbloquear: ${mood.unlockHint}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HUD Helper Widgets ─────────────────────────────────────────────────────────

class _HudCircleButton extends StatelessWidget {
  final Widget child;
  const _HudCircleButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _HudActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HudActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context)=>Semantics(button:true,label:label,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(40),child:Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Container(width:58,height:58,decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle,boxShadow:const[BoxShadow(color:Color(0x12EA5782),blurRadius:12,offset:Offset(0,4))]),child:Center(child:Container(width:46,height:46,decoration:BoxDecoration(color:color.withAlpha(23),shape:BoxShape.circle),child:Icon(emoji=='🍎'?Icons.restaurant_rounded:emoji=='🎮'?Icons.favorite_rounded:emoji=='💌'?Icons.mail_outline_rounded:Icons.nightlight_round,color:emoji=='💤'?const Color(0xFF9A68D9):AppTheme.primary,size:27)))),
    const SizedBox(height:5),Text(label,style:const TextStyle(fontSize:11,color:Color(0xFF504451))),
  ]))));
}

// ── Care Meter Sheet ───────────────────────────────────────────────────────────

class _CareMeterSheet extends StatelessWidget {
  final int happiness;
  final int hunger;
  final int energy;
  final Color Function(int) meterColor;
  final VoidCallback onFeed;
  final bool previewMode;
  final VoidCallback onPlay;
  final VoidCallback onSleep;

  const _CareMeterSheet({
    required this.happiness,
    required this.hunger,
    required this.energy,
    required this.meterColor,
    required this.onFeed,
    this.previewMode=false,
    required this.onPlay,
    required this.onSleep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '💖 Estado de tu mascota',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildMeter('❤️', 'Felicidad', happiness, meterColor(happiness)),
          const SizedBox(height: 12),
          _buildMeter('🍎', 'Comida', hunger, meterColor(hunger)),
          const SizedBox(height: 12),
          _buildMeter('⚡', 'Energía', energy, meterColor(energy)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  emoji: '🍎',
                  label: 'Alimentar',
                  color: const Color(0xFFFF6B6B),
                  onTap: onFeed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SheetActionButton(
                  emoji: '🎮',
                  label: 'Jugar',
                  color: const Color(0xFF6B9FFF),
                  onTap: onPlay,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SheetActionButton(
                  emoji: '💤',
                  label: 'Descansar',
                  color: const Color(0xFFB39DDB),
                  onTap: onSleep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMeter(String emoji, String label, int value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    '$value%',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 8,
                  backgroundColor: Colors.black.withAlpha(12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60), width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mood Selector Sheet ────────────────────────────────────────────────────────

class _MoodSelectorSheet extends StatelessWidget {
  final List<CollectibleMood> moods;
  final String activeMoodId;
  final void Function(String) onSelect;
  final void Function(CollectibleMood) onUnlockHint;

  const _MoodSelectorSheet({
    required this.moods,
    required this.activeMoodId,
    required this.onSelect,
    required this.onUnlockHint,
  });

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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Moods Coleccionables',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cada actividad desbloquea un nuevo mood',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF716671),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: moods.length,
            itemBuilder: (_, i) {
              final mood = moods[i];
              final isActive = mood.id == activeMoodId;
              return GestureDetector(
                onTap: () =>
                    mood.unlocked ? onSelect(mood.id) : onUnlockHint(mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive
                        ? mood.color.withAlpha(60)
                        : mood.unlocked
                        ? mood.color.withAlpha(25)
                        : Colors.black.withAlpha(8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? mood.color
                          : mood.unlocked
                          ? mood.color.withAlpha(60)
                          : Colors.black.withAlpha(15),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            mood.emoji,
                            style: TextStyle(
                              fontSize: 28,
                              color: mood.unlocked
                                  ? null
                                  : const Color(0xFF000000),
                            ),
                          ),
                          if (!mood.unlocked)
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: Text('🔒', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: mood.unlocked
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF716671),
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Evolution Sheet ────────────────────────────────────────────────────────────

class _EvolutionSheet extends StatelessWidget {
  final int currentLevel;
  final List<PetEvolutionStage> stages;

  const _EvolutionSheet({required this.currentLevel, required this.stages});

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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Evolución',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cuídalo y hagan actividades juntos para evolucionar',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF716671),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stages.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFFCCCCCC),
                  ),
                ),
              ),
              itemBuilder: (_, i) {
                final stage = stages[i];
                final unlocked = currentLevel >= stage.requiredLevel;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? stage.accentColor.withAlpha(50)
                            : Colors.black.withAlpha(8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: unlocked
                              ? stage.accentColor
                              : Colors.black.withAlpha(20),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          stage.emoji,
                          style: TextStyle(
                            fontSize: 28,
                            color: unlocked ? null : const Color(0xFF000000),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stage.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: unlocked
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF716671),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? stage.accentColor.withAlpha(60)
                            : Colors.black.withAlpha(10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Nv. ${stage.requiredLevel}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: unlocked
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFF716671),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
