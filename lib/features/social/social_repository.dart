import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'social_models.dart';

abstract interface class SocialRepository {
  bool get demo;
  String? get userId;
  Stream<String?> get authChanges;
  Future<SocialPage> feed(String mode, {DateTime? before});
  Future<void> publish(
    String type,
    String content,
    bool anonymous,
    String caption,
  );
  Future<SocialPost> like(SocialPost post, bool liked);
  Future<void> follow(String author, bool following);
  Future<List<SocialComment>> comments(String post, {DateTime? before});
  Future<void> comment(String post, String text);
  Future<void> deleteComment(String id);
  Future<void> deletePost(String id);
  Future<void> report(String post, String reason);
  Future<void> block(String post);
  Future<String> upload(Uint8List bytes);
  Future<Uint8List> image(String path);
  Future<void> discardUpload(String path);
}

/// All Social requests go through this repository and the same guarded RPCs.
class SupabaseSocialRepository implements SocialRepository {
  final SupabaseClient client;
  SupabaseSocialRepository(this.client);
  @override
  bool get demo => false;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Stream<String?> get authChanges => client.auth.onAuthStateChange
      .map((event) => event.session?.user.id)
      .distinct();
  @override
  Future<SocialPage> feed(String mode, {DateTime? before}) async {
    final result = Map<String, dynamic>.from(
      await client.rpc(
            'social_feed',
            params: {
              'p_mode': mode,
              'p_before': before?.toUtc().toIso8601String(),
            },
          )
          as Map,
    );
    return SocialPage(
      (result['posts'] as List)
          .map((p) => SocialPost.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      DateTime.parse(result['server_now'] as String).toUtc(),
    );
  }

  @override
  Future<void> publish(
    String type,
    String content,
    bool anonymous,
    String caption,
  ) async {
    await client.rpc(
      'social_create_post',
      params: {
        'p_type': type,
        'p_content': content,
        'p_anonymous': anonymous,
        'p_caption': caption,
      },
    );
  }

  @override
  Future<SocialPost> like(SocialPost post, bool liked) async =>
      SocialPost.fromJson(
        Map<String, dynamic>.from(
          await client.rpc(
                'social_set_like',
                params: {'p_post': post.id, 'p_liked': liked},
              )
              as Map,
        ),
      );
  @override
  Future<void> follow(String author, bool following) async {
    await client.rpc(
      'social_set_follow',
      params: {'p_author': author, 'p_follow': following},
    );
  }

  @override
  Future<List<SocialComment>> comments(String post, {DateTime? before}) async =>
      (await client.rpc(
                'social_comments',
                params: {
                  'p_post': post,
                  'p_before': before?.toUtc().toIso8601String(),
                },
              )
              as List)
          .map(
            (c) => SocialComment.fromJson(Map<String, dynamic>.from(c as Map)),
          )
          .toList();
  @override
  Future<void> comment(String post, String text) async {
    await client.rpc(
      'social_add_comment',
      params: {'p_post': post, 'p_content': text},
    );
  }

  @override
  Future<void> deleteComment(String id) async {
    await client.rpc('social_delete_comment', params: {'p_comment': id});
  }

  @override
  Future<void> deletePost(String id) async {
    await client.rpc('social_delete_post', params: {'p_post': id});
  }

  @override
  Future<void> report(String post, String reason) async {
    await client.rpc(
      'social_report_post',
      params: {'p_post': post, 'p_reason': reason},
    );
  }

  @override
  Future<void> block(String post) async {
    await client.rpc('social_block_post_author', params: {'p_post': post});
  }

  @override
  Future<String> upload(Uint8List bytes) async {
    if (bytes.length > 5 * 1024 * 1024)
      throw const FormatException('Elige una imagen de hasta 5 MB.');
    final extension = imageExtension(bytes);
    final random = Random.secure();
    final name = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final path = '$name.$extension';
    await client.storage
        .from('social-media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: extension == 'jpg' ? 'image/jpeg' : 'image/$extension',
            cacheControl: '0',
            upsert: false,
          ),
        );
    return path;
  }

  // Authenticated reads only: no public or long-lived signed image URLs.
  @override
  Future<Uint8List> image(String path) =>
      client.storage.from('social-media').download(path);
  @override
  Future<void> discardUpload(String path) async {
    await client.storage.from('social-media').remove([path]);
  }
}

String imageExtension(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255)
    return 'jpg';
  if (bytes.length >= 8 &&
      bytes.take(8).join(',') == '137,80,78,71,13,10,26,10')
    return 'png';
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP')
    return 'webp';
  throw const FormatException('Elige una imagen JPG, PNG o WebP.');
}

/// Explicit, isolated demonstration. Never calls Supabase or seeds real accounts.
class DemoSocialRepository implements SocialRepository {
  final List<SocialPost> posts;
  final Map<String, List<SocialComment>> _comments = {};
  DemoSocialRepository([List<Map<String, dynamic>>? preview])
    : posts = preview == null
          ? [
              SocialPost(
                id: 'demo-1',
                name: 'Una pareja de ejemplo',
                type: 'image',
                content: '',
                caption: 'Nuestro rincón favorito, siempre contigo. ♡',
                createdAt: DateTime.now().toUtc().subtract(
                  const Duration(hours: 2),
                ),
                expiresAt: DateTime.now().toUtc().add(
                  const Duration(hours: 22),
                ),
                authorId: 'demo-other',
                likes: 12,
                previewPanel: 0,
              ),
              SocialPost(
                id: 'demo-2',
                name: 'Tu publicación de ejemplo',
                type: 'phrase',
                content: 'Hoy elegimos pasar más tiempo juntos.',
                caption: '',
                createdAt: DateTime.now().toUtc(),
                expiresAt: DateTime.now().toUtc().add(
                  const Duration(hours: 24),
                ),
                mine: true,
                authorId: 'demo-me',
              ),
            ]
          : preview
                .map(
                  (p) => SocialPost.fromJson({
                    ...p,
                    'display_name':
                        (p['user_profiles'] as Map?)?['nickname'] ??
                        'Pareja de ejemplo',
                    'content': p['content'] ?? p['content_text'] ?? '',
                    'expires_at':
                        p['expires_at'] ??
                        DateTime.parse(
                          p['created_at'] as String,
                        ).add(const Duration(hours: 24)).toIso8601String(),
                  }),
                )
                .toList();
  @override
  bool get demo => true;
  @override
  String? get userId => 'demo-me';
  @override
  Stream<String?> get authChanges => const Stream.empty();
  @override
  Future<SocialPage> feed(String mode, {DateTime? before}) async => SocialPage(
    posts
        .where(
          (p) =>
              p.activeAt(DateTime.now().toUtc()) &&
              (before == null || p.createdAt.isBefore(before)),
        )
        .toList(),
    DateTime.now().toUtc(),
  );
  @override
  Future<void> publish(
    String type,
    String content,
    bool anonymous,
    String caption,
  ) async {
    posts.insert(
      0,
      SocialPost(
        id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
        name: anonymous ? 'Anónimo' : 'Tu ejemplo',
        type: type,
        content: content,
        caption: caption,
        createdAt: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 24)),
        mine: true,
        anonymous: anonymous,
        authorId: anonymous ? null : 'demo-me',
      ),
    );
  }

  @override
  Future<SocialPost> like(SocialPost post, bool liked) async {
    final i = posts.indexWhere((p) => p.id == post.id);
    final current = posts[i];
    final updated = current.copy(
      liked: liked,
      likes:
          current.likes +
          (current.liked == liked
              ? 0
              : liked
              ? 1
              : -1),
    );
    posts[i] = updated;
    return updated;
  }

  @override
  Future<void> follow(String author, bool following) async {
    for (var i = 0; i < posts.length; i++) {
      if (posts[i].authorId == author)
        posts[i] = posts[i].copy(following: following);
    }
  }

  @override
  Future<List<SocialComment>> comments(String post, {DateTime? before}) async =>
      (_comments[post] ?? [])
          .where((c) => before == null || c.createdAt.isBefore(before))
          .toList();
  @override
  Future<void> comment(String post, String text) async {
    (_comments[post] ??= []).insert(
      0,
      SocialComment(
        id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
        content: text,
        name: 'Tu ejemplo',
        createdAt: DateTime.now().toUtc(),
        mine: true,
      ),
    );
    final i = posts.indexWhere((p) => p.id == post);
    posts[i] = posts[i].copy(comments: (_comments[post] ?? []).length);
  }

  @override
  Future<void> deleteComment(String id) async {
    for (final e in _comments.entries) {
      e.value.removeWhere((c) => c.id == id);
      final i = posts.indexWhere((p) => p.id == e.key);
      if (i >= 0) posts[i] = posts[i].copy(comments: e.value.length);
    }
  }

  @override
  Future<void> deletePost(String id) async {
    posts.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> report(String post, String reason) async {}
  @override
  Future<void> block(String post) async {
    final author = posts.firstWhere((p) => p.id == post).authorId;
    posts.removeWhere((p) => p.authorId == author);
  }

  @override
  Future<String> upload(Uint8List bytes) async =>
      throw const FormatException('La demostración no sube fotografías.');
  @override
  Future<Uint8List> image(String path) async => Uint8List(0);
  @override
  Future<void> discardUpload(String path) async {}
}
