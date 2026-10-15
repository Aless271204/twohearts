import 'dart:math';

/// Local practice only. No wallet, reward or authenticated mutation is exposed.
class DuoTraining {
  DuoTraining(this.game, {int? seed}) : random = Random(seed) {
    _newQuestion();
  }
  final String game;
  final Random random;
  double time = 0, x = .5, y = .5, vx = .28, vy = .48, bot = .5;
  double target = .5, reaction = 0, deadline = 1;
  int scoreA = 0, scoreB = 0, winsA = 0, winsB = 0, question = 0;
  int? self, guess, botSelf, botGuess;
  bool finished = false;
  String phase = 'countdown';
  String? event;
  static const questions = [
    [
      'Planes',
      '¿Qué plan elegiría Nube?',
      ['Un pícnic', 'Una película', 'Un paseo'],
    ],
    [
      'Viajes',
      '¿Qué paisaje le gustaría explorar?',
      ['Playa', 'Montaña', 'Bosque'],
    ],
    [
      'Comida',
      '¿Qué pediría para cenar?',
      ['Pizza', 'Sushi', 'Pasta'],
    ],
    [
      'Música',
      '¿Qué escucharía en un viaje?',
      ['Pop', 'Rock', 'Instrumental'],
    ],
    [
      'Tiempo libre',
      '¿Qué haría un domingo?',
      ['Leer', 'Cocinar', 'Salir'],
    ],
    [
      'Hogar',
      '¿Qué rincón elegiría?',
      ['Jardín', 'Biblioteca', 'Terraza'],
    ],
    [
      'Aventuras',
      '¿Qué probaría primero?',
      ['Baile', 'Cerámica', 'Fotografía'],
    ],
    [
      'Recuerdos',
      '¿Qué guardaría de un viaje?',
      ['Fotos', 'Artesanía', 'Una postal'],
    ],
  ];
  void _newQuestion() {
    botSelf = random.nextInt(3);
    botGuess = random.nextInt(3);
    self = guess = null;
  }

  void choose(int choice) {
    if (game != 'quiz' || finished || choice < 0 || choice > 2) return;
    if (phase == 'self' && self == null) {
      self = choice;
      phase = 'guess';
      deadline = time + 15;
    } else if (phase == 'guess' && guess == null) {
      guess = choice;
      _reveal();
    }
  }

  void _reveal() {
    if (guess == botSelf) scoreA++;
    if (botGuess == self) scoreB++;
    event = guess == botSelf ? 'score' : 'miss';
    phase = 'reveal';
    deadline = time + 3;
  }

  void step(double dt, double paddle) {
    event = null;
    if (finished || !dt.isFinite || dt <= 0) return;
    final safe = dt.clamp(0, .1).toDouble();
    time += safe;
    if (phase == 'countdown') {
      if (time >= deadline) {
        phase = game == 'pong' ? 'play' : 'self';
        deadline = time + 15;
      }
      return;
    }
    if (game == 'quiz') {
      if (time < deadline) return;
      if (phase == 'self') {
        phase = 'guess';
        deadline = time + 15;
      } else if (phase == 'guess') {
        _reveal();
      } else if (phase == 'reveal') {
        question++;
        if (question >= 5 && (scoreA != scoreB || question >= 8)) {
          finished = true;
          return;
        }
        _newQuestion();
        phase = 'self';
        deadline = time + 15;
      }
      return;
    }
    reaction -= safe;
    if (reaction <= 0) {
      target = (x + (random.nextDouble() - .5) * .28).clamp(.11, .89);
      reaction = .22 + random.nextDouble() * .15;
    }
    bot += (target - bot).clamp(-safe * .62, safe * .62);
    final steps = (safe / .008).ceil();
    final delta = safe / steps;
    for (var i = 0; i < steps; i++) {
      final previous = y;
      x += vx * delta;
      y += vy * delta;
      if (x < .025) {
        x = .05 - x;
        vx = vx.abs();
        event = 'hit';
      }
      if (x > .975) {
        x = 1.95 - x;
        vx = -vx.abs();
        event = 'hit';
      }
      final playerHit =
          vy > 0 &&
          previous < .88 &&
          y >= .88 &&
          (x - paddle.clamp(.11, .89)).abs() < .13;
      final botHit =
          vy < 0 && previous > .12 && y <= .12 && (x - bot).abs() < .13;
      if (playerHit || botHit) {
        y = playerHit ? .88 : .12;
        vy = (playerHit ? -1 : 1) * (vy.abs() * 1.025).clamp(.48, .9);
        vx = ((x - (playerHit ? paddle : bot)) * 3).clamp(-.65, .65);
        event = 'hit';
      }
      if (y < -.04 || y > 1.04) {
        final won = y < 0;
        if (won) {
          scoreA++;
        } else {
          scoreB++;
        }
        event = won ? 'score' : 'miss';
        if (scoreA >= 7 || scoreB >= 7) {
          if (scoreA > scoreB) {
            winsA++;
          } else {
            winsB++;
          }
          if (winsA == 2 || winsB == 2) {
            finished = true;
            return;
          }
          scoreA = scoreB = 0;
        }
        x = y = .5;
        vx = (random.nextBool() ? 1 : -1) * .28;
        vy = won ? -.48 : .48;
        phase = 'countdown';
        deadline = time + 1;
        break;
      }
    }
  }

  Map<String, dynamic> snapshot(double epoch) {
    final q = questions[question % questions.length];
    final winnerA = game == 'pong' ? winsA > winsB : scoreA > scoreB;
    return {
      'id': 'practice',
      'side': 'a',
      'status': finished ? 'finished' : 'playing',
      'winner': game == 'quiz' && scoreA == scoreB
          ? 'practice-draw'
          : winnerA
          ? 'practice-player'
          : 'practice-bot',
      'reward': 0,
      'server_time': epoch,
      'state': {
        'phase': phase,
        'round': winsA + winsB + 1,
        'wins_a': winsA,
        'wins_b': winsB,
        'score_a': scoreA,
        'score_b': scoreB,
        'question_no': question,
        'round_questions': question,
        'x': x,
        'y': y,
        'vx': vx,
        'vy': vy,
        'paddle_b': bot,
        'deadline': epoch + deadline - time,
        'my_choice': phase == 'self'
            ? self
            : phase == 'guess'
            ? guess
            : null,
        'question': {
          'category': q[0],
          'prompt': (q[1] as String).replaceFirst('Nube', 'cada uno'),
          'options': q[2],
        },
        if (phase == 'reveal') ...{
          'answer_a': self,
          'answer_b': botSelf,
          'guess_a': guess,
          'guess_b': botGuess,
        },
      },
    };
  }
}
