// Isolated Android host for the unchanged NIDO WebGL renderer and original GLBs.
// No account, store, game rules or original pet assets are changed here.
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FitReview extends StatefulWidget {
  final Completer<WebViewController> ready;
  const FitReview(this.ready, {super.key});
  @override
  State<FitReview> createState() => _FitReviewState();
}

class _FitReviewState extends State<FitReview> {
  HttpServer? server;
  WebViewController? controller;
  @override
  void initState() {
    super.initState();
    open();
  }

  Future<void> open() async {
    final host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server = host;
    host.listen((request) async {
      final path = request.uri.path;
      if (!path.startsWith('/assets/runner/') || path.contains('..')) {
        request.response.statusCode = 404;
        await request.response.close();
        return;
      }
      try {
        final data = await rootBundle.load(path.substring(1));
        final ext = path.split('.').last;
        request.response.headers.set('Content-Type', switch (ext) {
          'js' => 'text/javascript',
          'json' => 'application/json',
          'html' => 'text/html',
          'css' => 'text/css',
          'png' => 'image/png',
          'webp' => 'image/webp',
          'glb' => 'model/gltf-binary',
          _ => 'application/octet-stream',
        });
        request.response.add(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } catch (_) {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });
    final view = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    await view.loadRequest(
      Uri.parse('http://127.0.0.1:${host.port}/assets/runner/index.html?pet=1'),
    );
    if (!mounted) return;
    setState(() => controller = view);
    widget.ready.complete(view);
  }

  @override
  void dispose() {
    server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: controller!),
    ),
  );
}

void main() => runApp(FitReview(Completer<WebViewController>()));
