import 'package:flutter/material.dart';
import '../../widgets/twohearts_ui.dart';

class NidoWelcomeScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const NidoWelcomeScreen({super.key, required this.onFinished});
  @override
  State<NidoWelcomeScreen> createState() => _NidoWelcomeScreenState();
}

class _NidoWelcomeScreenState extends State<NidoWelcomeScreen> {
  static const titles = [
    'Bienvenidos a Nido',
    'Tu espacio para compartir',
    'Divertirte y amar',
    'Tu lugar seguro y personal',
    'Comparte tu Nido con quien más quieres',
  ];
  final _pages = PageController();
  int _page = 0;
  bool _leaving = false;

  void _finish() {
    if (_leaving) return;
    _leaving = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF8EB),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _finish, child: const Text('Omitir')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: titles.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (_, index) => Image.asset(
                    'assets/images/ui/login-welcome-$index-v4.webp',
                    fit: BoxFit.contain,
                    cacheWidth: 800,
                    semanticLabel: titles[index],
                    errorBuilder: (_, error, stack) => Center(
                      child: Text(titles[index], textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, color: Color(0xFF593F3D))),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [for (int i = 0; i < titles.length; i++)
                    Semantics(
                      label: 'Imagen ${i + 1} de ${titles.length}',
                      selected: _page == i,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 6, width: _page == i ? 24 : 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _page == i ? const Color(0xFFCE536C) : const Color(0xFFD8C5B7),
                          borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: HeartButton(
                  label: _page == titles.length - 1 ? 'Entrar a Nido' : 'Continuar',
                  onPressed: () {
                    if (_page == titles.length - 1) {_finish(); return;}
                    if (MediaQuery.disableAnimationsOf(context)) {
                      _pages.jumpToPage(_page + 1);
                    } else {
                      _pages.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
