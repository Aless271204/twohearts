import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:twohearts/core/quiz_reactions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'three consecutive misses cause a cute angry reaction and a success resets the streak',
    () {
      var streak = 0;
      for (var i = 1; i <= 3; i++) {
        streak = nextQuizStreak(streak, false);
        expect(streak, -i);
        expect(
          QuizReaction.forStreak(streak, i, 'a').mood,
          i < 3 ? 'sad' : 'angry',
        );
      }
      streak = nextQuizStreak(streak, true);
      expect(streak, 1);
      expect(QuizReaction.forStreak(streak, 4, 'a').mood, 'happy');
      streak = nextQuizStreak(streak, true);
      streak = nextQuizStreak(streak, true);
      expect(QuizReaction.forStreak(streak, 6, 'a').mood, 'proud');
      expect(nextQuizStreak(streak, false), -1);
    },
  );
  test(
    'repeated streaks rotate gestures and captions deterministically for both phones',
    () {
      final reactions = [
        for (var q = 0; q < 6; q++) QuizReaction.forStreak(-3, q, 'a'),
      ];
      expect(reactions.map((r) => r.caption).toSet().length, 3);
      expect(reactions.map((r) => r.variation).toSet().length, 3);
      expect(
        QuizReaction.forStreak(-3, 2, 'a').caption,
        QuizReaction.forStreak(-3, 2, 'a').caption,
      );
    },
  );
  test('every species has all four packaged emotional portraits', () async {
    for (final species in ['penguin', 'bear', 'pig', 'chick'])
      for (final mood in ['happy', 'sad', 'angry', 'proud'])
        expect(
          (await rootBundle.load(
            'assets/images/ui/quiz-$species-$mood-v1.webp',
          )).lengthInBytes,
          greaterThan(1000),
        );
  });
}
