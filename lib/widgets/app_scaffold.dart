import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './app_navigation.dart';

class AppScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});
  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}
class _AppScaffoldState extends State<AppScaffold> {
  bool _modeOpen = false;
  @override
  Widget build(BuildContext context) => NotificationListener<NavigationNotification>(
    onNotification: (notification) {
      final next = notification.canHandlePop;
      if (next != _modeOpen) WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && next != _modeOpen) setState(() => _modeOpen = next);
      });
      return false;
    },
    child: Scaffold(
      extendBody: false,
      body: widget.navigationShell,
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
        child: _modeOpen ? const SizedBox.shrink() : AppNavigation(navigationShell: widget.navigationShell),
      ),
    ),
  );
}
