import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../state/app_state.dart';
import '../widgets/background_painter.dart';

Widget _buildAuthCenteredShell(BuildContext context, Widget formChild) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final double screenHeight = MediaQuery.of(context).size.height;

  return BackgroundPainter(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight > 64 ? screenHeight - 64 : 500,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Header Logo & Branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryTeal.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'HealthGuard AI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(isDark),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-Powered Healthcare & Early Risk Assessment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Glassmorphism Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    width: double.infinity,
                    child: AppCard(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 500 ? 16 : 32),
                      child: formChild,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryTeal),
                      const SizedBox(width: 6),
                      Text(
                        'Secure • Intelligent • Healthcare',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ==========================================
// 1. UNIFIED LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _selectedRole = 'patient'; // 'patient' or 'admin'
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    final state = AppStateProvider.of(context);

    try {
      final success = await state.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        final user = state.currentUser;
        if (_selectedRole == 'admin' && !(user?.isAdmin ?? false) && user?.role != 'admin') {
          await state.logout();
          setState(() => _errorMessage = 'Access Denied: Account does not have Administrator privileges.');
          return;
        }
        _redirectUserBasedOnRole(state);
      } else if (mounted) {
        setState(() => _errorMessage = 'Invalid email or password. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('user-not-found') || msg.contains('No account found')) {
          msg = 'No account found with this email.';
        } else if (msg.contains('wrong-password') || msg.contains('invalid-credential') || msg.contains('Incorrect password')) {
          msg = 'Invalid email or password. Please try again.';
        } else if (msg.contains('user-disabled')) {
          msg = 'Your account has been disabled. Please contact hospital administration.';
        }
        setState(() => _errorMessage = msg);
      }
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _errorMessage = null);
    final state = AppStateProvider.of(context);

    try {
      final success = await state.loginWithGoogle();
      if (success && mounted) {
        final user = state.currentUser;
        if (_selectedRole == 'admin' && !(user?.isAdmin ?? false) && user?.role != 'admin') {
          await state.logout();
          setState(() => _errorMessage = 'Access Denied: Account does not have Administrator privileges.');
          return;
        }
        _redirectUserBasedOnRole(state);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Google Sign-in failed: ${e.toString()}');
      }
    }
  }

  void _redirectUserBasedOnRole(AppState state) {
    final user = state.currentUser;
    if (user != null && (user.isAdmin || user.role == 'admin')) {
      Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    return _buildAuthCenteredShell(
      context,
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(isDark),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to continue to HealthGuard AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
            const SizedBox(height: 20),

            // Role Selector: Login As
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Login As',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedRole = 'patient';
                        _errorMessage = null;
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'patient'
                              ? AppColors.primaryTeal
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, size: 16, color: _selectedRole == 'patient' ? Colors.white : AppColors.getTextSecondary(isDark)),
                            const SizedBox(width: 6),
                            Text(
                              'Patient',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedRole == 'patient' ? Colors.white : AppColors.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedRole = 'admin';
                        _errorMessage = null;
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'admin'
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings_outlined, size: 16, color: _selectedRole == 'admin' ? Colors.white : AppColors.getTextSecondary(isDark)),
                            const SizedBox(width: 6),
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedRole == 'admin' ? Colors.white : AppColors.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            AppTextField(
              label: _selectedRole == 'admin' ? 'Admin ID / Email' : 'Email Address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: _selectedRole == 'admin' ? Icons.admin_panel_settings_outlined : Icons.email_outlined,
              hint: _selectedRole == 'admin' ? 'Enter admin email or ID' : 'Enter your email',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return _selectedRole == 'admin' ? 'Enter admin ID/email' : 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: _selectedRole == 'admin' ? 'Admin Password' : 'Password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline,
              hint: 'Enter your password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.getTextSecondary(isDark),
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                return null;
              },
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: _selectedRole == 'admin' ? AppColors.primaryBlue : AppColors.primaryTeal,
                        onChanged: (val) {
                          if (val != null) setState(() => _rememberMe = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedRole == 'admin' ? AppColors.primaryBlue : AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            AppButton(
              label: _selectedRole == 'admin' ? 'SIGN IN AS ADMINISTRATOR' : 'SIGN IN TO PATIENT PORTAL',
              icon: Icons.login,
              onPressed: _submit,
              isLoading: state.isLoading,
              isFullWidth: true,
              size: AppButtonSize.medium,
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.getBorder(isDark))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.getBorder(isDark))),
              ],
            ),
            const SizedBox(height: 18),

            AppButton(
              label: 'Continue with Google',
              variant: AppButtonVariant.outline,
              icon: Icons.g_mobiledata_rounded,
              onPressed: _handleGoogleLogin,
              isFullWidth: true,
              size: AppButtonSize.medium,
            ),

            if (_selectedRole == 'patient') ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. PATIENT REGISTER SCREEN
// ==========================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _ageController = TextEditingController(text: '28');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _gender = 'Male';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() => _errorMessage = null);
    final state = AppStateProvider.of(context);

    try {
      final success = await state.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 25,
        gender: _gender,
        password: _passwordController.text,
      );

      if (success && mounted) {
        await state.logout();
        setState(() {
          _isSuccess = true;
        });
      } else if (mounted) {
        setState(() => _errorMessage = 'Registration failed. Email may already be in use.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Registration error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    if (_isSuccess) {
      return _buildAuthCenteredShell(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              'Registration Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(isDark),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your account has been created successfully. Please login to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextSecondary(isDark),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Go to Sign In',
              isFullWidth: true,
              size: AppButtonSize.medium,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
            ),
          ],
        ),
      );
    }

    return _buildAuthCenteredShell(
      context,
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Your HealthGuard AI Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(isDark),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign up as a patient to access intelligent health assessments & personalized care.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            AppTextField(
              label: 'Full Name',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              hint: 'Enter your full name',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your full name';
                return null;
              },
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Email Address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              hint: 'Enter your email',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: AppTextField(
                    label: 'Mobile Number',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    hint: 'Phone',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: 'Age',
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    hint: '28',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.getBg(isDark),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.getBorder(isDark)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ['Male', 'Female', 'Other'].contains(_gender) ? _gender : 'Male',
                            isExpanded: true,
                            dropdownColor: AppColors.getSurface(isDark),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _gender = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline,
              hint: 'Enter your password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.getTextSecondary(isDark),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              prefixIcon: Icons.lock_reset_outlined,
              hint: 'Confirm password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.getTextSecondary(isDark),
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (v) {
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 22),

            AppButton(
              label: 'Create Account',
              onPressed: _submit,
              isLoading: state.isLoading,
              isFullWidth: true,
              size: AppButtonSize.medium,
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum ForgotPasswordPhase { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ForgotPasswordPhase _phase = ForgotPasswordPhase.email;
  
  Timer? _timer;
  int _secondsRemaining = 300;
  
  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;
  bool _canResend = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startOtpTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 300;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownRemaining = 60;
      _canResend = false;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_cooldownRemaining > 0) {
            _cooldownRemaining--;
          } else {
            _canResend = true;
            _cooldownTimer?.cancel();
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    
    final state = AppStateProvider.of(context);
    final email = _emailController.text.trim();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final exists = await state.checkEmailExists(email);
      if (!exists) {
        setState(() => _errorMessage = 'This email address is not registered.');
        return;
      }

      await state.sendOtp(email);
      setState(() {
        _phase = ForgotPasswordPhase.otp;
        _successMessage = 'OTP sent successfully to your registered email.';
      });
      _startOtpTimer();
      _startCooldownTimer();
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _resendOtp() async {
    if (!_canResend) return;

    final state = AppStateProvider.of(context);
    final email = _emailController.text.trim();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await state.sendOtp(email);
      setState(() {
        _successMessage = 'A new OTP has been sent successfully.';
      });
      _startOtpTimer();
      _startCooldownTimer();
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    if (_secondsRemaining <= 0) {
      setState(() => _errorMessage = 'The OTP has expired. Please request a new one.');
      return;
    }

    final state = AppStateProvider.of(context);
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final verified = await state.verifyOtp(email, otp);
      if (verified) {
        setState(() {
          _phase = ForgotPasswordPhase.newPassword;
          _successMessage = 'OTP verified successfully. Please set a new password.';
        });
        _timer?.cancel();
        _cooldownTimer?.cancel();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final state = AppStateProvider.of(context);
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await state.resetPasswordWithOtp(email, otp, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    return _buildAuthCenteredShell(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _phase == ForgotPasswordPhase.email
                ? 'Forgot Password'
                : _phase == ForgotPasswordPhase.otp
                    ? 'OTP Verification'
                    : 'Create New Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(isDark),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _phase == ForgotPasswordPhase.email
                ? 'Enter your registered email address to receive a 6-digit verification code.'
                : _phase == ForgotPasswordPhase.otp
                    ? 'We have sent a verification code to ${_emailController.text.trim()}.'
                    : 'Please choose a secure password for your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: TextStyle(fontSize: 12, color: AppColors.getTextPrimary(isDark)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_phase == ForgotPasswordPhase.email) ...[
            Form(
              key: _emailFormKey,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    hint: 'Enter your registered email',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Send OTP',
                    onPressed: _sendOtp,
                    isLoading: state.isLoading,
                    isFullWidth: true,
                    size: AppButtonSize.medium,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ] else if (_phase == ForgotPasswordPhase.otp) ...[
            Form(
              key: _otpFormKey,
              child: Column(
                children: [
                  AppTextField(
                    label: '6-Digit OTP',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.security,
                    hint: 'Enter 6-digit code',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter the OTP';
                      if (v.trim().length != 6 || int.tryParse(v.trim()) == null) {
                        return 'OTP must be exactly 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _secondsRemaining > 0
                            ? 'Expires in: ${_formatTime(_secondsRemaining)}'
                            : 'OTP Expired',
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondsRemaining > 0
                              ? AppColors.getTextSecondary(isDark)
                              : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _canResend ? _resendOtp : null,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _canResend
                              ? 'Resend OTP'
                              : 'Resend in ${_cooldownRemaining}s',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _canResend ? AppColors.primaryTeal : AppColors.getTextSecondary(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Verify OTP',
                    onPressed: _verifyOtp,
                    isLoading: state.isLoading,
                    isFullWidth: true,
                    size: AppButtonSize.medium,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ] else if (_phase == ForgotPasswordPhase.newPassword) ...[
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  AppTextField(
                    label: 'New Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    hint: 'Enter new password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter new password';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Confirm New Password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icons.lock_reset_outlined,
                    hint: 'Confirm new password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Reset Password',
                    onPressed: _resetPassword,
                    isLoading: state.isLoading,
                    isFullWidth: true,
                    size: AppButtonSize.medium,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, size: 14, color: AppColors.primaryTeal),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
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
