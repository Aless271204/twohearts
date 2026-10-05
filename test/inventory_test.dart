import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/services/inventory_service.dart';
import 'package:twohearts/core/duo_pong.dart';

void main() {
  test('Inventory color parsing rejects unsafe and malformed styles', () {
    expect(InventoryItem.parseColor('#ef91b4'), const Color(0xFFEF91B4));
    for (final value in [
      'red',
      'javascript:alert(1)',
      '#123',
      ' #FFFFFF',
      null,
      {},
    ])
      expect(InventoryItem.parseColor(value), const Color(0xFF92BDA7));
  });
  test('Opposing phones mirror input while preserving collision limits', () {
    expect(pongToServerX(.25, false), .25);
    expect(pongToServerX(.25, true), .75);
    expect(pongToServerX(-5, false), .11);
    expect(pongToServerX(3, true), .11);
    for (final x in [.11, .25, .5, .75, .89])
      expect(pongFromServer(pongFromServer(x, true), true), closeTo(x, .00001));
  });
  test('Prediction reflects at walls and never advances more than 200ms', () {
    expect(pongBallX(.97, .5, .1), closeTo(.93, .00001));
    expect(pongBallX(.03, -.5, .1), closeTo(.07, .00001));
    expect(pongBallX(.5, .5, 100), pongBallX(.5, .5, .2));
  });
}
