import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Real DB data
  List<Map<String, dynamic>> _recentPosts = [];
  List<Map<String, dynamic>> _discoverPosts = [];
  Set<String> _followingIds = {};
  Set<String> _likedPostIds = {};
  bool _loadingRecent = true;
  bool _loadingDiscover = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadFollowing(), _loadDiscoverPosts()]);
    await _loadRecentPosts();
  }

  Future<void> _loadFollowing() async {
    try {
      final uid = SupabaseService.instance.currentUser?.id;
      if (uid == null) return;
      final rows = await SupabaseService.instance.client
          .from('social_follows')
          .select('following_id')
          .eq('follower_id', uid);
      if (mounted) {
        setState(() {
          _followingIds = Set<String>.from(
            (rows as List).map((r) => r['following_id'] as String),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRecentPosts() async {
    try {
      final uid = SupabaseService.instance.currentUser?.id;
      if (uid == null) {
        if (mounted) setState(() => _loadingRecent = false);
        return;
      }
      // Posts from people the current user follows (within 24h)
      final cutoff = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String();

      List<Map<String, dynamic>> posts = [];
      if (_followingIds.isNotEmpty) {
        final rows = await SupabaseService.instance.client
            .from('social_posts')
            .select(
              '*, user_profiles!social_posts_author_id_fkey(nickname, full_name, city)',
            )
            .inFilter('author_id', _followingIds.toList())
            .gte('created_at', cutoff)
            .order('created_at', ascending: false)
            .limit(30);
        posts = List<Map<String, dynamic>>.from(rows as List);
      }

      // Load liked post ids
      final likes = await SupabaseService.instance.client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', uid);
      final likedIds = Set<String>.from(
        (likes as List).map((r) => r['post_id'] as String),
      );

      if (mounted) {
        setState(() {
          _recentPosts = posts;
          _likedPostIds = likedIds;
          _loadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  Future<void> _loadDiscoverPosts() async {
    try {
      // Most popular posts (by interaction_count) within 24h
      final cutoff = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      final rows = await SupabaseService.instance.client
          .from('social_posts')
          .select(
            '*, user_profiles!social_posts_author_id_fkey(nickname, full_name, city)',
          )
          .gte('created_at', cutoff)
          .order('interaction_count', ascending: false)
          .limit(30);
      if (mounted) {
        setState(() {
          _discoverPosts = List<Map<String, dynamic>>.from(rows as List);
          _loadingDiscover = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDiscover = false);
    }
  }

  Future<void> _toggleFollow(String targetUserId) async {
    final uid = SupabaseService.instance.currentUser?.id;
    if (uid == null) return;
    final isFollowing = _followingIds.contains(targetUserId);
    setState(() {
      if (isFollowing) {
        _followingIds.remove(targetUserId);
      } else {
        _followingIds.add(targetUserId);
      }
    });
    try {
      if (isFollowing) {
        await SupabaseService.instance.client
            .from('social_follows')
            .delete()
            .eq('follower_id', uid)
            .eq('following_id', targetUserId);
      } else {
        await SupabaseService.instance.client.from('social_follows').insert({
          'follower_id': uid,
          'following_id': targetUserId,
        });
      }
    } catch (_) {
      // Revert on error
      setState(() {
        if (isFollowing) {
          _followingIds.add(targetUserId);
        } else {
          _followingIds.remove(targetUserId);
        }
      });
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final uid = SupabaseService.instance.currentUser?.id;
    if (uid == null) return;
    final postId = post['id'] as String;
    final isLiked = _likedPostIds.contains(postId);
    setState(() {
      if (isLiked) {
        _likedPostIds.remove(postId);
      } else {
        _likedPostIds.add(postId);
      }
    });
    try {
      if (isLiked) {
        await SupabaseService.instance.client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', uid);
      } else {
        await SupabaseService.instance.client.from('post_likes').insert({
          'post_id': postId,
          'user_id': uid,
        });
      }
    } catch (_) {
      setState(() {
        if (isLiked) {
          _likedPostIds.add(postId);
        } else {
          _likedPostIds.remove(postId);
        }
      });
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }

  String _expiresIn(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final expiry = dt.add(const Duration(hours: 24));
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return 'Expirado';
    if (remaining.inHours > 0) {
      return 'Expira en ${remaining.inHours}h ${remaining.inMinutes % 60}m';
    }
    return 'Expira en ${remaining.inMinutes}m';
  }

  double _expiryProgress(String? createdAt) {
    if (createdAt == null) return 0;
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return 0;
    final elapsed = DateTime.now().difference(dt).inMinutes;
    return (elapsed / (24 * 60)).clamp(0.0, 1.0);
  }

  String _getDisplayName(Map<String, dynamic> post) {
    if (post['is_anonymous'] == true) return 'Anónimo 🌸';
    final profile = post['user_profiles'] as Map<String, dynamic>?;
    final nick = profile?['nickname'] as String?;
    final full = profile?['full_name'] as String?;
    return (nick?.isNotEmpty == true ? nick : full) ?? 'Pareja';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildRecentFeed(), _buildDiscoverFeed()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Social',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Comparte recuerdos 🌍',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(999),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          labelStyle: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Conocidos'),
            Tab(text: 'Descubrir'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFeed() {
    if (_loadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recentPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💑', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Sigue a personas para ver sus recuerdos',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: const Color(0xFF9E9E9E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Las publicaciones duran 24 horas',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: _recentPosts.length,
        itemBuilder: (context, index) => _buildPostCard(_recentPosts[index]),
      ),
    );
  }

  Widget _buildDiscoverFeed() {
    if (_loadingDiscover) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_discoverPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Aún no hay publicaciones populares',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '¡Sé el primero en compartir un recuerdo!',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDiscoverPosts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: _discoverPosts.length,
        itemBuilder: (context, index) => _buildPostCard(_discoverPosts[index]),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final createdAt = post['created_at'] as String?;
    final progress = _expiryProgress(createdAt);
    final type = post['content_type'] as String? ?? 'phrase';
    final isAnon = post['is_anonymous'] as bool? ?? false;
    final authorId = post['author_id'] as String?;
    final isLiked = _likedPostIds.contains(post['id'] as String? ?? '');
    final likesCount = post['likes_count'] as int? ?? 0;
    final commentsCount = post['comments_count'] as int? ?? 0;
    final interactionCount = post['interaction_count'] as int? ?? 0;
    final displayName = _getDisplayName(post);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 24h expiry progress bar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: LinearProgressIndicator(
              value: 1.0 - progress,
              backgroundColor: Colors.grey.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress < 0.5 ? AppTheme.primary : Colors.orange,
              ),
              minHeight: 3,
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                isAnon ? _buildAnonAvatar() : _buildUserAvatar(post),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _timeAgo(createdAt),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: progress < 0.75
                                  ? AppTheme.primaryContainer
                                  : Colors.orange.withAlpha(30),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _expiresIn(createdAt),
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: progress < 0.75
                                    ? AppTheme.primary
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (interactionCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB347).withAlpha(30),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Text(
                          '$interactionCount',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE07000),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Content
          if (type == 'image' && post['content_url'] != null)
            _buildImageContent(post),
          if (type == 'phrase') _buildPhraseContent(post),
          if (type == 'gif') _buildGifContent(post),
          // Caption
          if (post['caption'] != null && (post['caption'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                post['caption'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF2A2A2A),
                  height: 1.5,
                ),
              ),
            ),
          // Actions row — follow button is HERE on the post card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                _buildActionBtn(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${isLiked ? likesCount + 1 : likesCount}',
                  color: isLiked ? AppTheme.primary : const Color(0xFF9E9E9E),
                  onTap: () => _toggleLike(post),
                ),
                const SizedBox(width: 20),
                _buildActionBtn(
                  icon: Icons.chat_bubble_outline,
                  label: '$commentsCount',
                  color: const Color(0xFF9E9E9E),
                  onTap: () {},
                ),
                const Spacer(),
                // Follow button on each post card
                if (!isAnon &&
                    authorId != null &&
                    authorId != SupabaseService.instance.currentUser?.id)
                  _buildFollowButton(authorId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(String userId) {
    final isFollowing = _followingIds.contains(userId);
    return GestureDetector(
      onTap: () => _toggleFollow(userId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isFollowing ? AppTheme.surfaceVariantLight : AppTheme.primary,
          borderRadius: BorderRadius.circular(999),
          border: isFollowing
              ? Border.all(color: const Color(0xFFDDDDDD))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowing ? Icons.check : Icons.person_add_outlined,
              size: 12,
              color: isFollowing ? const Color(0xFF6B6B6B) : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              isFollowing ? 'Siguiendo' : 'Seguir',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isFollowing ? const Color(0xFF6B6B6B) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> post) {
    final profile = post['user_profiles'] as Map<String, dynamic>?;
    final nick = profile?['nickname'] as String?;
    final full = profile?['full_name'] as String?;
    final name = (nick?.isNotEmpty == true ? nick : full) ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFFFF7A9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(Map<String, dynamic> post) {
    return ClipRRect(
      child: Image.network(
        post['content_url'] as String,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: 'Imagen compartida por la pareja',
        errorBuilder: (_, __, ___) =>
            Container(height: 200, color: AppTheme.surfaceVariantLight),
      ),
    );
  }

  Widget _buildPhraseContent(Map<String, dynamic> post) {
    final content =
        post['content_text'] as String? ?? post['content'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(20),
            AppTheme.secondary.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Text(
        content,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          color: const Color(0xFF2A2A2A),
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildGifContent(Map<String, dynamic> post) {
    final content = post['content_text'] as String? ?? '🎭';
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(content, style: const TextStyle(fontSize: 60))),
    );
  }

  Widget _buildAnonAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8547A), Color(0xFFFF8FAB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreatePostSheet(),
      backgroundColor: AppTheme.primary,
      elevation: 4,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Compartir',
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePostSheet(onPosted: _loadData),
    );
  }
}

// ── Create Post Sheet ────────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  final VoidCallback? onPosted;
  const _CreatePostSheet({this.onPosted});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  bool _isAnon = false;
  String _selectedType = 'phrase';
  final TextEditingController _phraseCtrl = TextEditingController();
  final TextEditingController _imageUrlCtrl = TextEditingController();
  bool _posting = false;

  final List<Map<String, dynamic>> _types = [
    {'id': 'phrase', 'emoji': '💬', 'label': 'Frase'},
    {'id': 'image', 'emoji': '📷', 'label': 'Imagen'},
    {'id': 'gif', 'emoji': '🎭', 'label': 'GIF'},
  ];

  Future<void> _publish() async {
    final uid = SupabaseService.instance.currentUser?.id;
    if (uid == null) return;
    final content = _selectedType == 'image'
        ? _imageUrlCtrl.text.trim()
        : _phraseCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _posting = true);
    try {
      await SupabaseService.instance.client.from('social_posts').insert({
        'author_id': uid,
        'content_type': _selectedType,
        if (_selectedType == 'image') 'content_url': content,
        if (_selectedType != 'image') 'content_text': content,
        'is_anonymous': _isAnon,
        'interaction_count': 0,
        'likes_count': 0,
        'comments_count': 0,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onPosted?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Nueva publicación',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            '⏰ Expira en 24 horas automáticamente',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tipo de contenido (solo uno)',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _types.map((t) {
              final isSelected = _selectedType == t['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t['emoji'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t['label'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_selectedType == 'phrase')
            TextField(
              controller: _phraseCtrl,
              maxLines: 4,
              maxLength: 280,
              decoration: InputDecoration(
                hintText: 'Escribe una frase, pensamiento o recuerdo... 💕',
                hintStyle: GoogleFonts.dmSans(
                  color: const Color(0xFFBBBBBB),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariantLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          if (_selectedType == 'image')
            TextField(
              controller: _imageUrlCtrl,
              decoration: InputDecoration(
                hintText: 'URL de la imagen',
                hintStyle: GoogleFonts.dmSans(
                  color: const Color(0xFFBBBBBB),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.image_outlined,
                  color: AppTheme.primary,
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariantLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          if (_selectedType == 'gif')
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '🎭 Escribe el emoji o texto del GIF',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isAnon = !_isAnon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isAnon
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAnon ? Icons.lock : Icons.lock_open,
                        size: 14,
                        color: _isAnon
                            ? AppTheme.primary
                            : const Color(0xFF9E9E9E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isAnon ? 'Anónimo' : 'Con nombre',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isAnon
                              ? AppTheme.primary
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _posting ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: _posting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Publicar',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
