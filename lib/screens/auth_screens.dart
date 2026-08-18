import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../state/app_state.dart';

Widget _buildAuthCenteredShell(BuildContext context, Widget formChild) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    backgroundColor: isDark ? AppColors.darkBg : AppColors.navyDark,
    body: Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [
            AppColors.primaryBlue.withOpacity(0.4),
            isDark ? AppColors.darkBg : AppColors.navyDark,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: AppCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Branding & Back Button Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.getTextPrimary(isDark),
                          size: 20,
                        ),
                        tooltip: 'Back to Welcome',
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushNamed('/welcome');
                          }
                        },
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pushNamed('/welcome'),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.health_and_safety,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'HealthGuard AI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextPrimary(isDark),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // Spacing placeholder for balanced header alignment
                    ],
                  ),
                  const SizedBox(height: 24),
                  formChild,
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
// 1. PATIENT LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
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
        if (state.currentUser?.isAdmin == true) {
          Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      } else if (mounted) {
        setState(() => _errorMessage = 'Invalid email or password. Please check your credentials.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Login error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _errorMessage = null);
    final state = AppStateProvider.of(context);

    try {
      final success = await state.loginWithGoogle();
      if (success && mounted) {
        if (state.currentUser?.isAdmin == true) {
          Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Google Sign-in failed: ${e.toString()}');
      }
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
              'Sign in to continue to your HealthGuard AI portal.',
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
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
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
              label: 'Email Address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              hint: 'name@example.com',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 16),

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
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your password';
                return null;
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            AppButton(
              label: 'LOGIN',
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
                    'Register',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back, size: 14, color: AppColors.primaryTeal),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/welcome');
                  },
                  child: const Text(
                    'Back to Welcome Screen',
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

// ==========================================
// 2. PATIENT REGISTER SCREEN
// ==========================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

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
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
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

    return _buildAuthCenteredShell(
      context,
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Your Account',
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
              'Join HealthGuard AI for intelligent health assessment and healthcare management.',
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
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
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
              hint: 'John Doe',
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
              hint: 'name@example.com',
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
                    hint: '+1 555-0199',
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
                            value: _gender,
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
              hint: 'Create a password',
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
              hint: 'Re-enter password',
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
              label: 'REGISTER',
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
                    'Login',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back, size: 14, color: AppColors.primaryTeal),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/welcome');
                  },
                  child: const Text(
                    'Back to Welcome Screen',
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

// ==========================================
// 3. FORGOT PASSWORD SCREEN
// ==========================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppStateProvider.of(context);
    try {
      await state.resetPassword(_emailController.text.trim());
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
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
            'Reset Your Password',
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
            "Enter your registered email address and we'll help you reset your password.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: 24),

          if (_submitted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    'Password Reset Link Sent!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please check your inbox at ${_emailController.text} for instructions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    hint: 'name@example.com',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your email';
                      if (!v.contains('@')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Send Reset Link',
                    onPressed: _submit,
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
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text(
                  'Back to Login',
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
