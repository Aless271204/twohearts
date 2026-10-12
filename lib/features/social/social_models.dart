class SocialPost {
  final String id, name, type, content, caption;
  final String? authorId;
  final DateTime createdAt, expiresAt;
  final int likes, comments;
  final bool anonymous, mine, liked, following;
  final int? previewPanel;
  const SocialPost({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.authorId,
    this.likes = 0,
    this.comments = 0,
    this.anonymous = false,
    this.mine = false,
    this.liked = false,
    this.following = false,
    this.previewPanel,
  });
  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
    id: json['id'] as String,
    name: json['display_name'] as String? ?? 'Pareja',
    type: json['content_type'] as String? ?? 'phrase',
    content: json['content'] as String? ?? '',
    caption: json['caption'] as String? ?? '',
    authorId: json['author_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
    likes: json['likes_count'] as int? ?? 0,
    comments: json['comments_count'] as int? ?? 0,
    anonymous: json['is_anonymous'] == true,
    mine: json['is_mine'] == true,
    liked: json['liked'] == true,
    following: json['following'] == true,
    previewPanel: json['preview_panel'] as int?,
  );
  bool activeAt(DateTime now) => now.isBefore(expiresAt);
  SocialPost copy({bool? liked, bool? following, int? likes, int? comments}) =>
      SocialPost(
        id: id,
        name: name,
        type: type,
        content: content,
        caption: caption,
        createdAt: createdAt,
        expiresAt: expiresAt,
        authorId: authorId,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        anonymous: anonymous,
        mine: mine,
        liked: liked ?? this.liked,
        following: following ?? this.following,
        previewPanel: previewPanel,
      );
}

class SocialComment {
  final String id, content, name;
  final DateTime createdAt;
  final bool mine;
  const SocialComment({
    required this.id,
    required this.content,
    required this.name,
    required this.createdAt,
    this.mine = false,
  });
  factory SocialComment.fromJson(Map<String, dynamic> json) => SocialComment(
    id: json['id'] as String,
    content: json['content'] as String,
    name: json['display_name'] as String? ?? 'Pareja',
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    mine: json['is_mine'] == true,
  );
}

class SocialPage {
  final List<SocialPost> posts;
  final DateTime serverNow;
  const SocialPage(this.posts, this.serverNow);
}
