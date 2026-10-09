import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AppNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});
  static const _tabs = [
    (label: 'Social', icon: Icons.people_outline_rounded),
    (label: 'Tienda', icon: Icons.storefront_outlined),
    (label: 'Nido', icon: Icons.home_outlined),
    (label: 'Mascota', icon: Icons.pets_outlined),
    (label: 'Actividades', icon: Icons.sports_esports_outlined),
  ];
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.paddingOf(context).bottom + 8),
    child: DecoratedBox(
      decoration: BoxDecoration(color: Colors.white.withAlpha(248), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x19BA6D83), blurRadius: 22, offset: Offset(0, 5))]),
      child: SizedBox(height: 72, child: Row(children: [
        for (var index = 0; index < _tabs.length; index++) Expanded(child: Semantics(
          selected: navigationShell.currentIndex == index,
          button: true,
          label: _tabs[index].label,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
            child: Center(child: AnimatedContainer(
              duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
              width: 58, height: 58,
              decoration: BoxDecoration(
                gradient: navigationShell.currentIndex == index ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF6994), AppTheme.primary]) : null,
                borderRadius: BorderRadius.circular(29),
                boxShadow: navigationShell.currentIndex == index ? const [BoxShadow(color: Color(0x33FF407A), blurRadius: 10, offset: Offset(0, 3))] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_tabs[index].icon, size: 22, color: navigationShell.currentIndex == index ? Colors.white : const Color(0xFF676170)),
                const SizedBox(height: 3),
                Text(_tabs[index].label, maxLines: 1, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: navigationShell.currentIndex == index ? Colors.white : const Color(0xFF676170))),
              ]),
            )),
          ),
        )),
      ])),
    ),
  );
}
