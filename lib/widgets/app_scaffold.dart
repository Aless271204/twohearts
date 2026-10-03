import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './app_navigation.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class AppScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _muted = false;

  void _toggleMute() async {
    await AudioService.instance.toggleMute();
    setState(() {
      _muted = AudioService.instance.isMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          widget.navigationShell,
          // Floating mute button — top right, subtle
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _muted ? Icons.music_off_rounded : Icons.music_note_rounded,
                  size: 16,
                  color: _muted ? const Color(0xFFBBBBBB) : AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppNavigation(
        navigationShell: widget.navigationShell,
      ),
    );
  }
}
