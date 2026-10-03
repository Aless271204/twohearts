import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class HomeAppBarWidget extends StatelessWidget {
  final String myName;
  final bool hasParter;

  const HomeAppBarWidget({
    super.key,
    required this.myName,
    this.hasParter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hola, ',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                    Text(
                      myName,
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('💕', style: TextStyle(fontSize: 18)),
                  ],
                ),
                Text(
                  hasParter
                      ? 'Tu historia de amor continúa hoy'
                      : '¡Enlaza tu Nido con alguien especial!',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: hasParter
                        ? const Color(0xFF9E9E9E)
                        : AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Show pairing button if no partner
          if (!hasParter) ...[
            GestureDetector(
              onTap: () => context.push(AppRoutes.pairingScreen),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.primary.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪺', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Enlazar',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Notification bell
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE0E8), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'notifications_outlined',
                    color: const Color(0xFF1A1A1A),
                    size: 22,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
