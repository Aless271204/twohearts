import 'dart:math' as math;

/// Both players see their own paddle at the bottom of the vertical court.
double pongToServerX(double localX, bool sideB) =>
    (sideB ? 1 - localX : localX).clamp(.11, .89).toDouble();
double pongFromServer(double value, bool sideB) => sideB ? 1 - value : value;
double pongBallX(double x, double velocity, double elapsed) {
  final v = x + velocity * elapsed.clamp(0, .20);
  final t = (v - .025) % 1.9;
  return .025 + math.min(t, 1.9 - t);
}
