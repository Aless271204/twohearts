import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';

/// Minijuego 4 — Love Merge ❤️
/// 2048-style game with romantic symbols
class LoveMergeGame extends StatefulWidget {
  const LoveMergeGame({super.key});
  @override
  State<LoveMergeGame> createState() => _LoveMergeGameState();
}

class _LoveMergeGameState extends State<LoveMergeGame> {
  static const String gameId = 'love_merge';
  static const int gridSize = 4;

  List<List<int>> _grid = [];
  int _score = 0;
  int _bestScore = 0;
  bool _isFinished = false;
  bool _isStarted = false;
  int _coinsEarned = 0;

  // Tile values: 0=empty, 1=❤️, 2=💕, 3=💖, 4=💘, 5=💎
  static const List<String> _emojis = ['', '❤️', '💕', '💖', '💘', '💎', '🌟'];
  static const List<Color> _tileColors = [
    Color(0xFFF5F5F5),
    Color(0xFFFFD6E0),
    Color(0xFFFFB3C6),
    Color(0xFFFF8FAB),
    Color(0xFFFF6B9D),
    Color(0xFFE8547A),
    Color(0xFFB91C5A),
  ];

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final rec = await GameService.instance.getRecord(gameId);
    if (mounted) setState(() => _bestScore = rec?['best_score'] as int? ?? 0);
  }

  void _startGame() {
    setState(() {
      _grid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
      _score = 0;
      _isFinished = false;
      _isStarted = true;
      _coinsEarned = 0;
    });
    _addRandomTile();
    _addRandomTile();
  }

  void _addRandomTile() {
    final empty = <List<int>>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (_grid[r][c] == 0) empty.add([r, c]);
      }
    }
    if (empty.isEmpty) return;
    final pos = empty[Random().nextInt(empty.length)];
    _grid[pos[0]][pos[1]] = 1;
  }

  void _swipe(DragEndDetails details) {
    if (!_isStarted || _isFinished) return;
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;
    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        _move('right');
      } else {
        _move('left');
      }
    } else {
      if (dy > 0) {
        _move('down');
      } else {
        _move('up');
      }
    }
  }

  bool _move(String dir) {
    final prev = _gridCopy();
    bool moved = false;

    if (dir == 'left') {
      for (int r = 0; r < gridSize; r++) {
        final row = _compress(_grid[r]);
        final merged = _merge(row);
        _grid[r] = _compress(merged);
      }
    } else if (dir == 'right') {
      for (int r = 0; r < gridSize; r++) {
        final row = _compress(_grid[r].reversed.toList());
        final merged = _merge(row);
        _grid[r] = _compress(merged).reversed.toList();
      }
    } else if (dir == 'up') {
      for (int c = 0; c < gridSize; c++) {
        final col = List.generate(gridSize, (r) => _grid[r][c]);
        final row = _compress(col);
        final merged = _merge(row);
        final result = _compress(merged);
        for (int r = 0; r < gridSize; r++) {
          _grid[r][c] = result[r];
        }
      }
    } else if (dir == 'down') {
      for (int c = 0; c < gridSize; c++) {
        final col = List.generate(
          gridSize,
          (r) => _grid[r][c],
        ).reversed.toList();
        final row = _compress(col);
        final merged = _merge(row);
        final result = _compress(merged).reversed.toList();
        for (int r = 0; r < gridSize; r++) {
          _grid[r][c] = result[r];
        }
      }
    }

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (_grid[r][c] != prev[r][c]) {
          moved = true;
          break;
        }
      }
    }

    if (moved) {
      HapticFeedback.selectionClick();
      _addRandomTile();
      setState(() {});
      if (_isGameOver()) {
        setState(() {
          _isFinished = true;
          _coinsEarned = _calcCoins(_score);
        });
        _saveResult();
      }
    }
    return moved;
  }

  List<int> _compress(List<int> row) {
    final nonZero = row.where((v) => v != 0).toList();
    while (nonZero.length < gridSize) {
      nonZero.add(0);
    }
    return nonZero;
  }

  List<int> _merge(List<int> row) {
    for (int i = 0; i < gridSize - 1; i++) {
      if (row[i] != 0 && row[i] == row[i + 1]) {
        row[i] = row[i] + 1;
        row[i + 1] = 0;
        _score += row[i] * 10;
      }
    }
    return row;
  }

  List<List<int>> _gridCopy() =>
      List.generate(gridSize, (r) => List.from(_grid[r]));

  bool _isGameOver() {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (_grid[r][c] == 0) return false;
        if (c < gridSize - 1 && _grid[r][c] == _grid[r][c + 1]) return false;
        if (r < gridSize - 1 && _grid[r][c] == _grid[r + 1][c]) return false;
      }
    }
    return true;
  }

  int _calcCoins(int score) {
    if (score >= 500) return 40;
    if (score >= 200) return 25;
    if (score >= 80) return 15;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Love Merge ❤️',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _scoreBox('Puntos', '$_score'),
                const SizedBox(width: 8),
                _scoreBox('Récord', '$_bestScore'),
              ],
            ),
          ),
        ],
      ),
      body: !_isStarted
          ? _buildStart()
          : _isFinished
          ? _buildResult()
          : _buildGame(),
    );
  }

  Widget _scoreBox(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 9, color: AppTheme.primary),
          ),
          Text(
            val,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return GestureDetector(
      onHorizontalDragEnd: _swipe,
      onVerticalDragEnd: _swipe,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Desliza para combinar ❤️+❤️=💕',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF5A5A5A),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(
                    gridSize,
                    (r) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        gridSize,
                        (c) => _buildTile(_grid[r][c]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildChallenges(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int val) {
    final color = val < _tileColors.length
        ? _tileColors[val]
        : _tileColors.last;
    final emoji = val < _emojis.length ? _emojis[val] : _emojis.last;
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
    );
  }

  Widget _buildChallenges() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desafíos',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          _challengeRow('Consigue una pieza 💖', _hasLevel(3)),
          _challengeRow('Supera 1.000 puntos', _score >= 1000),
          _challengeRow('Llega a 💎', _hasLevel(5)),
        ],
      ),
    );
  }

  bool _hasLevel(int level) {
    for (final row in _grid) {
      if (row.contains(level)) return true;
    }
    return false;
  }

  Widget _challengeRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: done ? AppTheme.secondary : const Color(0xFF9E9E9E),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: done ? AppTheme.secondary : const Color(0xFF5A5A5A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('❤️💕💖💘💎', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 16),
          Text(
            'Love Merge',
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Combina corazones\n❤️+❤️=💕  💕+💕=💖  💖+💖=💘',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              '¡Jugar!',
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
              color: AppTheme.primary.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isRecord ? '🏆 ¡Nuevo Récord!' : '🎉 ¡Bien jugado!',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _row('Puntuación', '$_score'),
            _row('Récord', '$_bestScore'),
            _row('LoveCoins ❤️', '+$_coinsEarned'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Salir',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.primary,
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
                      backgroundColor: AppTheme.primary,
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
