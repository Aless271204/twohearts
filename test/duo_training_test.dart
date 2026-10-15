import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/duo_training.dart';

void main() {
  test('practice paddle returns a hit while a missed ball awards the bot a point', () {
    final game = DuoTraining('pong', seed: 7);
    game.phase = 'play'; game.x = .5; game.y = .879; game.vy = .48;
    game.step(.02, .5);
    expect(game.vy, lessThan(0));
    expect(game.event, 'hit');
    game.x = .8; game.y = 1.03; game.vy = .48;
    game.step(.05, .11);
    expect(game.scoreB, 1);
    expect(game.phase, 'countdown');
    expect(game.snapshot(100)['reward'], 0);
  });
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
  test('quiz practice locks choices and does not let the bot read your secret', () {
    final a = DuoTraining('quiz', seed: 8), b = DuoTraining('quiz', seed: 8);
    a.phase = b.phase = 'self';
    a.choose(0); b.choose(2);
    expect(a.botGuess, b.botGuess);
    expect(a.snapshot(0)['state'], isNot(contains('answer_b')));
    a.choose(a.botSelf!);
    final score = a.scoreA;
    a.choose(1); a.choose(2);
    expect(a.scoreA, score);
    expect(a.phase, 'reveal');
    expect(a.snapshot(0)['reward'], 0);
  });
}
