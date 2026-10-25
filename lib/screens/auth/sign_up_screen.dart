import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// MRCAS Sports Management System - Sign Up / Registration Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _registerNumberCtrl = TextEditingController();
  final _employeeIdCtrl = TextEditingController();

  // Form state
  String _selectedRole = 'Sports Staff';
  String _selectedDepartment = 'Physical Education';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  final List<String> _roles = ['Sports Staff'];
  final List<String> _departments = [
    'Physical Education',
    'Sports Science',
    'B.A. English',
    'B.Com',
    'B.Sc CS',
    'B.Sc Mathematics',
    'B.Sc Physics',
    'B.Sc Chemistry',
    'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _registerNumberCtrl.dispose();
    _employeeIdCtrl.dispose();
    super.dispose();
  }

  // ── Password strength checker ────────────────────────────────────────────
  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password);
  }

  PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) score++;
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    if (score == 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions to continue.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      department: _selectedDepartment,
      role: _selectedRole,
      password: _passwordCtrl.text,
      registerNumber: _registerNumberCtrl.text.trim(),
      employeeId: _employeeIdCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Navigate to email verification screen
      context.go(
        '/auth/verify-email',
        extra: {
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'Registration failed. Please try again.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final Color primary = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final Color secondary = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final Color onBg = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackgroundLight;
    final Color surfaceBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);

    final bool isWide = size.width >= 900;

    return Scaffold(
      backgroundColor: surfaceBg,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0F172A),
                          const Color(0xFF1E1B4B),
                          const Color(0xFF0F172A),
                        ]
                      : [
                          const Color(0xFFEFF6FF),
                          const Color(0xFFF8FAFC),
                          const Color(0xFFEDE9FE),
                        ],
                ),
              ),
            ),
          ),
          // Decorative blob
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondary.withValues(alpha: isDark ? 0.12 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: isWide
                ? _buildWideLayout(context, primary, secondary, onBg, isDark)
                : _buildNarrowLayout(context, primary, secondary, onBg, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    Color primary,
    Color secondary,
    Color onBg,
    bool isDark,
  ) {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BackButton(onBg: onBg),
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/mrcas_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.shield_rounded, color: primary, size: 38),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Your\nMRCAS Account',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: primary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Register to access the MRCAS Sports Management portal. All fields marked with * are required.',
                  style: TextStyle(
                    fontSize: 14,
                    color: onBg.withValues(alpha: 0.6),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                _buildRoleInfo(primary, secondary, onBg, isDark),
              ],
            ),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 5,
          child: _buildFormPanel(
            context,
            primary,
            secondary,
            onBg,
            isDark,
            scrolled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    Color primary,
    Color secondary,
    Color onBg,
    bool isDark,
  ) {
    return _buildFormPanel(
      context,
      primary,
      secondary,
      onBg,
      isDark,
      scrolled: false,
    );
  }

  Widget _buildRoleInfo(
    Color primary,
    Color secondary,
    Color onBg,
    bool isDark,
  ) {
    final roles = [
      (
        Icons.school_rounded,
        'Student',
        'Access sports calendars, equipment, and achievements',
        primary,
      ),
      (
        Icons.sports_rounded,
        'Sports Staff',
        'Manage students, attendance, and equipment',
        secondary,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roles
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: r.$4.withValues(alpha: 0.1),
                    ),
                    child: Icon(r.$1, size: 18, color: r.$4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: r.$4,
                          ),
                        ),
                        Text(
                          r.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: onBg.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFormPanel(
    BuildContext context,
    Color primary,
    Color secondary,
    Color onBg,
    bool isDark, {
    required bool scrolled,
  }) {
    final content = Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!scrolled) ...[
                const SizedBox(height: 8),
                _BackButton(onBg: onBg),
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill in the details below to register',
                  style: TextStyle(
                    fontSize: 13,
                    color: onBg.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const SizedBox(height: 48),
              ],

              // ── Role selector ──────────────────────────────────────────────
              _SectionTitle(title: 'Account Type', primary: primary),
              const SizedBox(height: 10),
              _buildRoleSelector(primary, secondary, onBg, isDark),
              const SizedBox(height: 20),

              // ── Personal info ──────────────────────────────────────────────
              _SectionTitle(title: 'Personal Information', primary: primary),
              const SizedBox(height: 10),
              _buildTextField(
                id: 'signup_name',
                controller: _nameCtrl,
                label: 'Full Name *',
                icon: Icons.person_outline_rounded,
                onBg: onBg,
                isDark: isDark,
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Enter your full name (min 3 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                id: 'signup_email',
                controller: _emailCtrl,
                label: 'Email Address *',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onBg: onBg,
                isDark: isDark,
                validator: (val) {
                  if (val == null ||
                      !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(val.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                id: 'signup_phone',
                controller: _phoneCtrl,
                label: 'Phone Number *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onBg: onBg,
                isDark: isDark,
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Department dropdown
              _buildDropdown(
                id: 'signup_department',
                label: 'Department *',
                icon: Icons.school_outlined,
                value: _selectedDepartment,
                items: _departments,
                onBg: onBg,
                isDark: isDark,
                onChanged: (val) => setState(() => _selectedDepartment = val!),
              ),
              const SizedBox(height: 12),

              // Role-specific ID field
              if (_selectedRole == 'Student') ...[
                _buildTextField(
                  id: 'signup_register_number',
                  controller: _registerNumberCtrl,
                  label: 'Register Number *',
                  icon: Icons.badge_outlined,
                  onBg: onBg,
                  isDark: isDark,
                  hint: 'e.g. MRCAS22012',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter your college register number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ] else if (_selectedRole == 'Sports Staff') ...[
                _buildTextField(
                  id: 'signup_employee_id',
                  controller: _employeeIdCtrl,
                  label: 'Employee ID *',
                  icon: Icons.work_outline_rounded,
                  onBg: onBg,
                  isDark: isDark,
                  hint: 'e.g. EMP-2024-001',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter your MRCAS employee ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              // ── Password ───────────────────────────────────────────────────
              _SectionTitle(title: 'Security', primary: primary),
              const SizedBox(height: 10),
              _buildPasswordField(
                id: 'signup_password',
                controller: _passwordCtrl,
                label: 'Password *',
                obscure: _obscurePassword,
                onBg: onBg,
                isDark: isDark,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                validator: (val) {
                  if (val == null || !_isPasswordStrong(val)) {
                    return 'Use 8+ chars with uppercase, lowercase, number & symbol';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Password strength indicator
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _passwordCtrl,
                builder: (_, value, _) {
                  final strength = _getPasswordStrength(value.text);
                  return _PasswordStrengthBar(strength: strength, onBg: onBg);
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                id: 'signup_confirm_password',
                controller: _confirmPasswordCtrl,
                label: 'Confirm Password *',
                obscure: _obscureConfirm,
                onBg: onBg,
                isDark: isDark,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val != _passwordCtrl.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ── Terms & conditions ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _acceptedTerms,
                      onChanged: (val) =>
                          setState(() => _acceptedTerms = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I confirm that the information provided is accurate and I accept the MRCAS Sports Portal Terms of Use and Privacy Policy.',
                      style: TextStyle(
                        fontSize: 12,
                        color: onBg.withValues(alpha: 0.65),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Error display ─────────────────────────────────────────────
              if (auth.errorMessage != null &&
                  auth.errorMessage!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Submit button ─────────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  key: const Key('btn_create_account'),
                  onPressed: auth.isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Already have account
              Center(
                child: TextButton(
                  key: const Key('btn_already_have_account'),
                  onPressed: () => context.go('/auth/role'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: onBg.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );

    if (scrolled) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: content,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: content,
    );
  }

  Widget _buildRoleSelector(
    Color primary,
    Color secondary,
    Color onBg,
    bool isDark,
  ) {
    return Row(
      children: _roles.map((role) {
        final isSelected = _selectedRole == role;
        final color = role == 'Student' ? primary : secondary;
        final icon = role == 'Student'
            ? Icons.school_rounded
            : Icons.sports_rounded;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.10)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : onBg.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? color : onBg.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? color : onBg.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required String id,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color onBg,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: Key(id),
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: onBg, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String id,
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required Color onBg,
    required bool isDark,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: Key(id),
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: onBg, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String id,
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Color onBg,
    required bool isDark,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: Key(id),
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (val) =>
          val == null || val.isEmpty ? 'Please select $label' : null,
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final Color onBg;
  const _BackButton({required this.onBg});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('btn_back_signup'),
      onPressed: () => context.go('/welcome'),
      icon: Icon(
        Icons.arrow_back_rounded,
        size: 18,
        color: onBg.withValues(alpha: 0.6),
      ),
      label: Text(
        'Back',
        style: TextStyle(color: onBg.withValues(alpha: 0.6), fontSize: 13),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color primary;
  const _SectionTitle({required this.title, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: primary.withValues(alpha: 0.7),
      ),
    );
  }
}

enum PasswordStrength { none, weak, fair, good, strong }

class _PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  final Color onBg;

  const _PasswordStrengthBar({required this.strength, required this.onBg});

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.none) return const SizedBox.shrink();

    final colors = {
      PasswordStrength.weak: Colors.red,
      PasswordStrength.fair: Colors.orange,
      PasswordStrength.good: Colors.blue,
      PasswordStrength.strong: Colors.green,
    };
    final labels = {
      PasswordStrength.weak: 'Weak',
      PasswordStrength.fair: 'Fair',
      PasswordStrength.good: 'Good',
      PasswordStrength.strong: 'Strong',
    };
    final fills = {
      PasswordStrength.weak: 0.25,
      PasswordStrength.fair: 0.50,
      PasswordStrength.good: 0.75,
      PasswordStrength.strong: 1.0,
    };

    final color = colors[strength]!;
    final label = labels[strength]!;
    final fill = fills[strength]!;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fill,
              backgroundColor: onBg.withValues(alpha: 0.1),
              color: color,
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
