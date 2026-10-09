import 'dart:convert';
import 'forest_runner_view.dart';
import '../core/pet_model_catalog.dart';
import '../services/inventory_service.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Pet3DViewer extends StatefulWidget {
  final String modelPath;
  final String altText;
  final bool cameraControls;
  final bool disableZoom;
  final bool autoRotate;
  final bool autoPlay;
  final String? animationName;
  final String? cameraOrbit;
  final ValueChanged<WebViewController>? onWebViewCreated;

  const Pet3DViewer({
    super.key,
    required this.modelPath,
    this.altText = 'Mascota 3D de TwoHearts',
    this.cameraControls = true,
    this.disableZoom = false,
    this.autoRotate = false,
    this.autoPlay = false,
    this.animationName,
    this.cameraOrbit,
    this.onWebViewCreated,
  });

  @override
  State<Pet3DViewer> createState() => _Pet3DViewerState();
}

class _Pet3DViewerState extends State<Pet3DViewer> {
  String? _failure;
  void _report(String message) {
    if (mounted) setState(() => _failure = message);
  }

  @override
  Widget build(BuildContext context) {
    if (_failure != null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              'No pudimos mostrar la mascota.\nVersión 1.1.0\n$_failure',
            ),
          ),
        ),
      );
    }
    if (widget.modelPath == PetModelCatalog.penguinModelPath && widget.onWebViewCreated == null) {
      return ListenableBuilder(listenable: InventoryService.instance, builder: (context, _) {
        final appearance = jsonEncode({for (final entry in InventoryService.instance.loadout.entries)
          entry.key: entry.value.appearance});
        return ForestRunnerView(key: ValueKey('$appearance|${widget.animationName}'), petOnly: true, petOrbit: widget.cameraControls,
          appearance: appearance, animationName: widget.cameraControls ? widget.animationName : 'Natural_Rest');
      });
    }
    return ModelViewer(
      key: ValueKey(
        '${widget.modelPath}|${widget.animationName}|${widget.cameraOrbit}',
      ),
      src: widget.modelPath,
      alt: widget.altText,
      autoPlay: widget.autoPlay,
      animationName: widget.animationName,
      cameraControls: widget.cameraControls,
      disableZoom: widget.disableZoom,
      autoRotate: widget.autoRotate,
      cameraOrbit: widget.cameraOrbit,
      backgroundColor: Colors.transparent,
      interactionPrompt: InteractionPrompt.none,
      loading: Loading.eager,
      ar: false,
      relatedJs: '''
        const reportPet = message => {
          if (window.PetDiagnostics) window.PetDiagnostics.postMessage(String(message).slice(0, 600) + '\\n' + navigator.userAgent);
        };
        window.addEventListener('error', e => reportPet(e.message || 'Error del motor 3D'));
        window.addEventListener('unhandledrejection', e => reportPet(e.reason?.message || e.reason));
        const petViewer = document.querySelector('model-viewer');
        petViewer.addEventListener('error', e => reportPet(e.detail?.sourceError?.message || e.detail?.type || 'No se pudo cargar el modelo'));
        setTimeout(() => { if (!petViewer.loaded) reportPet('La mascota no terminó de cargar en 60 segundos'); }, 60000);
      ''',
      javascriptChannels: {
        JavascriptChannel(
          'PetDiagnostics',
          onMessageReceived: (message) => _report(message.message),
        ),
      },
      onWebViewCreated: (controller) {
        controller.setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (error) {
              final path = Uri.tryParse(error.url ?? '')?.path;
              if (error.isForMainFrame != false ||
                  path == '/model' ||
                  path == '/model-viewer.min.js') {
                _report('${error.errorCode}: ${error.description}');
              }
            },
          ),
        );
        widget.onWebViewCreated?.call(controller);
      },
    );
  }
}
