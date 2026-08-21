import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_text_field.dart';
import '../state/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileDialog(BuildContext context, AppState state) {
    final user = state.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.fullName);
    final mobileCtrl = TextEditingController(text: user.mobileNumber);
    final ageCtrl = TextEditingController(text: user.age > 0 ? '${user.age}' : '30');
    String selectedGender = user.gender.isNotEmpty ? user.gender : 'Male';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppModal(
          title: 'Edit Profile Information',
          icon: Icons.edit_note_outlined,
          iconColor: AppColors.primaryTeal,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Full Name',
                controller: nameCtrl,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Mobile Number',
                controller: mobileCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Age',
                      controller: ageCtrl,
                      prefixIcon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedGender,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedGender = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              onPressed: () => Navigator.pop(ctx),
            ),
            AppButton(
              label: 'Save Changes',
              size: AppButtonSize.small,
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newMobile = mobileCtrl.text.trim();
                final newAge = int.tryParse(ageCtrl.text.trim()) ?? user.age;
                
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
                  return;
                }

                final ok = await state.updateUserProfile(
                  fullName: newName,
                  mobileNumber: newMobile,
                  age: newAge,
                  gender: selectedGender,
                );

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Profile updated successfully!' : 'Failed to update profile.'),
                      backgroundColor: ok ? AppColors.success : AppColors.danger,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final user = state.currentUser;
    final role = user?.isAdmin == true ? UserRole.admin : UserRole.patient;
    final name = user?.name ?? 'User Account';
    final email = user?.email ?? 'user@healthguard.ai';

    return AppLayout(
      title: 'User Profile & Settings',
      subtitle: 'Manage your biometrics, notifications, theme preferences, and credentials',
      role: role,
      currentRoute: '/profile',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppButton(
                label: 'Back to Dashboard',
                icon: Icons.arrow_back,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                onPressed: () {
                  final backTarget = role == UserRole.admin ? '/admin-dashboard' : '/dashboard';
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, backTarget);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile Header Card
          AppCard(
            backgroundColor: AppColors.primaryBlue,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryTeal,
                  child: Text(
                    name.trim().isNotEmpty ? name.trim().characters.first.toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryTeal, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          role == UserRole.admin ? 'Administrator' : 'Patient',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Assessments',
                  value: '${state.assessments.length}',
                  icon: Icons.assignment_outlined,
                  iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                  iconColor: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Total Appointments',
                  value: '${state.appointments.length}',
                  icon: Icons.calendar_month_outlined,
                  iconBgColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                  iconColor: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Details Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Biometrics & Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(isDark))),
                    if (user != null)
                      AppButton(
                        label: 'Edit Profile',
                        icon: Icons.edit_outlined,
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.small,
                        onPressed: () => _showEditProfileDialog(context, state),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (user != null) ...[
                  _buildProfileRow(isDark, 'Age', '${user.age} Years Old', Icons.cake_outlined),
                  const Divider(height: 20),
                  _buildProfileRow(isDark, 'Gender', user.gender, Icons.wc_outlined),
                  const Divider(height: 20),
                  _buildProfileRow(isDark, 'Mobile Number', user.mobileNumber.isNotEmpty ? user.mobileNumber : 'Not set', Icons.phone_outlined),
                  const Divider(height: 20),
                ],
                _buildProfileRow(isDark, 'Account Security', 'Firebase Auth SSL Encrypted', Icons.shield_outlined),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Logout Account',
                icon: Icons.logout,
                variant: AppButtonVariant.danger,
                onPressed: () {
                  state.logout();
                  Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(bool isDark, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryTeal),
        const SizedBox(width: 12),
        SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark)))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)))),
      ],
    );
  }
}
