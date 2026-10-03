import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CoupleHeaderWidget extends StatelessWidget {
  final String myName;
  final String partnerName;
  final int daysTogether;
  final int distanceKm;
  final String myCity;
  final String partnerCity;

  const CoupleHeaderWidget({
    super.key,
    required this.myName,
    required this.partnerName,
    required this.daysTogether,
    required this.distanceKm,
    required this.myCity,
    required this.partnerCity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withAlpha(20),
              AppTheme.secondary.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withAlpha(31), width: 1),
        ),
        child: Column(
          children: [
            // Names row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  myName,
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('❤️', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                Text(
                  partnerName,
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '$daysTogether',
                    label: 'Days Together',
                    emoji: '📅',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: '${(distanceKm / 1000).toStringAsFixed(1)}k',
                    label: 'km Apart',
                    emoji: '✈️',
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: '${(daysTogether / 7).floor()}',
                    label: 'Weeks',
                    emoji: '🗓️',
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Location row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(179),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📍', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    myCity,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 1,
                      height: 12,
                      color: const Color(0xFFE0E0E0),
                    ),
                  ),
                  const Text('📍', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    partnerCity,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFF6B6B6B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
