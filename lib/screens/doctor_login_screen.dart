import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
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
  bool _obscurePassword = true;
  String? _selectedDoctorId = 'doc_102';

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
    });
  }

  Future<void> _handleDoctorLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final state = AppStateProvider.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final doctorId = _selectedDoctorId ?? _doctorIdController.text.trim();

    try {
      final success = await state.loginDoctor(email, password, doctorId: doctorId);
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/doctor-dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Doctor credentials or Doctor ID.'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor authentication error: ${e.toString()}'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: state.isDarkMode
                ? const [Color(0xFF0A1128), Color(0xFF0F1C3F), Color(0xFF070D1F)]
                : const [Color(0xFFF0F4F8), Color(0xFFE2E8F0), Color(0xFFD9E2EC)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: GlassCard(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Branding & Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              size: 32,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HEALTHGUARD AI',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                                ),
                              ),
                              const Text(
                                'Professional Doctor Portal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      Text(
                        'Physician Sign In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Access assigned patient clinical records & consultation workspace',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: state.isDarkMode ? Colors.white70 : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Multi-Doctor Test Switcher
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primaryTeal),
                                SizedBox(width: 6),
                                Text(
                                  'Quick Select Doctor Profile for Testing:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: doctorDatabase.take(4).map((doc) {
                                final isSelected = _selectedDoctorId == doc.id;
                                return InkWell(
                                  onTap: () => _selectDoctorDemo(doc),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryTeal : AppColors.primaryTeal.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '${doc.name.split(' ').first} (${doc.id.toUpperCase()})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.white : (state.isDarkMode ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary),
                        decoration: InputDecoration(
                          labelText: 'Doctor Email / Account',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryTeal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter doctor email' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryTeal),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter password' : null,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : _handleDoctorLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: state.isLoading
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Access Clinical Portal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                            child: const Text(
                              'Patient Login',
                              style: TextStyle(color: AppColors.primaryTeal, fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/admin-dashboard'),
                            child: const Text(
                              'Admin Portal',
                              style: TextStyle(color: AppColors.primaryTeal, fontSize: 13),
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
