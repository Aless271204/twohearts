import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'twohearts_ui.dart';

class AppNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});
  @override
  Widget build(BuildContext context) => HeartNavigation(selected: navigationShell.currentIndex, onSelect: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex));

}
