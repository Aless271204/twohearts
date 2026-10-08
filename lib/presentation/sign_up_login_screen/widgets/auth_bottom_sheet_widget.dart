import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import './pet_selection_widget.dart';

class AuthBottomSheetWidget extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  const AuthBottomSheetWidget({super.key, required this.onAuthSuccess});

  @override
  State<AuthBottomSheetWidget> createState() => _AuthBottomSheetWidgetState();
}

class _AuthBottomSheetWidgetState extends State<AuthBottomSheetWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _partnerCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Signup steps: 0=credentials, 1=connection type, 2=pairing, 3=pet
  int _signupStep = 0;

  String _connectionType = 'pareja'; // pareja | amigo | grupo
  String? _selectedPet;
  DateTime? _relationshipStart;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMessage = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _partnerCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await SupabaseService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) widget.onAuthSuccess();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage = 'Algo salió mal. Por favor intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignupNext() async {
    if (_signupStep == 0) {
      if (!_signupFormKey.currentState!.validate()) return;
      setState(() => _signupStep = 1);
      return;
    }
    if (_signupStep == 1) {
      setState(() => _signupStep = 2);
      return;
    }
    if (_signupStep == 2) {
      setState(() => _signupStep = 3);
      return;
    }
    if (_signupStep == 3) {
      await _finishSignup();
    }
  }

  Future<void> _finishSignup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await SupabaseService.instance.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
      );

      if (response.user == null) {
        setState(
          () => _errorMessage = 'Registro fallido. Por favor intenta de nuevo.',
        );
        return;
      }

      // Set pet type
      if (_selectedPet != null) {
        await SupabaseService.instance.setPetType(_selectedPet!);
      }

      // Link partner if code provided
      final code = _partnerCodeController.text.trim();
      if (code.isNotEmpty) {
        final linkError = await SupabaseService.instance.linkPartner(
          inviteCode: code,
          relationshipStart: _relationshipStart,
          connectionType: _connectionType,
        );
        if (linkError != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enlace: $linkError'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (mounted) {
        widget.onAuthSuccess();
        // If no partner code was entered, navigate to pairing screen after a short delay
        if (code.isEmpty) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              context.push(AppRoutes.pairingScreen);
            }
          });
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage = 'Algo salió mal. Por favor intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final availableHeight = math
        .max(0.0, size.height - viewInsets.bottom)
        .toDouble();
    final preferredTabHeight = _tabController.index == 0
        ? 300.0
        : (_signupStep == 3 ? 420.0 : (_signupStep == 1 ? 340.0 : 320.0));
    final tabContentHeight = math
        .min(
          preferredTabHeight,
          math.max(120.0, availableHeight - 180.0),
        )
        .toDouble();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? size.width * 0.15 : 0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tab bar
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: const [
                      Tab(text: 'Iniciar sesión'),
                      Tab(text: 'Crear cuenta'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Color(0xFFE53935),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tab content
                SizedBox(
                  height: tabContentHeight,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(child: _buildLoginForm()),
                      SingleChildScrollView(child: _buildSignupForm()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _AnimatedFormField(
            controller: _emailController,
            label: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v?.isEmpty ?? true) ? 'Ingresa tu correo' : null,
          ),
          const SizedBox(height: 16),
          _AnimatedFormField(
            controller: _passwordController,
            label: 'Contraseña',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF9E9E9E),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) =>
                (v?.isEmpty ?? true) ? 'Ingresa tu contraseña' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Entrar',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

        ],
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu correo primero.');
      return;
    }
    try {
      await SupabaseService.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correo de recuperación enviado a $email'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'No se pudo enviar el correo. Intenta de nuevo.',
      );
    }
  }

  Widget _buildSignupForm() {
    if (_signupStep == 3) {
      return PetSelectionWidget(
        selectedPet: _selectedPet,
        onPetSelected: (pet) => setState(() => _selectedPet = pet),
        onConfirm: _finishSignup,
        isLoading: _isLoading,
      );
    }

    if (_signupStep == 2) {
      return _buildPairingStep();
    }

    if (_signupStep == 1) {
      return _buildConnectionTypeStep();
    }

    return _buildCredentialsStep();
  }

  Widget _buildCredentialsStep() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          _AnimatedFormField(
            controller: _nameController,
            label: 'Tu nombre',
            validator: (v) => (v?.isEmpty ?? true) ? 'Ingresa tu nombre' : null,
          ),
          const SizedBox(height: 16),
          _AnimatedFormField(
            controller: _emailController,
            label: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v?.isEmpty ?? true) ? 'Ingresa tu correo' : null,
          ),
          const SizedBox(height: 16),
          _AnimatedFormField(
            controller: _passwordController,
            label: 'Contraseña',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF9E9E9E),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) =>
                (v?.length ?? 0) < 12 ? 'Mínimo 12 caracteres' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignupNext,
              child: Text(
                'Continuar',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTypeStep() {
    final options = [
      {
        'type': 'pareja',
        'emoji': '💑',
        'label': 'Pareja',
        'desc': 'Comparte con tu pareja romántica',
      },
      {
        'type': 'amigo',
        'emoji': '🤝',
        'label': 'Mejor amigo',
        'desc': 'Comparte con tu mejor amigo/a',
      },
      {
        'type': 'grupo',
        'emoji': '👥',
        'label': 'Grupo de amigos',
        'desc': 'Comparte con tu grupo',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Con quién quieres compartir tu Nido?',
          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige el tipo de conexión',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((opt) {
          final isSelected = _connectionType == opt['type'];
          return GestureDetector(
            onTap: () =>
                setState(() => _connectionType = opt['type'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    opt['emoji'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['label'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          opt['desc'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _signupStep = 0),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Atrás',
                  style: GoogleFonts.dmSans(color: const Color(0xFF6B6B6B)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _handleSignupNext,
                child: Text(
                  'Continuar',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPairingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enlaza tu Nido',
          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _connectionType == 'pareja'
              ? 'Ingresa el código de tu pareja para conectarse'
              : _connectionType == 'amigo'
              ? 'Ingresa el código de tu mejor amigo/a'
              : 'Ingresa el código de tu grupo',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 20),
        _AnimatedFormField(
          controller: _partnerCodeController,
          label: 'Código de invitación (opcional)',
          keyboardType: TextInputType.text,
          validator: null,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2024, 6, 15),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(
                    context,
                  ).colorScheme.copyWith(primary: AppTheme.primary),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _relationshipStart = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: const Color(0xFF9E9E9E),
                ),
                const SizedBox(width: 12),
                Text(
                  _relationshipStart != null
                      ? 'Desde: ${_relationshipStart!.day}/${_relationshipStart!.month}/${_relationshipStart!.year}'
                      : '¿Cuándo se conocieron?',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: _relationshipStart != null
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer.withAlpha(100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Puedes enlazarte después desde tu perfil si aún no tienes el código.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _signupStep = 1),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Atrás',
                  style: GoogleFonts.dmSans(color: const Color(0xFF6B6B6B)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _handleSignupNext,
                child: Text(
                  'Continuar',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AnimatedFormField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_AnimatedFormField> createState() => _AnimatedFormFieldState();
}

class _AnimatedFormFieldState extends State<_AnimatedFormField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? AppTheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        validator: widget.validator,
        style: GoogleFonts.dmSans(fontSize: 15, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: _isFocused
              ? AppTheme.primaryContainer.withAlpha(77)
              : AppTheme.surfaceVariantLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
          ),
          floatingLabelStyle: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppTheme.primary,
            fontWeight: FontWeight.w500,
          ),
          labelStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }
}
