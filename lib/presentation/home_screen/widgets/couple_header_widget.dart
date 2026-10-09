import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
class CoupleHeaderWidget extends StatelessWidget {
  final String myName, partnerName, myCity, partnerCity;
  final int daysTogether, distanceKm;
  const CoupleHeaderWidget({super.key, required this.myName, required this.partnerName, required this.daysTogether, required this.distanceKm, required this.myCity, required this.partnerCity});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Column(children: [
    if (myName.isNotEmpty || partnerName.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text([myName, partnerName].where((n) => n.isNotEmpty).join('  ♡  '), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
    Row(children: [
      Expanded(child: _stat('📅', '$daysTogether', 'Días juntos', AppTheme.primaryContainer)),
      const SizedBox(width: 10), Expanded(child: _stat('✈️', '${(distanceKm / 1000).toStringAsFixed(1)}k', 'km de distancia', const Color(0xFFEAF4EE))),
      const SizedBox(width: 10), Expanded(child: _stat('🗓️', '${(daysTogether / 7).floor()}', 'Semanas', const Color(0xFFFFF0E7))),
    ]),
    if (myCity.isNotEmpty || partnerCity.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text([myCity, partnerCity].where((c) => c.isNotEmpty).join('  ·  '), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF716B78)))),
  ]));
  Widget _stat(String icon, String value, String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)), child: Column(children: [Text(icon, style: const TextStyle(fontSize: 22)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF716B78)))]));
}
