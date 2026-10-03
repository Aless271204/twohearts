import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';

/// Minijuego 3 — Construye Nuestro Hogar 🏠
/// Stack-style block placement game
class BuildOurHomeGame extends StatefulWidget {
  const BuildOurHomeGame({super.key});
  @override
  State<BuildOurHomeGame> createState() => _BuildOurHomeGameState();
}

class _BuildOurHomeGameState extends State<BuildOurHomeGame>
    with SingleTickerProviderStateMixin {
  static const String gameId = 'build_home';

  bool _isStarted = false;
  bool _isFinished = false;
  int _score = 0;
  int _floors = 0;
  int _bestScore = 0;
  int _coinsEarned = 0;
  int _combo = 0;

  // Moving block
  double _blockX = 0;
  double _blockWidth = 120;
  double _blockDir = 1;
  static const double _blockSpeed = 3;
  double _platformX = 100;
  double _platformWidth = 120;

  late AnimationController _moveController;
  final List<_Block> _blocks = [];
  final List<String> _decorations = [];

  static const List<String> _decoMilestones =
      ['🪴 Planta', '🛋️ Sofá', '🖼️ Cuadro', '❤️ Decoración romántica'];

  static const Map<int, String> _decoMap = {
    10: '🪴',
    20: '🛋️',
    30: '🖼️',
    50: '❤️',
  };

  static const List<String> _levelNames = [
    'Habitación 🛏️',
    'Casa 🏠',
    'Casa Grande 🏡',
    'Casa con Jardín 🌳',
    'Casa de Pareja 💑',
  ];

  String get _currentLevel {
    if (_floors < 10) return _levelNames[0];
    if (_floors < 20) return _levelNames[1];
    if (_floors < 30) return _levelNames[2];
    if (_floors < 50) return _levelNames[3];
    return _levelNames[4];
  }

  @override
  void initState() {
    super.initState();
    _moveController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 16),
          )
          ..addListener(_tick)
          ..repeat();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final rec = await GameService.instance.getRecord(gameId);
    if (mounted) setState(() => _bestScore = rec?['best_score'] as int? ?? 0);
  }

  void _startGame() {
    setState(() {
      _isStarted = true;
      _isFinished = false;
      _score = 0;
      _floors = 0;
      _combo = 0;
      _blockX = 0;
      _blockWidth = 120;
      _blockDir = 1;
      _platformX = 100;
      _platformWidth = 120;
      _blocks.clear();
      _decorations.clear();
      _coinsEarned = 0;
    });
  }

  void _tick() {
    if (!_isStarted || _isFinished || !mounted) return;
    setState(() {
      _blockX += _blockSpeed * _blockDir;
      if (_blockX > 250 || _blockX < 0) _blockDir *= -1;
    });
  }

  void _placeBlock() {
    if (!_isStarted || _isFinished) return;
    HapticFeedback.mediumImpact();

    final overlap = _calcOverlap();
    if (overlap <= 0) {
      // Missed — game over
      setState(() {
        _isFinished = true;
        _coinsEarned = _calcCoins(_score);
      });
      _saveResult();
      return;
    }

    final perfect = overlap >= _platformWidth * 0.9;
    if (perfect) {
      _combo++;
      _score += 10 + _combo * 2;
    } else {
      _combo = 0;
      _score += 5;
    }

    _floors++;
    _blocks.add(_Block(x: _blockX, width: overlap, floor: _floors));

    // Check decoration milestone
    if (_decoMap.containsKey(_floors)) {
      _decorations.add(_decoMap[_floors]!);
    }

    // Update platform for next block
    _platformX = _blockX;
    _platformWidth = overlap;
    _blockX = 0;
    _blockWidth = overlap;

    setState(() {});
  }

  double _calcOverlap() {
    final blockLeft = _blockX;
    final blockRight = _blockX + _blockWidth;
    final platLeft = _platformX;
    final platRight = _platformX + _platformWidth;
    final overlapLeft = max(blockLeft, platLeft);
    final overlapRight = min(blockRight, platRight);
    return max(0, overlapRight - overlapLeft);
  }

  int _calcCoins(int score) {
    if (score >= 200) return 30;
    if (score >= 100) return 20;
    if (score >= 40) return 14;
    return 10;
  }

  Future<void> _saveResult() async {
    final isRecord = _score > _bestScore;
    final bonus = isRecord ? 20 : 0;
    final total = _coinsEarned + bonus;
    await GameService.instance.addReward(
      coins: total,
      xp: total,
      gameId: gameId,
      score: _score,
    );
    await GameService.instance.completeChallenge('play_1');
    if (mounted) {
      setState(() {
        _coinsEarned = total;
        if (isRecord) _bestScore = _score;
      });
    }
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Construye Nuestro Hogar 🏠',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: !_isStarted
          ? _buildStart()
          : _isFinished
          ? _buildResult()
          : _buildGame(),
    );
  }

  Widget _buildGame() {
    return GestureDetector(
      onTap: _placeBlock,
      child: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pisos: $_floors',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _currentLevel,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Puntos: $_score',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Decorations earned
          if (_decorations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Desbloqueado: ',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF5A5A5A),
                    ),
                  ),
                  ..._decorations.map(
                    (d) => Text(d, style: const TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),
          // Game area
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Ground
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 40, color: const Color(0xFFFFCC80)),
                ),
                // Stacked blocks
                ..._buildStackedBlocks(),
                // Moving block
                Positioned(
                  top: 60,
                  left: _blockX,
                  child: Container(
                    width: _blockWidth,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('🏠', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                // Tap hint
                const Positioned(
                  bottom: 60,
                  child: Text(
                    'Toca para colocar el bloque ☝️',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5A5A5A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStackedBlocks() {
    final widgets = <Widget>[];
    for (int i = 0; i < _blocks.length && i < 10; i++) {
      final b = _blocks[_blocks.length - 1 - i];
      final colors = [
        AppTheme.primary,
        AppTheme.secondary,
        const Color(0xFFFFB347),
        const Color(0xFF7B5EA7),
        const Color(0xFF3D7A5E),
      ];
      widgets.add(
        Positioned(
          bottom: 40 + i * 32,
          left: b.x,
          child: Container(
            width: b.width,
            height: 30,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildStart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏠', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(
            'Construye Nuestro Hogar',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca para colocar bloques\nConstruye la casa perfecta',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB347),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              '¡Construir!',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final isRecord = _score >= _bestScore && _score > 0;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB347).withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isRecord ? '🏆 ¡Nuevo Récord!' : '🏠 ¡Casa construida!',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _row('Pisos construidos', '$_floors'),
            _row('Puntuación', '$_score'),
            _row('Récord', '$_bestScore'),
            if (_decorations.isNotEmpty)
              _row('Decoraciones', _decorations.join(' ')),
            _row('LoveCoins ❤️', '+$_coinsEarned'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFB347)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Salir',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFFFFB347),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB347),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Otra vez',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF5A5A5A),
          ),
        ),
        Text(
          v,
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _Block {
  final double x;
  final double width;
  final int floor;
  _Block({required this.x, required this.width, required this.floor});
}