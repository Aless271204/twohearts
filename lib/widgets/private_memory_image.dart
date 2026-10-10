import 'rose_ui.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// Stable object references are persisted; short lived access URLs are not.
export '../core/memory_photo_reference.dart';
import '../core/memory_photo_reference.dart';

class PrivateMemoryImage extends StatefulWidget {
  final String source;
  final double? width, height;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  const PrivateMemoryImage(this.source, {super.key, this.width, this.height,
    this.fit, this.errorBuilder, this.loadingBuilder});
  @override
  State<PrivateMemoryImage> createState() => _PrivateMemoryImageState();
}

class _PrivateMemoryImageState extends State<PrivateMemoryImage> {
  late Future<String> _url;
  Timer? _refresh;
  StreamSubscription<dynamic>? _auth;
  @override
  void initState() {
    super.initState(); _url = _resolve();
    _refresh = Timer.periodic(const Duration(minutes: 4), (_) {
      if (mounted) setState(() => _url = _resolve());
    });
    _auth = SupabaseService.instance.authStateChanges.listen((_) {
      if (mounted) setState(() => _url = _resolve());
    });
  }
  @override
  void dispose() { _refresh?.cancel(); _auth?.cancel(); super.dispose(); }
  @override
  void didUpdateWidget(PrivateMemoryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _url = _resolve();
  }
  Future<String> _resolve() async {
    final path = memoryPhotoPath(widget.source, SupabaseService.supabaseUrl);
    if (path == null) {
      if (widget.source.startsWith('memory-photo:')) throw StateError('Invalid photo');
      return widget.source;
    }
    if (SupabaseService.instance.currentUser == null) throw StateError('Inicia sesión');
    return SupabaseService.instance.client.storage.from('memory-photos').createSignedUrl(path, 300);
  }
  @override
  Widget build(BuildContext context) => widget.source.startsWith("twohearts-preview:") ? SizedBox(width:widget.width,height:widget.height,child:StoryArt(panel:int.tryParse(widget.source.split(":").last)??0)) : FutureBuilder<String>(
    future: _url,
    builder: (context, state) {
      if (state.hasError) return widget.errorBuilder?.call(context, state.error!, null)
        ?? SizedBox(width: widget.width, height: widget.height, child: const Icon(Icons.lock_outline));
      if (!state.hasData) return SizedBox(width: widget.width, height: widget.height,
        child: const Center(child: CircularProgressIndicator()));
      return Image.network(state.data!, width: widget.width, height: widget.height,
        fit: widget.fit, errorBuilder: widget.errorBuilder, loadingBuilder: widget.loadingBuilder);
    },
  );
}
