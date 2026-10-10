import '../core/feature_flags.dart';
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'runner_bridge.dart';

class ForestRunnerView extends StatefulWidget {
  final VoidCallback? onExit;
  final VoidCallback? onPetStroke;
  final bool petOnly;
  final int petReaction;
  final String petSpecies;
  final int petLevel;
  final bool petOrbit;
  final String? appearance;
  final String? animationName;
  const ForestRunnerView({
    super.key,
    this.onExit,
    this.onPetStroke,
    this.petOnly = false,
    this.petReaction = 0,
    this.petSpecies = 'penguin',
    this.petLevel = 10,
    this.petOrbit = false,
    this.appearance,
    this.animationName,
  });
  @override
  State<ForestRunnerView> createState() => _ForestRunnerViewState();
}

class _ForestRunnerViewState extends State<ForestRunnerView>
    with WidgetsBindingObserver {
  static int _nextId = 0;
  late final String _viewType;
  late final web.HTMLIFrameElement _frame;
  late final JSFunction _listener;
  final _bridge = RunnerBridge();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewType = 'forest-runner-${_nextId++}';
    _frame = web.HTMLIFrameElement()
      ..src = Uri.parse(web.document.baseURI)
          .resolve('assets/assets/runner/index.html')
          .replace(
            queryParameters: widget.petOnly
                ? {
                    'pet': '1',
                    'species': widget.petSpecies,
                    'level': (FeatureFlags.petGrowth ? widget.petLevel : 10)
                        .toString(),
                    'orbit': widget.petOrbit ? '1' : '0',
                    'appearance': widget.appearance ?? '{}',
                    'animation': widget.animationName ?? 'Idle_9',
                  }
                : {
                    'species': widget.petSpecies,
                    'level': (FeatureFlags.petGrowth ? widget.petLevel : 10)
                        .toString(),
                  },
          )
          .toString()
      ..title = 'Corre en pareja: bosque 3D'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    _updatePointerPolicy();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _frame);
    _listener = ((web.Event event) {
      final message = event as web.MessageEvent;
      if (message.origin != Uri.base.origin ||
          message.source != _frame.contentWindow)
        return;
      final data = message.data.dartify();
      if (data is String) _handleMessage(data);
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  Future<void> _handleMessage(String raw) async {
    try {
      if (widget.petOnly && jsonDecode(raw)['type'] == 'pet-stroke') {
        widget.onPetStroke?.call();
        return;
      }
      if (!widget.petOnly && jsonDecode(raw)['type'] == 'runner-exit') {
        widget.onExit?.call();
        return;
      }
      final response = await _bridge.handle(raw);
      if (mounted)
        _frame.contentWindow?.postMessage(
          jsonEncode(response).toJS,
          Uri.base.origin.toJS,
        );
    } catch (_) {
      /* Ignore messages outside the runner protocol. */
    }
  }

  @override
  void didUpdateWidget(covariant ForestRunnerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePointerPolicy();
    if (widget.petOnly && widget.petReaction != oldWidget.petReaction)
      _frame.contentWindow?.postMessage(
        'pet-stroke'.toJS,
        Uri.base.origin.toJS,
      );
  }

  void _updatePointerPolicy() {
    // Static shop previews must let scrolling reach the Flutter list.
    _frame.style.pointerEvents =
        widget.petOnly && !widget.petOrbit && widget.onPetStroke == null
        ? 'none'
        : 'auto';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _frame.contentWindow?.postMessage(
      (state == AppLifecycleState.resumed ? 'runner-resume' : 'runner-suspend')
          .toJS,
      Uri.base.origin.toJS,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frame.contentWindow?.postMessage(
      'runner-suspend'.toJS,
      Uri.base.origin.toJS,
    );
    web.window.removeEventListener('message', _listener);
    _frame.src = 'about:blank';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
