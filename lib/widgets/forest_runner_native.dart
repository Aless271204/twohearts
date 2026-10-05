import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'runner_bridge.dart';

class ForestRunnerView extends StatefulWidget {
  const ForestRunnerView({super.key});
  @override
  State<ForestRunnerView> createState() => _ForestRunnerViewState();
}

class _ForestRunnerViewState extends State<ForestRunnerView> {
  HttpServer? _server;
  WebViewController? _controller;
  String? _error;
  final _bridge = RunnerBridge();
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() => _error = 'Abre este juego en Chrome, Android o iPhone.');
      return;
    }
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      if (!mounted) {
        await server.close(force: true);
        return;
      }
      _server = server;
      server.listen((request) async {
        final path = request.uri.path.substring(1);
        if (!path.startsWith('assets/runner/') || path.contains('..')) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        try {
          final data = await rootBundle.load(path);
          request.response.headers.set(
            'Content-Type',
            path.endsWith('.html')
                ? 'text/html; charset=utf-8'
                : path.endsWith('.js')
                ? 'text/javascript; charset=utf-8'
                : path.endsWith('.json')
                ? 'application/json'
                : 'model/gltf-binary',
          );
          request.response.add(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        } catch (_) {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF17392B));
      await controller.addJavaScriptChannel(
        'RunnerBridge',
        onMessageReceived: (message) async {
          try {
            final response = await _bridge.handle(message.message);
            if (mounted)
              await controller.runJavaScript(
                'window.runnerBridgeResponse(${jsonEncode(response)});',
              );
          } catch (_) {
            /* Ignore messages outside the runner protocol. */
          }
        },
      );
      await controller.loadRequest(
        Uri.parse('http://localhost:${server.port}/assets/runner/index.html'),
      );
      if (mounted) setState(() => _controller = controller);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'No se pudo abrir el bosque. Vuelve a intentarlo.',
        );
    }
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null)
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white)),
      );
    if (_controller == null)
      return const Center(child: CircularProgressIndicator());
    return WebViewWidget(controller: _controller!);
  }
}
