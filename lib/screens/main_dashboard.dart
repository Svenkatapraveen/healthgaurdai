import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'assessment_wizard.dart';
import 'booking_screens.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != null && routeName.contains('tab=reports')) {
      _currentIndex = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final user = state.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        body: Center(
          child: AppCard(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.primaryTeal, size: 48),
                  const SizedBox(height: 16),
                  Text('Authentication Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
                  const SizedBox(height: 8),
                  Text('Please log in to your patient account to access your health dashboard.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13)),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Go to Login',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget bodyContent;
    String pageTitle;
    String pageSubtitle;

    switch (_currentIndex) {
      case 1:
        pageTitle = 'Health Assessment Intake';
        pageSubtitle = 'Multi-step clinical intake and symptom checker wizard';
        bodyContent = const AssessmentWizard(isNested: true);
        break;
      case 2:
        pageTitle = 'Medical Reports';
        pageSubtitle = 'View and download past medical assessment reports';
        bodyContent = _buildReportsTab(context, isDark, state, user);
        break;
      case 3:
        pageTitle = 'My Appointments & Booking';
        pageSubtitle = 'Schedule consultations with clinical specialists';
        bodyContent = const BookingWizardScreen();
        break;
      case 0:
      default:
        final hour = DateTime.now().hour;
        String greeting = 'Good Morning';
        if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
        if (hour >= 17) greeting = 'Good Evening';

        pageTitle = '$greeting, ${user.name}';
        pageSubtitle = "Here's your personal health overview & risk summary.";
        bodyContent = _buildHomeTab(context, isDark, state, user);
        break;
    }

    return AppLayout(
      title: pageTitle,
      subtitle: pageSubtitle,
      role: UserRole.patient,
      currentRoute: _currentIndex == 1
          ? '/assessment'
          : _currentIndex == 2
              ? '/dashboard?tab=reports'
              : _currentIndex == 3
                  ? '/my-appointments'
                  : '/dashboard',
      body: bodyContent,
    );
  }

  // ==========================================
  // HOME TAB
  // ==========================================
  Widget _buildHomeTab(BuildContext context, bool isDark, AppState state, AppUser user) {
    String riskLevel = 'Low Risk';
    AssessmentModel? latestAssessment;

    if (state.assessments.isNotEmpty) {
      latestAssessment = state.assessments.first;
      riskLevel = latestAssessment.riskCategory;
    }

    final upcomingAppts = state.appointments
        .where((a) => a.preferredDateTime.isAfter(DateTime.now().subtract(const Duration(hours: 1))))
        .toList();
    upcomingAppts.sort((a, b) => a.preferredDateTime.compareTo(b.preferredDateTime));
    final nextAppt = upcomingAppts.isNotEmpty ? upcomingAppts.first : null;

    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric Cards Grid
        LayoutBuilder(
          builder: (ctx, constraints) {
            int crossAxisCount = isDesktop ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 2.2 : 2.5,
              children: [
                StatCard(
                  title: 'Health Risk Level',
                  value: riskLevel,
                  subtitle: latestAssessment != null ? 'Score: ${latestAssessment.overallRiskScore.toInt()}/100' : 'No recent check',
                  icon: Icons.shield_outlined,
                  iconBgColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                  iconColor: AppColors.primaryTeal,
                  onTap: () {
                    if (latestAssessment != null) {
                      Navigator.pushNamed(context, '/results', arguments: latestAssessment);
                    } else {
                      AppLayout.safeNavigate(context, '/assessment', '/dashboard');
                    }
                  },
                ),
                StatCard(
                  title: 'Latest Assessment',
                  value: latestAssessment != null ? '${latestAssessment.date.day}/${latestAssessment.date.month}/${latestAssessment.date.year}' : 'Not Taken',
                  subtitle: latestAssessment != null ? '${latestAssessment.symptoms.length} symptoms reported' : 'Click to start',
                  icon: Icons.assignment_outlined,
                  iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                  iconColor: AppColors.primaryBlue,
                  onTap: () {
                    if (latestAssessment != null) {
                      Navigator.pushNamed(context, '/report?id=${latestAssessment.id}');
                    } else {
                      AppLayout.safeNavigate(context, '/assessment', '/dashboard');
                    }
                  },
                ),
                StatCard(
                  title: 'Upcoming Appointment',
                  value: nextAppt != null ? '${nextAppt.preferredDateTime.day}/${nextAppt.preferredDateTime.month}' : 'None Scheduled',
                  subtitle: nextAppt != null ? 'Dr. ${nextAppt.doctorName}' : 'Book consultation',
                  icon: Icons.calendar_month_outlined,
                  iconBgColor: AppColors.warning.withValues(alpha: 0.15),
                  iconColor: AppColors.warning,
                  onTap: () => AppLayout.safeNavigate(context, '/my-appointments', '/dashboard'),
                ),
                StatCard(
                  title: 'Medical Reports',
                  value: '${state.assessments.length}',
                  subtitle: 'Available PDF records',
                  icon: Icons.description_outlined,
                  iconBgColor: AppColors.info.withValues(alpha: 0.15),
                  iconColor: AppColors.info,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        // Quick Actions Section
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppCard(
                onTap: () => AppLayout.safeNavigate(context, '/assessment', '/dashboard'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_task, color: AppColors.primaryTeal, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Assessment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.getTextPrimary(isDark))),
                          Text('Run AI symptom risk evaluation', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppCard(
                onTap: () => AppLayout.safeNavigate(context, '/booking', '/dashboard'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month, color: AppColors.primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.getTextPrimary(isDark))),
                          Text('Connect with clinical doctors', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Recent Assessments & Upcoming Appt Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Health Assessments',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                        ),
                        if (state.assessments.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _currentIndex = 2),
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (state.assessments.isEmpty)
                      EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No Health Assessments Yet',
                        description: 'Take your first AI health check to evaluate risk indicators.',
                        actionLabel: 'Start Assessment',
                        onAction: () => setState(() => _currentIndex = 1),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.assessments.take(3).length,
                        separatorBuilder: (ctx, i) => const Divider(height: 20),
                        itemBuilder: (ctx, index) {
                          final asm = state.assessments[index];
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.article_outlined, color: AppColors.primaryBlue, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assessment #${asm.id.substring(0, asm.id.length > 8 ? 8 : asm.id.length)}',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.getTextPrimary(isDark)),
                                    ),
                                    Text(
                                      '${asm.symptoms.length} Symptoms • ${asm.date.day}/${asm.date.month}/${asm.date.year}',
                                      style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                                    ),
                                  ],
                                ),
                              ),
                              AppBadge.risk(asm.riskCategory),
                              const SizedBox(width: 12),
                              AppButton(
                                label: 'Report',
                                size: AppButtonSize.small,
                                variant: AppButtonVariant.outline,
                                onPressed: () {
                                  Navigator.pushNamed(context, '/report?id=${asm.id}');
                                },
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Appointment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                      ),
                      const SizedBox(height: 16),
                      if (nextAppt == null)
                        EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'No Upcoming Consultations',
                          description: 'Book an appointment with specialist doctors.',
                          actionLabel: 'Book Appointment',
                          onAction: () => setState(() => _currentIndex = 3),
                        )
                      else ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                              child: Text(
                                nextAppt.doctorName.trim().isNotEmpty
                                    ? nextAppt.doctorName.trim().characters.first.toUpperCase()
                                    : 'D',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dr. ${nextAppt.doctorName}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.getTextPrimary(isDark))),
                                  Text(nextAppt.doctorSpecialty, style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
                                ],
                              ),
                            ),
                            AppBadge.status(nextAppt.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: AppColors.primaryTeal),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${nextAppt.preferredDateTime.day}/${nextAppt.preferredDateTime.month}/${nextAppt.preferredDateTime.year}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark)),
                                  ),
                                ],
                              ),
                              Text(
                                nextAppt.timeSlot,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'View Appointment Details',
                          isFullWidth: true,
                          size: AppButtonSize.small,
                          onPressed: () => AppLayout.safeNavigate(context, '/my-appointments', '/dashboard'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ==========================================
  // REPORTS TAB
  // ==========================================
  Widget _buildReportsTab(BuildContext context, bool isDark, AppState state, AppUser user) {
    if (state.assessments.isEmpty) {
      return EmptyState(
        icon: Icons.description_outlined,
        title: 'No Medical Reports Found',
        description: 'Take a health assessment to generate professional AI reports.',
        actionLabel: 'Take Health Assessment',
        onAction: () => setState(() => _currentIndex = 1),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Medical Reports (${state.assessments.length})',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.assessments.length,
          itemBuilder: (ctx, index) {
            final asm = state.assessments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryBlue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health Assessment Report',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Report ID: ${asm.id} • Date: ${asm.date.day}/${asm.date.month}/${asm.date.year}',
                            style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              AppBadge.risk(asm.riskCategory),
                              const SizedBox(width: 8),
                              Text(
                                '${asm.symptoms.length} Symptoms Evaluated',
                                style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        AppButton(
                          label: 'View Report',
                          icon: Icons.visibility_outlined,
                          size: AppButtonSize.small,
                          onPressed: () {
                            Navigator.pushNamed(context, '/report?id=${asm.id}');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
