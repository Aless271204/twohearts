import '../core/memory_photo_reference.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class MemoryAlbum {
  final String id;
  final String userId;
  final String coupleId;
  final String albumName;
  final String description;
  final String category;
  final List<String> photoUrls;
  final String? spotifyTrackId;
  final String? spotifyTrackName;
  final String? spotifyArtistName;
  final String? spotifyPreviewUrl;
  final DateTime createdAt;

  const MemoryAlbum({
    required this.id,
    required this.userId,
    required this.coupleId,
    required this.albumName,
    required this.description,
    this.category = 'general',
    required this.photoUrls,
    this.spotifyTrackId,
    this.spotifyTrackName,
    this.spotifyArtistName,
    this.spotifyPreviewUrl,
    required this.createdAt,
  });

  factory MemoryAlbum.fromJson(Map<String, dynamic> json) {
    return MemoryAlbum(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      coupleId: json['couple_id'] as String,
      albumName: json['album_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      photoUrls:
          (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      spotifyTrackId: json['spotify_track_id'] as String?,
      spotifyTrackName: json['spotify_track_name'] as String?,
      spotifyArtistName: json['spotify_artist_name'] as String?,
      spotifyPreviewUrl: json['spotify_preview_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class MemoryAlbumService {
  static MemoryAlbumService? _instance;
  static MemoryAlbumService get instance =>
      _instance ??= MemoryAlbumService._();
  MemoryAlbumService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _currentUserId => SupabaseService.instance.currentUser?.id;

  /// Get couple_id for current user
  Future<String?> _getCoupleId() async {
    final uid = _currentUserId;
    if (uid == null) return null;
    try {
      final result = await _client.rpc(
        'get_couple_id_for_user',
        params: {'uid': uid},
      );
      return result as String?;
    } catch (_) {
      debugPrint('getCoupleId no disponible.');
      return uid;
    }
  }

  /// Fetch all albums for the couple
  Future<List<MemoryAlbum>> getAlbums() async {
    try {
      final response = await _client
          .from('memory_albums')
          .select()
          .order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((e) => MemoryAlbum.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      debugPrint('getAlbums no disponible.');
      return [];
    } catch (_) {
      debugPrint('getAlbums no disponible.');
      return [];
    }
  }

  /// Stream of albums for real-time updates
  Stream<List<MemoryAlbum>> albumsStream() {
    if (_currentUserId == null) return Stream.value(const <MemoryAlbum>[]);
    return _client
        .from('memory_albums')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((e) => MemoryAlbum.fromJson(e)).toList());
  }

  /// Create a new album
  Future<String?> createAlbum({
    required String albumName,
    String? expectedUserId,
    String category = 'general',
    required String description,
    required List<String> photoUrls,
    String? spotifyTrackId,
    String? spotifyTrackName,
    String? spotifyArtistName,
    String? spotifyPreviewUrl,
  }) async {
    if (albumName.trim().isEmpty) return 'El nombre del álbum es requerido';
    if (photoUrls.isEmpty) return 'Agrega al menos una foto';
    if (photoUrls.length > 5) return 'Máximo 5 fotos por álbum';
    final uid = _currentUserId;
    if (uid == null) return 'No autenticado';
    if (expectedUserId != null && expectedUserId != uid) {
      return 'Tu sesión cambió. Vuelve a abrir el álbum.';
    }

    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'No se pudo obtener el ID de pareja';
      if (_currentUserId != uid) {
        return 'Tu sesión cambió. Vuelve a abrir el álbum.';
      }

      await _client.from('memory_albums').insert({
        'user_id': uid,
        'couple_id': coupleId,
        'album_name': albumName.trim(),
        'category': category,
        'description': description.trim(),
        'photo_urls': photoUrls,
        if (spotifyTrackId != null) 'spotify_track_id': spotifyTrackId,
        if (spotifyTrackName != null) 'spotify_track_name': spotifyTrackName,
        if (spotifyArtistName != null) 'spotify_artist_name': spotifyArtistName,
        if (spotifyPreviewUrl != null) 'spotify_preview_url': spotifyPreviewUrl,
      });
      return null; // success
    } on PostgrestException {
      debugPrint('createAlbum no disponible.');
      return 'No pudimos crear el álbum. Revisa la conexión e inténtalo de nuevo.';
    } catch (_) {
      debugPrint('createAlbum no disponible.');
      return 'Error al crear el álbum';
    }
  }

  /// Delete an album
  Future<String?> deleteAlbum(String albumId) async {
    try {
      final uid = _currentUserId;
      if (uid == null) return 'Inicia sesión para eliminar el álbum';
      final album = await _client
          .from('memory_albums')
          .select('user_id,photo_urls')
          .eq('id', albumId)
          .maybeSingle();
      if (album == null || album['user_id'] != uid)
        return 'Solo puedes eliminar tus álbumes';
      await _client
          .from('memory_albums')
          .delete()
          .eq('id', albumId)
          .eq('user_id', uid);
      // Do not delete a photo reused by another accessible album.
      try {
        final remaining = await _client
            .from('memory_albums')
            .select('photo_urls');
        final references = <String>{
          for (final row in remaining)
            for (final photo in (row['photo_urls'] as List? ?? []))
              if (memoryPhotoPath(photo.toString(), SupabaseService.supabaseUrl)
                  case final String path)
                path,
        };
        final unused = <String>[
          for (final photo in (album['photo_urls'] as List? ?? []))
            if (memoryPhotoPath(photo.toString(), SupabaseService.supabaseUrl)
                case final String path)
              if (path.startsWith('albums/$uid/') && !references.contains(path))
                path,
        ];
        if (unused.isNotEmpty)
          await _client.storage.from('memory-photos').remove(unused);
      } catch (_) {
        debugPrint('La limpieza de fotos requiere reintento.');
      }
      return null;
    } on PostgrestException {
      debugPrint('deleteAlbum no disponible.');
      return 'Error al eliminar el álbum';
    }
  }
}
