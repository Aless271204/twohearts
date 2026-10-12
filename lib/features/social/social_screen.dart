import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';
import '../../widgets/twohearts_ui.dart';
import '../../widgets/rose_ui.dart';
import 'social_models.dart';
import 'social_repository.dart';

class SocialScreen extends StatefulWidget {
  final SocialRepository? repository;
  final List<Map<String, dynamic>>? previewPosts;
  const SocialScreen({super.key, this.repository, this.previewPosts});
  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with WidgetsBindingObserver {
  late final SocialRepository repository;
  List<SocialPost> posts = [];
  final Set<String> busy = {};
  String mode = 'friends';
  String? error, account;
  bool loading = true, more = false, loadingMore = false;
  int generation = 0;
  final serverClock = Stopwatch();
  DateTime? serverAnchor;
  Timer? timer;
  StreamSubscription<String?>? auth;
  DateTime get now =>
      serverAnchor?.add(serverClock.elapsed) ?? DateTime.now().toUtc();
  @override
  void initState() {
    super.initState();
    repository =
        widget.repository ??
        (widget.previewPosts != null
            ? DemoSocialRepository(widget.previewPosts)
            : SupabaseSocialRepository(SupabaseService.instance.client));
    account = repository.userId;
    WidgetsBinding.instance.addObserver(this);
    auth = repository.authChanges.listen((uid) {
      if (uid != account && mounted) {
        generation++;
        setState(() {
          account = uid;
          posts = [];
          busy.clear();
          error = null;
          loading = true;
        });
        _load();
      }
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final active = posts.where((p) => p.activeAt(now)).toList();
      if (active.length != posts.length || now.second == 0)
        setState(() => posts = active);
    });
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    final request = ++generation;
    if (repository.userId == null) {
      if (mounted)
        setState(() {
          posts = [];
          loading = false;
          error = 'Inicia sesión para ver y compartir recuerdos.';
        });
      return;
    }
    if (mounted)
      setState(() {
        error = null;
        if (append)
          loadingMore = true;
        else if (posts.isEmpty)
          loading = true;
      });
    try {
      final requestClock = Stopwatch()..start();
      final result = await repository.feed(
        mode,
        before: append && posts.isNotEmpty ? posts.last.createdAt : null,
      );
      if (!mounted || request != generation) return;
      // Advance conservatively by the request duration; a slow response must
      // never prolong the lifetime. A monotonic clock ignores phone date edits.
      serverAnchor = result.serverNow.add(requestClock.elapsed);
      serverClock
        ..reset()
        ..start();
      setState(() {
        final ids = posts.map((p) => p.id).toSet();
        posts = [
          if (append) ...posts,
          ...result.posts.where((p) => !append || !ids.contains(p.id)),
        ].where((p) => p.activeAt(now)).toList();
        more = result.posts.length == 30;
        loading = false;
        loadingMore = false;
      });
    } catch (_) {
      if (mounted && request == generation)
        setState(() {
          loading = false;
          loadingMore = false;
          error =
              'No pudimos cargar Social. Revisa tu conexión y vuelve a intentarlo.';
        });
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _like(SocialPost post) async {
    if (busy.contains(post.id) || !post.activeAt(now)) return;
    final currentGeneration = generation;
    setState(() => busy.add(post.id));
    try {
      final updated = await repository.like(post, !post.liked);
      if (mounted && currentGeneration == generation)
        setState(
          () => posts = posts
              .map((p) => p.id == updated.id ? updated : p)
              .toList(),
        );
    } catch (_) {
      _message('No se guardó el like. Vuelve a intentarlo.');
    } finally {
      if (mounted) setState(() => busy.remove(post.id));
    }
  }

  Future<void> _follow(SocialPost post) async {
    if (post.authorId == null || busy.contains(post.id)) return;
    setState(() => busy.add(post.id));
    try {
      await repository.follow(post.authorId!, !post.following);
      if (mounted) await _load();
    } catch (_) {
      _message('No se guardó el cambio. Vuelve a intentarlo.');
    } finally {
      if (mounted) setState(() => busy.remove(post.id));
    }
  }

  Future<void> _compose() async {
    if (repository.userId == null) {
      _message('Inicia sesión para publicar.');
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SocialComposer(repository: repository),
    );
    if (result == true && mounted) await _load();
  }

  Future<void> _comments(SocialPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SocialCommentsSheet(
        repository: repository,
        post: post,
        now: () => now,
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _menu(SocialPost post, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action == 'delete'
              ? '¿Eliminar publicación?'
              : action == 'block'
              ? '¿Bloquear a esta persona?'
              : '¿Reportar publicación?',
        ),
        content: Text(
          action == 'block'
              ? 'Dejarán de verse sus publicaciones y comentarios.'
              : action == 'delete'
              ? 'Dejará de aparecer en Social.'
              : 'Enviarás este contenido para revisión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (action == 'delete')
        await repository.deletePost(post.id);
      else if (action == 'block')
        await repository.block(post.id);
      else
        await repository.report(post.id, 'other');
      if (mounted) {
        _message(
          action == 'report'
              ? 'Reporte enviado para revisión.'
              : 'Cambio guardado.',
        );
        await _load();
      }
    } catch (_) {
      _message('No se guardó el cambio. Vuelve a intentarlo.');
    }
  }

  void _demo() => Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => SocialScreen(repository: DemoSocialRepository()),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF9FA),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          HeartHeader(
            title: 'Social',
            subtitle: repository.demo
                ? 'Demostración · No se publica nada'
                : 'Recuerdos que viven 24 horas ♡',
            leading: repository.demo
                ? HeartIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Volver',
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            actions: [
              HeartButton(
                label: 'Publicación',
                icon: Icons.add,
                onPressed: _compose,
              ),
            ],
          ),
          if (repository.demo)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Datos de ejemplo. Likes y comentarios solo se guardan durante esta demostración.',
                style: TextStyle(fontSize: 12, color: Color(0xFF716671)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'friends', label: Text('Amigos')),
                ButtonSegment(value: 'discover', label: Text('Descubrir')),
              ],
              selected: {mode},
              onSelectionChanged: (v) {
                setState(() {
                  mode = v.first;
                  posts = [];
                  loading = true;
                });
                _load();
              },
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            ),
          Expanded(
            child: loading
                ? const RoseLoading(label: 'Preparamos sus recuerdos…')
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (posts.isEmpty && error == null) ...[
                          const SizedBox(height: 48),
                          const Icon(
                            Icons.favorite_border_rounded,
                            size: 48,
                            color: Color(0xFFF05280),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            mode == 'friends'
                                ? 'Este espacio también es para ustedes'
                                : 'Sé parte del primer recuerdo',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mode == 'friends'
                                ? 'Aquí verás tus publicaciones y las de quienes sigas. No necesitas esperar a que llegue más gente.'
                                : 'Comparte una frase o una foto. La comunidad podrá verla durante 24 horas.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF716671),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: HeartButton(
                              label: 'Compartir un recuerdo',
                              onPressed: _compose,
                            ),
                          ),
                        ],
                        for (final post in posts) _card(post),
                        if (more)
                          Center(
                            child: TextButton(
                              onPressed: loadingMore
                                  ? null
                                  : () => _load(append: true),
                              child: Text(
                                loadingMore ? 'Cargando…' : 'Ver más recuerdos',
                              ),
                            ),
                          ),
                        if (!repository.demo)
                          Center(
                            child: TextButton.icon(
                              onPressed: _demo,
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Probar una demostración'),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
  Widget _card(SocialPost post) {
    final minutes = post.expiresAt.difference(now).inMinutes.clamp(0, 1440);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFE9EF),
                  child: Icon(
                    post.anonymous
                        ? Icons.person_outline
                        : Icons.favorite_outline,
                    color: const Color(0xFFF05280),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        minutes >= 60
                            ? 'Disponible ${minutes ~/ 60} h ${minutes % 60} min'
                            : 'Disponible $minutes min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF716671),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opciones de publicación',
                  onSelected: (v) => _menu(post, v),
                  itemBuilder: (_) => [
                    if (post.mine)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      )
                    else ...[
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Reportar'),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: Text('Bloquear autor'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (post.type == 'image')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: post.previewPanel != null
                      ? StoryArt(panel: post.previewPanel!)
                      : SocialPrivateImage(
                          repository: repository,
                          path: post.content,
                        ),
                ),
              ),
            ),
          if (post.type != 'image')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                post.content,
                style: TextStyle(
                  fontSize: post.type == 'emoji' ? 34 : 18,
                  height: 1.5,
                  color: const Color(0xFF3B2834),
                ),
              ),
            ),
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Text(post.caption, style: const TextStyle(height: 1.4)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 12, 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: busy.contains(post.id) ? null : () => _like(post),
                  icon: Icon(
                    post.liked ? Icons.favorite : Icons.favorite_outline,
                    color: const Color(0xFFF05280),
                  ),
                  label: Text(
                    '${post.likes}',
                    style: const TextStyle(color: Color(0xFF302A38)),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _comments(post),
                  icon: const Icon(Icons.chat_bubble_outline, size: 21),
                  label: Text(
                    '${post.comments}',
                    style: const TextStyle(color: Color(0xFF302A38)),
                  ),
                ),
                if (!post.mine && !post.anonymous && post.authorId != null)
                  TextButton(
                    onPressed: busy.contains(post.id)
                        ? null
                        : () => _follow(post),
                    child: Text(post.following ? 'Siguiendo' : 'Seguir'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SocialPrivateImage extends StatefulWidget {
  final SocialRepository repository;
  final String path;
  const SocialPrivateImage({
    super.key,
    required this.repository,
    required this.path,
  });
  @override
  State<SocialPrivateImage> createState() => _SocialPrivateImageState();
}

class _SocialPrivateImageState extends State<SocialPrivateImage> {
  late Future<Uint8List> bytes;
  @override
  void initState() {
    super.initState();
    bytes = widget.repository.image(widget.path);
  }

  @override
  void didUpdateWidget(covariant SocialPrivateImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.repository != widget.repository)
      bytes = widget.repository.image(widget.path);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: bytes,
    builder: (_, snapshot) {
      if (snapshot.hasData)
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _unavailable(),
        );
      if (snapshot.hasError) return _unavailable();
      return const ColoredBox(
        color: Color(0xFFFFF0F4),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    },
  );
  Widget _unavailable() => const ColoredBox(
    color: Color(0xFFFFF0F4),
    child: Center(child: Text('Imagen no disponible')),
  );
}

class SocialComposer extends StatefulWidget {
  final SocialRepository repository;
  const SocialComposer({super.key, required this.repository});
  @override
  State<SocialComposer> createState() => _SocialComposerState();
}

class _SocialComposerState extends State<SocialComposer> {
  String? account;
  @override
  void initState() {
    super.initState();
    account = widget.repository.userId;
  }

  final text = TextEditingController(), caption = TextEditingController();
  String type = 'phrase';
  bool anonymous = false, sending = false;
  Uint8List? photo;
  String? error;
  @override
  void dispose() {
    text.dispose();
    caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      imageExtension(bytes);
      if (bytes.length > 5 * 1024 * 1024)
        throw const FormatException('Elige una imagen de hasta 5 MB.');
      if (mounted) setState(() => photo = bytes);
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'No pudimos abrir la imagen. Usa JPG, PNG o WebP de hasta 5 MB.',
        );
    }
  }

  Future<void> _publish() async {
    if (sending) return;
    if (widget.repository.userId != account) {
      setState(
        () => error =
            'La sesión cambió. Cierra esta ventana e inicia sesión de nuevo.',
      );
      return;
    }
    if (type == 'image' ? photo == null : text.text.trim().isEmpty) {
      setState(() => error = 'Añade contenido antes de publicar.');
      return;
    }
    setState(() {
      sending = true;
      error = null;
    });
    String? upload;
    try {
      if (type == 'image') upload = await widget.repository.upload(photo!);
      if (widget.repository.userId != account)
        throw StateError('Session changed');
      await widget.repository.publish(
        type,
        upload ?? text.text.trim(),
        anonymous,
        caption.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      // A timed-out response may have committed the post. Do not delete its
      // image here; that could break a successfully published memory.
      if (mounted)
        setState(
          () => error =
              'No se publicó el recuerdo. Conservamos tu texto; revisa la conexión y reintenta.',
        );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !sending,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Comparte un recuerdo',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.repository.demo
                  ? 'Demostración: nada se enviará a la comunidad.'
                  : 'Visible para la comunidad durante 24 horas. Tu nombre completo, ubicación y datos de pareja no se comparten.',
              style: const TextStyle(color: Color(0xFF716671), height: 1.4),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final e in {
                  'phrase': 'Frase',
                  'emoji': 'Emojis',
                  if (!widget.repository.demo) 'image': 'Foto',
                }.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: type == e.key,
                    onSelected: sending
                        ? null
                        : (_) => setState(() => type = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (type == 'image') ...[
              if (photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    photo!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              TextButton.icon(
                onPressed: sending ? null : _pick,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir fotografía'),
              ),
            ] else
              TextField(
                controller: text,
                enabled: !sending,
                maxLength: 2000,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: type == 'emoji'
                      ? 'Un mensaje con tus emojis favoritos…'
                      : 'Un pensamiento que quieras compartir…',
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: caption,
              enabled: !sending,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Descripción opcional',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publicar sin mostrar mi nombre'),
              value: anonymous,
              onChanged: sending ? null : (v) => setState(() => anonymous = v),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: Color(0xFFA52A50)),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: HeartButton(
                label: sending ? 'Publicando…' : 'Publicar por 24 horas',
                onPressed: sending ? null : _publish,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SocialCommentsSheet extends StatefulWidget {
  final SocialRepository repository;
  final SocialPost post;
  final DateTime Function() now;
  const SocialCommentsSheet({
    super.key,
    required this.repository,
    required this.post,
    required this.now,
  });
  @override
  State<SocialCommentsSheet> createState() => _SocialCommentsSheetState();
}

class _SocialCommentsSheetState extends State<SocialCommentsSheet> {
  String? account;
  final text = TextEditingController();
  List<SocialComment> comments = [];
  bool loading = true, sending = false, more = false;
  String? error;
  Timer? timer;
  bool get expired =>
      !widget.post.activeAt(widget.now()) ||
      widget.repository.userId != account;
  @override
  void initState() {
    super.initState();
    account = widget.repository.userId;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && expired) {
        timer?.cancel();
        setState(() => comments = []);
      }
    });
    _load();
  }

  @override
  void dispose() {
    timer?.cancel();
    text.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    if (expired) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final page = await widget.repository.comments(
        widget.post.id,
        before: append && comments.isNotEmpty ? comments.last.createdAt : null,
      );
      if (mounted && !expired)
        setState(() {
          comments = [if (append) ...comments, ...page];
          loading = false;
          more = page.length == 50;
          error = null;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          loading = false;
          error = 'No pudimos cargar los comentarios.';
        });
    }
  }

  Future<void> _send() async {
    if (sending || expired || text.text.trim().isEmpty) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await widget.repository.comment(widget.post.id, text.text.trim());
      text.clear();
      await _load();
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'No se guardó el comentario. Conservamos tu mensaje.',
        );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _delete(SocialComment comment) async {
    try {
      await widget.repository.deleteComment(comment.id);
      await _load();
    } catch (_) {
      if (mounted) setState(() => error = 'No se pudo eliminar el comentario.');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            .85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comentarios',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (expired)
                const Expanded(
                  child: Center(
                    child: Text('Este recuerdo cumplió sus 24 horas.'),
                  ),
                )
              else
                Expanded(
                  child: loading
                      ? const RoseLoading(label: 'Cargando comentarios…')
                      : ListView(
                          children: [
                            if (comments.isEmpty && error == null)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Deja el primer mensaje bonito. ♡',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            for (final comment in comments)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  comment.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(comment.content),
                                trailing: comment.mine || widget.post.mine
                                    ? IconButton(
                                        tooltip: 'Eliminar comentario',
                                        onPressed: () => _delete(comment),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                      )
                                    : null,
                              ),
                            if (more)
                              TextButton(
                                onPressed: () => _load(append: true),
                                child: const Text('Comentarios anteriores'),
                              ),
                          ],
                        ),
                ),
              if (error != null) ...[
                Text(error!, style: const TextStyle(color: Color(0xFFA52A50))),
                TextButton(onPressed: _load, child: const Text('Reintentar')),
              ],
              if (!expired) ...[
                TextField(
                  controller: text,
                  enabled: !sending,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un comentario…',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: HeartButton(
                    label: sending ? 'Enviando…' : 'Comentar',
                    onPressed: sending ? null : _send,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
