import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/profile_change_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _nicknameCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _currentNickname = '';
  String _currentCity = '';
  String _currentBio = '';
  String _email = '';
  String _connectionType = 'pareja';

  // Mock followers/following (private)
  final List<Map<String, dynamic>> _following = [
    {
      'name': 'Camila & Diego',
      'avatar':
          'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg',
    },
    {
      'name': 'Luna & Andrés',
      'avatar':
          'https://images.pexels.com/photos/1542085/pexels-photo-1542085.jpeg',
    },
  ];

  final List<Map<String, dynamic>> _followers = [
    {
      'name': 'Sofía & Mateo',
      'avatar':
          'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg',
    },
    {
      'name': 'Valentina & Carlos',
      'avatar':
          'https://images.pexels.com/photos/1065084/pexels-photo-1065084.jpeg',
    },
    {
      'name': 'María & José',
      'avatar':
          'https://images.pexels.com/photos/1587009/pexels-photo-1587009.jpeg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.instance.getMyProfile();
      final user = SupabaseService.instance.currentUser;
      if (mounted) {
        setState(() {
          _currentNickname =
              (profile?['nickname'] as String?)?.isNotEmpty == true
              ? profile!['nickname'] as String
              : (profile?['full_name'] as String? ?? '');
          _currentCity = profile?['city'] as String? ?? '';
          _currentBio = profile?['bio'] as String? ?? '';
          _email = user?.email ?? '';
          _connectionType = profile?['connection_type'] as String? ?? 'pareja';
          _nicknameCtrl.text = _currentNickname;
          _cityCtrl.text = _currentCity;
          _bioCtrl.text = _currentBio;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final newNickname = _nicknameCtrl.text.trim();
      final newCity = _cityCtrl.text.trim();
      final newBio = _bioCtrl.text.trim();

      await SupabaseService.instance.updateProfile({
        'nickname': newNickname,
        'city': newCity,
        'bio': newBio,
      });

      if (mounted) {
        setState(() {
          _currentNickname = newNickname;
          _currentCity = newCity;
          _currentBio = newBio;
          _saving = false;
        });

        // Notify app-wide that profile changed
        ProfileChangeNotifier.instance.notify();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Perfil actualizado — tu apodo ya aparece en toda la app',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nicknameCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 24),
                      _buildProfileForm(),
                      const SizedBox(height: 24),
                      _buildConnectionInfo(),
                      const SizedBox(height: 24),
                      _buildSocialSection(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi Perfil',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Datos personales',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _connectionType == 'pareja'
                  ? '💑 Pareja'
                  : _connectionType == 'amigo'
                  ? '🤝 Amigo'
                  : '👥 Grupo',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final initials = _currentNickname.isNotEmpty
        ? _currentNickname.substring(0, 1).toUpperCase()
        : '?';
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFFFF7A9A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.dmSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentNickname.isNotEmpty ? _currentNickname : 'Sin apodo',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          if (_currentCity.isNotEmpty)
            Text(
              '📍 $_currentCity',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos personales',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Apodo / Nickname',
            hint: 'Cómo te llaman en la app',
            controller: _nicknameCtrl,
            icon: Icons.person_outline,
            helperText: 'Este nombre aparecerá en "Nuestro Nido"',
          ),
          const SizedBox(height: 12),
          _buildField(
            label: 'Ciudad',
            hint: 'Tu ciudad actual',
            controller: _cityCtrl,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          _buildField(
            label: 'Bio',
            hint: 'Algo sobre ti...',
            controller: _bioCtrl,
            icon: Icons.edit_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5A5A5A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFFBBBBBB),
            ),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
            filled: true,
            fillColor: AppTheme.surfaceVariantLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            helperText: helperText,
            helperStyle: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionInfo() {
    return Container(
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
      child: Row(
        children: [
          const Text('🔗', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de conexión',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  _connectionType == 'pareja'
                      ? 'Pareja romántica 💑'
                      : _connectionType == 'amigo'
                      ? 'Mejor amigo 🤝'
                      : 'Grupo de amigos 👥',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF5A5A5A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Red social',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 10,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Privado',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSocialStat('${_following.length}', 'Siguiendo'),
              const SizedBox(width: 24),
              _buildSocialStat('${_followers.length}', 'Seguidores'),
            ],
          ),
          const SizedBox(height: 16),
          // Tab bar for following/followers
          Container(
            height: 36,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
              tabs: const [
                Tab(text: 'Siguiendo'),
                Tab(text: 'Seguidores'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPeopleList(_following),
                _buildPeopleList(_followers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleList(List<Map<String, dynamic>> people) {
    if (people.isEmpty) {
      return Center(
        child: Text(
          'Nadie aún',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF9E9E9E),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: people.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(people[i]['avatar'] as String),
              backgroundColor: AppTheme.primaryContainer,
            ),
            const SizedBox(width: 10),
            Text(
              people[i]['name'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Guardar cambios',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
