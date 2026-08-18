import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    // App Logo & Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.health_and_safety,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'HealthGuard AI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(isDark),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Header Title & Subtitle
                    Text(
                      'Welcome to HealthGuard AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(isDark),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-powered health assessment and intelligent healthcare guidance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Compact Portal Option Cards
                    _buildPortalOptionCard(
                      context: context,
                      isDark: isDark,
                      title: 'Patient Portal',
                      subtitle: 'Symptom assessment & appointment booking',
                      icon: Icons.person_outline,
                      iconColor: AppColors.primaryTeal,
                      route: '/auth',
                    ),
                    const SizedBox(height: 12),
                    _buildPortalOptionCard(
                      context: context,
                      isDark: isDark,
                      title: 'Doctor Portal',
                      subtitle: 'Physician schedule & clinical workspace',
                      icon: Icons.medical_services_outlined,
                      iconColor: AppColors.primaryBlue,
                      route: '/doctor-login',
                    ),
                    const SizedBox(height: 12),
                    _buildPortalOptionCard(
                      context: context,
                      isDark: isDark,
                      title: 'Admin Portal',
                      subtitle: 'Operations center & administrative control',
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      route: '/admin-login',
                    ),
                    const SizedBox(height: 20),

                    // Footer Copyright text
                    Text(
                      '© 2026 HealthGuard AI • Clinical Decision Support System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(isDark).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortalOptionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String route,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.getBg(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(isDark),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.getTextSecondary(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
