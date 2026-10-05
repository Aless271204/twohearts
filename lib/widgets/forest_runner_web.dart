import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'runner_bridge.dart';

class ForestRunnerView extends StatefulWidget {
  const ForestRunnerView({super.key});
  @override
  State<ForestRunnerView> createState() => _ForestRunnerViewState();
}

class _ForestRunnerViewState extends State<ForestRunnerView> {
  static int _nextId = 0;
  late final String _viewType;
  late final web.HTMLIFrameElement _frame;
  late final JSFunction _listener;
  final _bridge = RunnerBridge();
  @override
  void initState() {
    super.initState();
    _viewType = 'forest-runner-${_nextId++}';
    _frame = web.HTMLIFrameElement()
      ..src = Uri.parse(
        web.document.baseURI,
      ).resolve('assets/assets/runner/index.html').toString()
      ..title = 'Corre en pareja: bosque 3D'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
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
  void dispose() {
    web.window.removeEventListener('message', _listener);
    _frame.src = 'about:blank';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
