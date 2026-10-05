import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'runner_bridge.dart';
import '../core/local_asset_path.dart';

class ForestRunnerView extends StatefulWidget {
  final ValueChanged<WebViewController>? onWebViewCreated;
  const ForestRunnerView({super.key, this.onWebViewCreated});
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
        final path = runnerAssetPath(request.uri);
        if (path == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        try {
          final data = await rootBundle.load(path);
          request.response.contentLength = data.lengthInBytes;
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
        } catch (error) {
          debugPrint('Forest asset load failed ($path): $error');
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF17392B));
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame != false && mounted) {
              setState(
                () => _error =
                    'No se pudo abrir el bosque.\nVersión 1.1.0\n${error.errorCode}: ${error.description}',
              );
            }
          },
        ),
      );
      if (controller.platform is AndroidWebViewController) {
        await (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }
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
      if (mounted) widget.onWebViewCreated?.call(controller);
    } catch (error) {
      if (mounted)
        setState(
          () => _error = 'No se pudo abrir el bosque.\nVersión 1.1.0\n$error',
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
