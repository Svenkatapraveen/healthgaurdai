import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../state/app_state.dart';
import '../data/doctor_database.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({Key? key}) : super(key: key);

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'dr.ananya@healthguard.ai');
  final _passwordController = TextEditingController(text: 'doctor123');
  final _doctorIdController = TextEditingController(text: 'doc_102');

  String? _selectedDoctorId = 'doc_102';
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _doctorIdController.dispose();
    super.dispose();
  }

  void _selectDoctorDemo(DoctorModel doc) {
    setState(() {
      _selectedDoctorId = doc.id;
      _emailController.text = doc.email.isNotEmpty ? doc.email : '${doc.id}@healthguard.ai';
      _passwordController.text = 'doctor123';
      _doctorIdController.text = doc.id;
      _errorMessage = null;
    });
  }

  Future<void> _handleDoctorLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final state = AppStateProvider.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final doctorId = _selectedDoctorId ?? _doctorIdController.text.trim();

    try {
      final success = await state.loginDoctor(email, password, doctorId: doctorId);
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/doctor-dashboard');
      } else if (mounted) {
        setState(() => _errorMessage = 'Invalid Doctor credentials or Doctor ID.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Doctor authentication error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & App Name
                      InkWell(
                        onTap: () => Navigator.of(context).pushNamed('/welcome'),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.medical_services_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'HealthGuard AI',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextPrimary(isDark),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Doctor Clinical Portal',
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
                        'Sign in with your physician credentials to access patient schedules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 20),

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

                      // Quick Demo Doctor Chips
                      Text(
                        'Quick Demo Physician Selection:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: doctorDatabase.map((doc) {
                          final bool isSelected = _selectedDoctorId == doc.id;
                          return ChoiceChip(
                            label: Text(doc.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                            backgroundColor: AppColors.getBg(isDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryBlue : AppColors.getBorder(isDark),
                              ),
                            ),
                            onSelected: (_) => _selectDoctorDemo(doc),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      AppTextField(
                        label: 'Physician Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        hint: 'dr.name@healthguard.ai',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter physician email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      AppTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        hint: 'Doctor password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter password';
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      AppButton(
                        label: 'DOCTOR LOGIN',
                        onPressed: _handleDoctorLogin,
                        isLoading: state.isLoading,
                        isFullWidth: true,
                        size: AppButtonSize.medium,
                      ),
                      const SizedBox(height: 20),

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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
