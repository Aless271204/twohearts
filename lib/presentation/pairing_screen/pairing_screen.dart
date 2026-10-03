import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class PairingScreen extends StatefulWidget {
  /// If true, shown as a modal bottom sheet during onboarding (no back button)
  final bool isOnboarding;
  final VoidCallback? onPaired;

  const PairingScreen({super.key, this.isOnboarding = false, this.onPaired});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // My invite code
  String? _myInviteCode;
  bool _loadingCode = true;
  bool _codeCopied = false;

  // Partner info
  String? _partnerId;
  String? _partnerName;
  bool _isAlreadyPaired = false;

  // Enter code tab
  final _codeController = TextEditingController();
  bool _linkingByCode = false;
  String? _codeError;
  String? _codeSuccess;

  // Search by email tab
  final _emailController = TextEditingController();
  bool _searching = false;
  String? _searchError;
  Map<String, dynamic>? _foundUser;
  bool _linkingFound = false;

  // Connection type
  String _connectionType = 'pareja';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingCode = true);
    try {
      final profile = await SupabaseService.instance.getMyProfile();
      if (mounted) {
        setState(() {
          _myInviteCode = profile?['invite_code'] as String?;
          _partnerId = profile?['partner_id'] as String?;
          _isAlreadyPaired = _partnerId != null;
          _loadingCode = false;
        });
        if (_isAlreadyPaired) {
          _loadPartnerName();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCode = false);
    }
  }

  Future<void> _loadPartnerName() async {
    final partner = await SupabaseService.instance.getPartnerProfile();
    if (mounted && partner != null) {
      setState(() {
        _partnerName = partner['full_name'] as String? ?? 'Tu pareja';
      });
    }
  }

  Future<void> _copyCode() async {
    if (_myInviteCode == null) return;
    await Clipboard.setData(ClipboardData(text: _myInviteCode!));
    setState(() => _codeCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _codeCopied = false);
  }

  Future<void> _linkByCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _codeError = 'Ingresa el código de invitación');
      return;
    }
    setState(() {
      _linkingByCode = true;
      _codeError = null;
      _codeSuccess = null;
    });
    final error = await SupabaseService.instance.linkPartner(
      inviteCode: code,
      connectionType: _connectionType,
    );
    if (mounted) {
      setState(() => _linkingByCode = false);
      if (error != null) {
        setState(() => _codeError = error);
      } else {
        setState(() {
          _codeSuccess = '¡Enlace exitoso! Ya comparten su Nido 🪺';
          _isAlreadyPaired = true;
        });
        _loadPartnerName();
        widget.onPaired?.call();
      }
    }
  }

  Future<void> _searchByEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _searchError = 'Ingresa un correo electrónico');
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
      _foundUser = null;
    });
    try {
      final user = await SupabaseService.instance.searchUserByEmail(email);
      if (mounted) {
        setState(() {
          _searching = false;
          if (user == null) {
            _searchError = 'No se encontró ningún usuario con ese correo.';
          } else {
            _foundUser = user;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _searchError = 'Error al buscar. Intenta de nuevo.';
        });
      }
    }
  }

  Future<void> _linkFoundUser() async {
    if (_foundUser == null) return;
    final inviteCode = _foundUser!['invite_code'] as String?;
    if (inviteCode == null || inviteCode.isEmpty) {
      setState(
        () => _searchError = 'Este usuario aún no tiene código de invitación.',
      );
      return;
    }
    setState(() => _linkingFound = true);
    final error = await SupabaseService.instance.linkPartner(
      inviteCode: inviteCode,
      connectionType: _connectionType,
    );
    if (mounted) {
      setState(() => _linkingFound = false);
      if (error != null) {
        setState(() => _searchError = error);
      } else {
        setState(() {
          _isAlreadyPaired = true;
          _partnerName = _foundUser!['full_name'] as String? ?? 'Tu pareja';
          _foundUser = null;
        });
        widget.onPaired?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              backgroundColor: AppTheme.backgroundLight,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Enlazar Nido',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
      body: _loadingCode
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isOnboarding) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Enlaza tu Nido 🪺',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Conecta con tu pareja, amigo o grupo para compartir recuerdos, mascotas y más.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Already paired banner
                  if (_isAlreadyPaired) ...[
                    _PairedBanner(partnerName: _partnerName),
                    const SizedBox(height: 20),
                  ],

                  // My invite code card
                  _MyCodeCard(
                    inviteCode: _myInviteCode,
                    copied: _codeCopied,
                    onCopy: _copyCode,
                  ),
                  const SizedBox(height: 24),

                  if (!_isAlreadyPaired) ...[
                    // Connection type selector
                    _ConnectionTypeSelector(
                      selected: _connectionType,
                      onChanged: (t) => setState(() => _connectionType = t),
                    ),
                    const SizedBox(height: 20),

                    // Tab: enter code | search email
                    Container(
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
                        unselectedLabelColor: const Color(0xFF6B6B6B),
                        labelStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        tabs: const [
                          Tab(text: 'Ingresar código'),
                          Tab(text: 'Buscar por correo'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 260,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _EnterCodeTab(
                            controller: _codeController,
                            isLoading: _linkingByCode,
                            error: _codeError,
                            success: _codeSuccess,
                            onLink: _linkByCode,
                          ),
                          _SearchEmailTab(
                            controller: _emailController,
                            isSearching: _searching,
                            isLinking: _linkingFound,
                            error: _searchError,
                            foundUser: _foundUser,
                            onSearch: _searchByEmail,
                            onLink: _linkFoundUser,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _PairedBanner extends StatelessWidget {
  final String? partnerName;
  const _PairedBanner({this.partnerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondary.withAlpha(30),
            AppTheme.primary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🪺', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Ya estás enlazado!',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondary,
                  ),
                ),
                if (partnerName != null)
                  Text(
                    'Compartiendo con $partnerName',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF5A5A5A),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.secondary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _MyCodeCard extends StatelessWidget {
  final String? inviteCode;
  final bool copied;
  final VoidCallback onCopy;

  const _MyCodeCard({
    required this.inviteCode,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD6E0), Color(0xFFFFF0F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔑', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Tu código de invitación',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withAlpha(40)),
                  ),
                  child: Text(
                    inviteCode ?? '—',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onCopy,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: copied ? AppTheme.secondary : AppTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    copied ? Icons.check_rounded : Icons.copy_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Comparte este código con tu pareja para que puedan enlazarse.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ConnectionTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {'type': 'pareja', 'emoji': '💑', 'label': 'Pareja'},
      {'type': 'amigo', 'emoji': '🤝', 'label': 'Amigo'},
      {'type': 'grupo', 'emoji': '👥', 'label': 'Grupo'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de conexión',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5A5A5A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = selected == opt['type'];
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opt['type'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        opt['emoji'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt['label'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EnterCodeTab extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? error;
  final String? success;
  final VoidCallback onLink;

  const _EnterCodeTab({
    required this.controller,
    required this.isLoading,
    required this.error,
    required this.success,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresa el código de tu pareja',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
          decoration: InputDecoration(
            hintText: 'Ej: ABCD1234',
            hintStyle: GoogleFonts.dmSans(
              fontSize: 16,
              letterSpacing: 2,
              color: const Color(0xFFBBBBBB),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.vpn_key_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          _StatusMessage(message: error!, isError: true),
        ],
        if (success != null) ...[
          const SizedBox(height: 8),
          _StatusMessage(message: success!, isError: false),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLink,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Enlazar Nido',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SearchEmailTab extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final bool isLinking;
  final String? error;
  final Map<String, dynamic>? foundUser;
  final VoidCallback onSearch;
  final VoidCallback onLink;

  const _SearchEmailTab({
    required this.controller,
    required this.isSearching,
    required this.isLinking,
    required this.error,
    required this.foundUser,
    required this.onSearch,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Busca a tu pareja por correo',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'correo@ejemplo.com',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFBBBBBB),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              width: 52,
              child: ElevatedButton(
                onPressed: isSearching ? null : onSearch,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 20),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          _StatusMessage(message: error!, isError: true),
        ],
        if (foundUser != null) ...[
          const SizedBox(height: 12),
          _FoundUserCard(
            user: foundUser!,
            isLinking: isLinking,
            onLink: onLink,
          ),
        ],
      ],
    );
  }
}

class _FoundUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isLinking;
  final VoidCallback onLink;

  const _FoundUserCard({
    required this.user,
    required this.isLinking,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['full_name'] as String? ?? 'Usuario';
    final email = user['email'] as String? ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryContainer,
            child: Text(
              initials,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF6B6B6B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isLinking ? null : onLink,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: isLinking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Enlazar',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusMessage({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFFFEBEE)
            : AppTheme.secondaryContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? const Color(0xFFEF9A9A)
              : AppTheme.secondary.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 15,
            color: isError ? const Color(0xFFE53935) : AppTheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isError ? const Color(0xFFE53935) : AppTheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
