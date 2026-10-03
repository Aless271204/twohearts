import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';

/// Minijuego 6 — Carrera de Pareja ❤️🏃
/// Two characters running, tap to collect items, avoid obstacles
class CoupleRaceGame extends StatefulWidget {
  const CoupleRaceGame({super.key});
  @override
  State<CoupleRaceGame> createState() => _CoupleRaceGameState();
}

class _CoupleRaceGameState extends State<CoupleRaceGame>
    with TickerProviderStateMixin {
  static const String gameId = 'couple_race';

  bool _isPlaying = false;
  bool _isFinished = false;
  int _score = 0;
  int _distance = 0;
  int _bestScore = 0;
  int _coinsEarned = 0;

  // Player character (top lane)
  double _playerY = 0;
  double _playerVelY = 0;
  bool _playerJumping = false;

  // Partner character (bottom lane) — AI controlled
  double _partnerY = 0;
  double _partnerVelY = 0;
  bool _partnerJumping = false;

  static const double _gravity = 0.9;
  static const double _jumpForce = -13;
  static const double _groundY = 0;

  final List<_RaceObject> _objects = [];
  final Random _rng = Random();
  double _gameSpeed = 4;
  int _frameCount = 0;

  late AnimationController _runCtrl;

  @override
  void initState() {
    super.initState();
    _runCtrl =
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
      _score = 0;
      _distance = 0;
      _isPlaying = true;
      _isFinished = false;
      _playerY = _groundY;
      _playerVelY = 0;
      _playerJumping = false;
      _partnerY = _groundY;
      _partnerVelY = 0;
      _partnerJumping = false;
      _objects.clear();
      _gameSpeed = 4;
      _frameCount = 0;
      _coinsEarned = 0;
    });
  }

  void _playerJump() {
    if (!_isPlaying || _playerJumping) return;
    HapticFeedback.lightImpact();
    setState(() {
      _playerVelY = _jumpForce;
      _playerJumping = true;
    });
  }

  void _tick() {
    if (!_isPlaying || !mounted) return;
    setState(() {
      _frameCount++;
      _distance = _frameCount ~/ 10;
      _gameSpeed = 4 + _frameCount / 400;

      // Player physics
      _playerVelY += _gravity;
      _playerY += _playerVelY;
      if (_playerY >= _groundY) {
        _playerY = _groundY;
        _playerVelY = 0;
        _playerJumping = false;
      }

      // Partner AI — auto-jumps when obstacle is close
      _partnerVelY += _gravity;
      _partnerY += _partnerVelY;
      if (_partnerY >= _groundY) {
        _partnerY = _groundY;
        _partnerVelY = 0;
        _partnerJumping = false;
      }
      // Partner auto-jump logic
      final nearObstacle = _objects.any(
        (o) => o.isObstacle && o.x > 80 && o.x < 160 && o.lane == 1,
      );
      if (nearObstacle && !_partnerJumping) {
        _partnerVelY = _jumpForce;
        _partnerJumping = true;
      }

      // Spawn objects
      if (_frameCount % max(45, 90 - _frameCount ~/ 80) == 0) {
        _spawnObject();
      }

      // Move objects
      for (final obj in _objects) {
        obj.x -= _gameSpeed;
      }
      _objects.removeWhere((o) => o.x < -60);

      // Collision
      for (final obj in _objects) {
        if (obj.x > 40 && obj.x < 110) {
          if (obj.lane == 0) {
            // Player lane
            final charBottom = 180 + _playerY;
            final charTop = charBottom - 45;
            final objTop = 180 - obj.height;
            if (charBottom > objTop && charTop < 180) {
              if (obj.isObstacle) {
                _endGame();
                return;
              } else {
                _score += obj.points;
                obj.x = -999;
              }
            }
          } else {
            // Partner lane
            final charBottom = 320 + _partnerY;
            final charTop = charBottom - 45;
            final objTop = 320 - obj.height;
            if (charBottom > objTop && charTop < 320) {
              if (!obj.isObstacle) {
                _score += obj.points ~/ 2;
                obj.x = -999;
              }
            }
          }
        }
      }
    });
  }

  void _spawnObject() {
    final lane = _rng.nextInt(2);
    final isObstacle = _rng.nextDouble() < 0.45;
    if (isObstacle) {
      _objects.add(
        _RaceObject(
          emoji: '💔',
          x: 400,
          height: 40,
          isObstacle: true,
          points: 0,
          lane: lane,
        ),
      );
    } else {
      final items = [
        {'emoji': '❤️', 'pts': 5},
        {'emoji': '💋', 'pts': 10},
        {'emoji': '⭐', 'pts': 15},
        {'emoji': '💎', 'pts': 25},
      ];
      final item = items[_rng.nextInt(items.length)];
      _objects.add(
        _RaceObject(
          emoji: item['emoji'] as String,
          x: 400,
          height: _rng.nextBool() ? 40 : 80,
          isObstacle: false,
          points: item['pts'] as int,
          lane: lane,
        ),
      );
    }
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
      _isFinished = true;
      _coinsEarned = _calcCoins(_score);
    });
    _saveResult();
  }

  int _calcCoins(int score) {
    if (score >= 300) return 40;
    if (score >= 150) return 25;
    if (score >= 60) return 18;
    return 15;
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
    await GameService.instance.recordCoupleGame(_score);
    await GameService.instance.completeChallenge('play_1');
    await GameService.instance.completeChallenge('play_together');
    if (mounted) {
      setState(() {
        _coinsEarned = total;
        if (isRecord) _bestScore = _score;
      });
    }
  }

  @override
  void dispose() {
    _runCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F2FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Carrera de Pareja ❤️🏃',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _isPlaying ? _playerJump : null,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
                ),
              ),
            ),
            // Lane divider
            if (_isPlaying)
              Positioned(
                top: 250,
                left: 0,
                right: 0,
                child: Container(height: 2, color: Colors.white.withAlpha(100)),
              ),
            // Ground lines
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                color: const Color(0xFF1565C0).withAlpha(60),
              ),
            ),
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                color: const Color(0xFF1565C0).withAlpha(40),
              ),
            ),

            if (_isPlaying) ...[
              // Score
              Positioned(
                top: 8,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distancia: $_distance m',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Puntos: $_score',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Player (top lane)
              Positioned(
                left: 60,
                top: 200 - 45 - _playerY,
                child: const Text('🏃', style: TextStyle(fontSize: 36)),
              ),
              // Partner (bottom lane)
              Positioned(
                left: 60,
                top: 340 - 45 - _partnerY,
                child: const Text('🏃‍♀️', style: TextStyle(fontSize: 36)),
              ),
              // Lane labels
              Positioned(
                top: 170,
                left: 20,
                child: Text(
                  'Tú ☝️',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                top: 310,
                left: 20,
                child: Text(
                  'Pareja 🤖',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Objects
              ..._objects.map((obj) {
                final topBase = obj.lane == 0 ? 200.0 : 340.0;
                return Positioned(
                  left: obj.x,
                  top: topBase - obj.height,
                  child: Text(obj.emoji, style: const TextStyle(fontSize: 30)),
                );
              }),
              const Positioned(
                bottom: 60,
                right: 20,
                child: Text(
                  'Toca para saltar ☝️',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A5A5A)),
                ),
              ),
            ],
            if (!_isPlaying) _isFinished ? _buildResult() : _buildStart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStart() {
    return Container(
      color: const Color(0xFFE3F2FD),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏃❤️🏃‍♀️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'Carrera de Pareja',
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para saltar\nTú y tu pareja corren juntos',
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
                backgroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                '¡Correr juntos!',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
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

  Widget _buildResult() {
    final isRecord = _score >= _bestScore && _score > 0;
    return Container(
      color: const Color(0xFFE3F2FD),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRecord
                    ? '🏆 ¡Nuevo Récord de Pareja!'
                    : '❤️ ¡Bien corrido juntos!',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              _row('Distancia de hoy', '$_distance m'),
              _row('Puntuación', '$_score'),
              _row('Récord de pareja', '$_bestScore'),
              _row('LoveCoins ❤️', '+$_coinsEarned'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1565C0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Salir',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF1565C0),
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
                        backgroundColor: const Color(0xFF1565C0),
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

class _RaceObject {
  final String emoji;
  double x;
  final double height;
  final bool isObstacle;
  final int points;
  final int lane; // 0=player, 1=partner
  _RaceObject({
    required this.emoji,
    required this.x,
    required this.height,
    required this.isObstacle,
    required this.points,
    required this.lane,
  });
}
