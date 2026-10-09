import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './app_navigation.dart';

class AppScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});
  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}
class _AppScaffoldState extends State<AppScaffold> with SingleTickerProviderStateMixin {
  bool _modeOpen = false;
  late final AnimationController _transition;
  late int _branch;
  @override
  void initState() {
    super.initState();
    _branch = widget.navigationShell.currentIndex;
    _transition = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: 1);
  }
  @override
  void didUpdateWidget(AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_branch != widget.navigationShell.currentIndex) {
      _branch = widget.navigationShell.currentIndex;
      if (MediaQuery.disableAnimationsOf(context)) { _transition.value = 1; }
      else { _transition.forward(from: 0); }
    }
  }
  @override
  void dispose() { _transition.dispose(); super.dispose(); }
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
      body: FadeTransition(opacity: CurvedAnimation(parent: _transition, curve: Curves.easeOut), child: widget.navigationShell),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
        child: _modeOpen ? const SizedBox.shrink() : AppNavigation(navigationShell: widget.navigationShell),
      ),
    ),
  );
}
