import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/quiz_reactions.dart';

class QuizReactionCard extends StatelessWidget {
  final String species, name, answer, expected;
  final bool correct;
  final QuizReaction reaction;
  final Animation<double> animation;
  const QuizReactionCard({
    super.key,
    required this.species,
    required this.name,
    required this.answer,
    required this.expected,
    required this.correct,
    required this.reaction,
    required this.animation,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: correct ? const Color(0xFFF0F7ED) : const Color(0xFFFFEEE8),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: correct ? const Color(0xFFB4D0B2) : const Color(0xFFE3B7B3),
      ),
    ),
    child: Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF493744),
          ),
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (_, child) {
            final wave = math.sin(animation.value * math.pi * 2),
                angry = reaction.mood == 'angry';
            return Transform.translate(
              offset: Offset(
                angry ? wave * (2 + reaction.variation) : 0,
                correct
                    ? -wave.abs() * (3 + reaction.variation * 2)
                    : wave * 1.5,
              ),
              child: Transform.rotate(
                angle:
                    wave *
                    (angry
                        ? .035
                        : correct
                        ? .025
                        : .012),
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/images/ui/quiz-$species-${reaction.mood}-v1.webp',
            height: 154,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 18,
              color: correct
                  ? const Color(0xFF46714B)
                  : const Color(0xFFAD4E57),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                correct ? '¡Acertó!' : 'No acertó',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: correct
                      ? const Color(0xFF315C38)
                      : const Color(0xFF993E4C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: Text(
            reaction.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF563D50),
            ),
          ),
        ),
        Text(
          reaction.streakLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6A5060)),
        ),
        const Divider(height: 18),
        Text(
          'Pensó: $answer',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 11, color: Color(0xFF69525E)),
        ),
        Text(
          'Era: $expected',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF493744),
          ),
        ),
      ],
    ),
  );
}
