import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final user = state.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized access.')));
    }

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Avatar & Title header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
                    child: Text(
                      user.fullName.substring(0, 1),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Health Statistics boxes
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    isDark,
                    title: 'Assessments',
                    value: state.assessments.length.toString(),
                    icon: Icons.analytics,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    isDark,
                    title: 'Appointments',
                    value: state.appointments.length.toString(),
                    icon: Icons.event,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Demographics Info
            Text(
              'Biometrics Profile',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  _buildBioRow(isDark, 'Age', '${user.age} Years Old', Icons.cake),
                  const Divider(),
                  _buildBioRow(isDark, 'Gender Identification', user.gender, Icons.wc),
                  const Divider(),
                  _buildBioRow(isDark, 'Contact Number', user.mobileNumber, Icons.phone),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account settings list
            Text(
              'Account Preferences',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  // Dark mode switcher
                  ListTile(
                    leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: AppColors.primaryTeal),
                    title: const Text('Dark Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    trailing: Switch(
                      value: isDark,
                      activeColor: AppColors.primaryTeal,
                      onChanged: (val) => state.toggleTheme(),
                    ),
                  ),
                  const Divider(),
                  
                  // Mock security/passwords settings
                  _buildSettingTile(isDark, 'Security Settings & Password', Icons.security),
                  const Divider(),
                  _buildSettingTile(isDark, 'Emergency Contact Information', Icons.contact_phone),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                await state.logout();
                Navigator.pushReplacementNamed(context, '/welcome');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out of Account', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.riskCritical.withOpacity(0.12),
                foregroundColor: AppColors.riskCritical,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(bool isDark, {required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark))),
        ],
      ),
    );
  }

  Widget _buildBioRow(bool isDark, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryTeal, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(bool isDark, String text, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryTeal),
      title: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.chevron_right, color: AppColors.getTextSecondary(isDark)),
      onTap: () {},
    );
  }
}
