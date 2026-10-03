import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Initialize Supabase — call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  /// Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user
  User? get currentUser => client.auth.currentUser;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ─────────────────────────────────────────────
  // AUTHENTICATION
  // ─────────────────────────────────────────────

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Sign in with Google (web uses OAuth redirect, mobile uses ID token)
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'https://twohearts1104.builtwithrocket.new',
        );
        return true;
      } else {
        // Native Google Sign-In requires google_sign_in package
        // For now, return false on mobile — can be extended later
        return false;
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // USER PROFILE
  // ─────────────────────────────────────────────

  /// Fetch current user's profile
  Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      debugPrint('getMyProfile error: ${e.message}');
      return null;
    }
  }

  /// Fetch partner's profile
  Future<Map<String, dynamic>?> getPartnerProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      final myProfile = await getMyProfile();
      final partnerId = myProfile?['partner_id'];
      if (partnerId == null) return null;

      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', partnerId)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      debugPrint('getPartnerProfile error: ${e.message}');
      return null;
    }
  }

  /// Update current user's profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await client.from('user_profiles').update(data).eq('id', uid);
  }

  /// Get my invite code
  Future<String?> getMyInviteCode() async {
    final profile = await getMyProfile();
    return profile?['invite_code'] as String?;
  }

  /// Link with partner using their invite code
  Future<String?> linkPartner({
    required String inviteCode,
    DateTime? relationshipStart,
    String connectionType = 'pareja',
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return 'Not authenticated';

    try {
      // Find partner by invite code
      final partnerResult = await client
          .from('user_profiles')
          .select('id, partner_id')
          .eq('invite_code', inviteCode.trim().toUpperCase())
          .maybeSingle();

      if (partnerResult == null) {
        return 'Código no encontrado. Verifica el código e intenta de nuevo.';
      }

      final partnerId = partnerResult['id'] as String;

      if (partnerId == uid) {
        return 'No puedes enlazarte contigo mismo.';
      }

      if (partnerResult['partner_id'] != null) {
        return 'Este usuario ya está enlazado con alguien.';
      }

      // Check if current user already has a partner
      final myProfile = await getMyProfile();
      if (myProfile?['partner_id'] != null) {
        return 'Ya estás enlazado con alguien.';
      }

      final startDate = relationshipStart?.toIso8601String().split('T').first;

      // Link both users
      await client
          .from('user_profiles')
          .update({
            'partner_id': partnerId,
            'connection_type': connectionType,
            if (startDate != null) 'relationship_start': startDate,
          })
          .eq('id', uid);

      await client
          .from('user_profiles')
          .update({
            'partner_id': uid,
            'connection_type': connectionType,
            if (startDate != null) 'relationship_start': startDate,
          })
          .eq('id', partnerId);

      return null; // null = success
    } on PostgrestException catch (e) {
      debugPrint('linkPartner error: ${e.message}');
      return 'Algo salió mal. Por favor intenta de nuevo.';
    }
  }

  /// Set pet type for current user
  Future<void> setPetType(String petType) async {
    await updateProfile({'pet_type': petType});
  }

  /// Get combined couple data (my profile + partner profile)
  Future<Map<String, dynamic>> getCoupleData() async {
    final myProfile = await getMyProfile();
    final partnerProfile = await getPartnerProfile();

    // Priority: nickname > full_name > first part of email (never show full email)
    String displayName(Map<String, dynamic>? profile, String fallback) {
      final nickname = (profile?['nickname'] as String?)?.trim() ?? '';
      if (nickname.isNotEmpty) return nickname;
      final fullName = (profile?['full_name'] as String?)?.trim() ?? '';
      if (fullName.isNotEmpty) return fullName;
      return fallback;
    }

    final myName = displayName(myProfile, 'Tú');
    final partnerName = displayName(partnerProfile, 'Tu pareja');

    final myCity = (myProfile?['city'] as String?)?.isNotEmpty == true
        ? myProfile!['city'] as String
        : '';

    final partnerCity = (partnerProfile?['city'] as String?)?.isNotEmpty == true
        ? partnerProfile!['city'] as String
        : '';

    DateTime startDate = DateTime.now().subtract(const Duration(days: 1));
    if (myProfile?['relationship_start'] != null) {
      try {
        startDate = DateTime.parse(myProfile!['relationship_start'] as String);
      } catch (_) {}
    }

    return {
      'myName': myName,
      'partnerName': partnerName,
      'myCity': myCity,
      'partnerCity': partnerCity,
      'startDate': startDate,
      'petType': myProfile?['pet_type'] ?? 'egg',
      'connectionType': myProfile?['connection_type'] ?? 'pareja',
      'partnerId': myProfile?['partner_id'],
      'inviteCode': myProfile?['invite_code'] ?? '',
    };
  }

  // ─────────────────────────────────────────────
  // NIDO MEMORIES (PHOTOS) — SYNCED
  // ─────────────────────────────────────────────

  /// Get all memories for the current user and their partner
  Future<List<Map<String, dynamic>>> getMemories() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    try {
      final myProfile = await getMyProfile();
      final partnerId = myProfile?['partner_id'] as String?;

      final query = client
          .from('nido_memories')
          .select()
          .order('memory_date', ascending: false);

      final result = await query;
      return List<Map<String, dynamic>>.from(result);
    } on PostgrestException catch (e) {
      debugPrint('getMemories error: ${e.message}');
      return [];
    }
  }

  /// Add a new memory for the current user and their partner
  Future<void> addMemory({
    required String imageUrl,
    required String caption,
    DateTime? memoryDate,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final myProfile = await getMyProfile();
      final partnerId = myProfile?['partner_id'] as String?;
      await client.from('nido_memories').insert({
        'owner_id': uid,
        'partner_id': partnerId,
        'image_url': imageUrl,
        'caption': caption,
        'memory_date': (memoryDate ?? DateTime.now())
            .toIso8601String()
            .split('T')
            .first,
      });
    } on PostgrestException catch (e) {
      debugPrint('addMemory error: ${e.message}');
    }
  }

  /// Delete a memory by its ID
  Future<void> deleteMemory(String memoryId) async {
    try {
      await client.from('nido_memories').delete().eq('id', memoryId);
    } on PostgrestException catch (e) {
      debugPrint('deleteMemory error: ${e.message}');
    }
  }

  /// Real-time stream for memories
  Stream<List<Map<String, dynamic>>> memoriesStream() {
    final uid = currentUser?.id;
    if (uid == null) return const Stream.empty();
    return client
        .from('nido_memories')
        .stream(primaryKey: ['id'])
        .order('memory_date', ascending: false)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  // ─────────────────────────────────────────────
  // NIDO TRIPS — SYNCED
  // ─────────────────────────────────────────────

  /// Get all trips for the current user and their partner
  Future<List<Map<String, dynamic>>> getTrips() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    try {
      final result = await client
          .from('nido_trips')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } on PostgrestException catch (e) {
      debugPrint('getTrips error: ${e.message}');
      return [];
    }
  }

  /// Add a new trip for the current user and their partner
  Future<void> addTrip({
    required String city,
    required String countryEmoji,
    required String tripDate,
    int rating = 5,
    String hotel = '',
    String note = '',
    String imageUrl = '',
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final myProfile = await getMyProfile();
      final partnerId = myProfile?['partner_id'] as String?;
      await client.from('nido_trips').insert({
        'owner_id': uid,
        'partner_id': partnerId,
        'city': city,
        'country_emoji': countryEmoji,
        'trip_date': tripDate,
        'rating': rating,
        'hotel': hotel,
        'note': note,
        'image_url': imageUrl,
      });
    } on PostgrestException catch (e) {
      debugPrint('addTrip error: ${e.message}');
    }
  }

  /// Stream of trips for the current user and their partner
  Stream<List<Map<String, dynamic>>> tripsStream() {
    final uid = currentUser?.id;
    if (uid == null) return const Stream.empty();
    return client
        .from('nido_trips')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  // ─────────────────────────────────────────────
  // NIDO DATES — SYNCED
  // ─────────────────────────────────────────────

  /// Get all dates for the current user and their partner
  Future<List<Map<String, dynamic>>> getDates() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    try {
      final result = await client
          .from('nido_dates')
          .select()
          .order('date_on', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } on PostgrestException catch (e) {
      debugPrint('getDates error: ${e.message}');
      return [];
    }
  }

  /// Add a new date for the current user and their partner
  Future<void> addDate({
    required String title,
    required String description,
    DateTime? dateOn,
    List<String> photos = const [],
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final myProfile = await getMyProfile();
      final partnerId = myProfile?['partner_id'] as String?;
      await client.from('nido_dates').insert({
        'owner_id': uid,
        'partner_id': partnerId,
        'title': title,
        'description': description,
        'date_on': (dateOn ?? DateTime.now())
            .toIso8601String()
            .split('T')
            .first,
        'photos': photos,
      });
    } on PostgrestException catch (e) {
      debugPrint('addDate error: ${e.message}');
    }
  }

  /// Stream of dates for the current user and their partner
  Stream<List<Map<String, dynamic>>> datesStream() {
    final uid = currentUser?.id;
    if (uid == null) return const Stream.empty();
    return client
        .from('nido_dates')
        .stream(primaryKey: ['id'])
        .order('date_on', ascending: false)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  /// Search for a user by email (for pairing)
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      final result = await client
          .from('user_profiles')
          .select('id, full_name, invite_code, partner_id')
          .eq('email', email.trim().toLowerCase())
          .neq('id', uid)
          .maybeSingle();
      if (result == null) return null;
      // Include email in result for display
      return {...result, 'email': email.trim().toLowerCase()};
    } on PostgrestException catch (e) {
      debugPrint('searchUserByEmail error: ${e.message}');
      return null;
    }
  }
}
