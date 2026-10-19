import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/duo_training.dart';

void main() {
  test(
    'each quiz answer has five seconds of reactions and a two-second next-question intro',
    () {
      final game = DuoTraining('quiz', seed: 3)..phase = 'self';
      game.choose(0);
      game.choose(1);
      expect(game.phase, 'reveal');
      expect(game.deadline - game.time, 5);
      for (var i = 0; i < 49; i++) {
        game.step(.1, .5);
      }
      expect(game.phase, 'reveal');
      for (var i = 0; i < 2; i++) {
        game.step(.1, .5);
      }
      expect(game.phase, 'question_intro');
      expect(game.question, 1);
      expect(game.snapshot(0)['state'], isNot(contains('answer_a')));
      game.choose(2);
      expect(game.self, isNull);
      for (var i = 0; i < 21; i++) {
        game.step(.1, .5);
      }
      expect(game.phase, 'self');
      expect(game.deadline - game.time, closeTo(20, .11));
    },
  );
  test('quiz grants twenty seconds for both secret and guess answers', () {
    final game = DuoTraining('quiz', seed: 3);
    for (var i = 0; i < 11; i++) game.step(.1, .5);
    expect(game.phase, 'self');
    expect(game.deadline - game.time, closeTo(20, .11));
    for (var i = 0; i < 160; i++) game.step(.1, .5);
    expect(game.phase, 'self');
    game.choose(1);
    expect(game.phase, 'guess');
    expect(game.deadline - game.time, 20);
    for (var i = 0; i < 160; i++) game.step(.1, .5);
    expect(game.phase, 'guess');
    for (var i = 0; i < 41; i++) game.step(.1, .5);
    expect(game.phase, 'reveal');
  });
  test(
    'spark and calm affect travel temporarily without changing the base velocity',
    () {
      for (final kind in [3, 4]) {
        final game = DuoTraining('pong', seed: 4)
          ..phase = 'play'
          ..powerClock = 8.1
          ..powerNumber = 1
          ..powerKind = kind
          ..powerX = .5
          ..lastHit = 0
          ..x = .5
          ..y = .5;
        game.step(.01, .5);
        expect(game.tempoKind, kind);
        expect(game.tempoRemaining, 4);
        final vx = game.vx, vy = game.vy, y = game.y;
        game.step(.05, .5);
        expect(game.y - y, closeTo(vy * .05 * (kind == 3 ? 1.3 : .72), .0001));
        expect(game.vx, vx);
        game.tempoRemaining = .01;
        game.step(.02, .5);
        expect(game.tempoRate, 1);
        expect(game.tempoKind, 0);
        expect(game.snapshot(1)['reward'], 0);
      }
    },
  );
  test('practice power-ups enlarge paddle and shield saves only one miss', () {
    final game = DuoTraining('pong', seed: 9)
      ..phase = 'play'
      ..powerClock = 8.1
      ..powerNumber = 1
      ..powerKind = 1
      ..powerX = .5
      ..lastHit = 0
      ..x = .5
      ..y = .5;
    game.step(.01, .5);
    expect(game.wideA, greaterThan(5));
    expect(game.powerKind, 0);
    game.shieldA = true;
    game.y = .979;
    game.vy = 1;
    game.step(.025, .1);
    expect(game.vy, lessThan(0));
    expect(game.shieldA, isFalse);
    expect(game.scoreB, 0);
    expect(game.snapshot(1)['reward'], 0);
  });
  test(
    'practice paddle returns a hit while a missed ball awards the bot a point',
    () {
      final game = DuoTraining('pong', seed: 7);
      game.phase = 'play';
      game.x = .5;
      game.y = .879;
      game.vy = .48;
      game.step(.02, .5);
      expect(game.vy, lessThan(0));
      expect(game.event, 'hit');
      game.x = .8;
      game.y = 1.03;
      game.vy = .48;
      game.step(.05, .11);
      expect(game.scoreB, 1);
      expect(game.phase, 'countdown');
      expect(game.snapshot(100)['reward'], 0);
    },
  );
  test('practice bot stays bounded and a match reaches a result', () {
    final game = DuoTraining('pong', seed: 42);
    for (var frame = 0; frame < 40000 && !game.finished; frame++) {
      game.step(.033, .11);
      expect(game.bot, inInclusiveRange(.11, .89));
      expect(game.x.isFinite && game.y.isFinite, isTrue);
    }
    expect(game.finished, isTrue);
    expect(game.winsA == 2 || game.winsB == 2, isTrue);
  });
  test(
    'quiz practice locks choices and does not let the bot read your secret',
    () {
      final a = DuoTraining('quiz', seed: 8), b = DuoTraining('quiz', seed: 8);
      a.phase = b.phase = 'self';
      a.choose(0);
      b.choose(2);
      expect(a.botGuess, b.botGuess);
      expect(a.snapshot(0)['state'], isNot(contains('answer_b')));
      a.choose(a.botSelf!);
      final score = a.scoreA;
      a.choose(1);
      a.choose(2);
      expect(a.scoreA, score);
      expect(a.phase, 'reveal');
      expect(a.snapshot(0)['reward'], 0);
    },
  );
}
