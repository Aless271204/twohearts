import 'dart:math' as math;

int nextQuizStreak(int current, bool correct) =>
    correct ? math.max(0, current) + 1 : math.min(0, current) - 1;

class QuizReaction {
  final String mood, caption, streakLabel;
  final int variation;
  const QuizReaction(this.mood, this.caption, this.streakLabel, this.variation);
  factory QuizReaction.forStreak(int streak, int question, String side) {
    final v = (question + streak.abs() + (side == 'b' ? 1 : 0)) % 3;
    if (streak <= -3) {
      return QuizReaction(
        'angry',
        ['¡Me piqué!', 'Voy por la revancha', '¡Esta la acierto!'][v],
        '${streak.abs()} fallos seguidos',
        v,
      );
    }
    if (streak < 0) {
      return QuizReaction(
        'sad',
        ['Uy, casi…', 'Una pista más', 'A la próxima'][v],
        streak == -2 ? '¡Aún puedo remontar!' : 'Un detalle más que aprender',
        v,
      );
    }
    if (streak >= 3) {
      return QuizReaction(
        'proud',
        ['¡Qué buena racha!', '¡Nos conocemos!', '¡Estoy imparable!'][v],
        '$streak aciertos seguidos',
        v,
      );
    }
    return QuizReaction(
      'happy',
      ['¡Te conozco!', '¡Lo sabía!', '¡Una conexión bonita!'][v],
      streak == 2 ? 'Dos aciertos seguidos' : '+1 acierto',
      v,
    );
  }
}
