import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
class CoupleHeaderWidget extends StatelessWidget {
  final String myName, partnerName, myCity, partnerCity;
  final int daysTogether, distanceKm;
  const CoupleHeaderWidget({super.key, required this.myName, required this.partnerName, required this.daysTogether, required this.distanceKm, required this.myCity, required this.partnerCity});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Column(children: [
    Row(children: [
      Expanded(child: _stat(Icons.favorite_outline_rounded, '$daysTogether', 'Días juntos', AppTheme.primaryContainer)),
      const SizedBox(width: 10), Expanded(child: _stat(Icons.near_me_outlined, '${(distanceKm / 1000).toStringAsFixed(1)}k', 'km de distancia', const Color(0xFFEAF4EE))),
      const SizedBox(width: 10), Expanded(child: _stat(Icons.calendar_month_outlined, '${(daysTogether / 7).floor()}', 'Semanas', const Color(0xFFFFF0E7))),
    ]),
    if (myCity.isNotEmpty || partnerCity.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text([myCity, partnerCity].where((c) => c.isNotEmpty).join('  ·  '), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF716B78)))),
  ]));
  Widget _stat(IconData icon, String value, String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14), decoration: BoxDecoration(color: color.withAlpha(220), borderRadius: BorderRadius.circular(18)), child: Column(children: [Icon(icon,size:22,color:const Color(0xFF755161)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF716B78)))]));
}
