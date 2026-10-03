import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import './custom_icon_widget.dart';

class _TabSpec {
  final String label;
  final String icon;
  final String selectedIcon;
  final int branchIndex;
  final String? petEmoji;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.branchIndex,
    this.petEmoji,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Tab order: Social | Tienda | Nuestro Nido (center) | Mascota | Actividades
  final List<_TabSpec> _tabs = const [
    _TabSpec(
      label: 'Social',
      icon: 'people_outline',
      selectedIcon: 'people',
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Tienda',
      icon: 'storefront_outlined',
      selectedIcon: 'storefront',
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Nido',
      icon: 'home_outlined',
      selectedIcon: 'home',
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Mascota',
      icon: 'pets',
      selectedIcon: 'pets',
      branchIndex: 3,
      petEmoji: '🐾',
    ),
    _TabSpec(
      label: 'Actividades',
      icon: 'explore_outlined',
      selectedIcon: 'explore',
      branchIndex: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _selectedVisualIndex => widget.navigationShell.currentIndex;

  void _onTabTap(int visualIndex) {
    widget.navigationShell.goBranch(
      visualIndex,
      initialLocation: visualIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(38),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sliding capsule indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: _capsuleLeft(context),
              child: Container(
                width: _capsuleWidth(),
                height: 44,
                decoration: BoxDecoration(
                  color: _selectedVisualIndex == 2
                      ? AppTheme.secondary
                      : AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            // Tab items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final isActive = i == _selectedVisualIndex;
                final isCenterTab = i == 2;
                return GestureDetector(
                  onTap: () => _onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: _tabWidth(context),
                    height: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pet tab shows emoji thumbnail instead of icon
                        if (i == 3 && !isActive)
                          Text('🐾', style: TextStyle(fontSize: 20))
                        else if (i == 3 && isActive)
                          Text('🐾', style: TextStyle(fontSize: 20))
                        else if (i == 2)
                          // Center tab — house icon
                          Icon(
                            isActive ? Icons.home_rounded : Icons.home_outlined,
                            color: isActive
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            size: 26,
                          )
                        else
                          CustomIconWidget(
                            iconName: isActive
                                ? _tabs[i].selectedIcon
                                : _tabs[i].icon,
                            color: isActive
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            size: isCenterTab ? 24 : 22,
                          ),
                        if (isActive) ...[
                          const SizedBox(height: 2),
                          Text(
                            _tabs[i].label,
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  double _tabWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - 40) / _tabs.length;
  }

  double _capsuleWidth() => 68;

  double _capsuleLeft(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalWidth = screenWidth - 40;
    final tabW = totalWidth / _tabs.length;
    return (_selectedVisualIndex * tabW) + (tabW / 2) - (_capsuleWidth() / 2);
  }
}
