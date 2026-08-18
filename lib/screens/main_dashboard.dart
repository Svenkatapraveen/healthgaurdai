import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'assessment_wizard.dart';
import '../widgets/custom_chart.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final user = state.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Unauthorized access. Log in.')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildBody(context, isDark, state, user),
              ),
              _buildBottomNavBar(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, AppState state, AppUser user) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(context, isDark, state, user);
      case 1:
        return const AssessmentWizard(isNested: true);
      case 2:
        return _buildReportsTab(context, isDark, state, user);
      case 3:
        return _buildAppointmentsTab(context, isDark, state, user);
      case 4:
        return _buildProfileTab(context, isDark, state, user);
      default:
        return _buildHomeTab(context, isDark, state, user);
    }
  }

  // ==========================================
  // 1. HOME TAB REDESIGN
  // ==========================================
  Widget _buildHomeTab(BuildContext context, bool isDark, AppState state, AppUser user) {
    // Compute Health Score from assessments
    double healthScore = 85.0; // Default base
    String riskLevel = 'Low Risk';
    Color riskColor = AppColors.riskLow;
    AssessmentModel? latestAssessment;

    if (state.assessments.isNotEmpty) {
      latestAssessment = state.assessments.first;
      healthScore = 100 - latestAssessment.overallRiskScore;
      riskLevel = latestAssessment.riskCategory;
      if (riskLevel.contains('Low')) {
        riskColor = AppColors.riskLow;
      } else if (riskLevel.contains('Moderate')) {
        riskColor = AppColors.riskModerate;
      } else if (riskLevel.contains('Critical')) {
        riskColor = AppColors.riskCritical;
      } else {
        riskColor = AppColors.riskHigh;
      }
    }

    // Dynamic greeting based on current local hour
    final hour = DateTime.now().hour;
    String timeGreeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      timeGreeting = 'Good Afternoon';
    } else if (hour >= 17) {
      timeGreeting = 'Good Evening';
    }

    // Find nearest upcoming appointment
    final upcomingAppts = state.appointments
        .where((a) => a.preferredDateTime.isAfter(DateTime.now().subtract(const Duration(hours: 1))))
        .toList();
    upcomingAppts.sort((a, b) => a.preferredDateTime.compareTo(b.preferredDateTime));
    final nextAppt = upcomingAppts.isNotEmpty ? upcomingAppts.first : null;

    // Compute health scores history for the mini graph
    List<double> trendHealthScores = [];
    List<String> trendLabels = [];
    if (state.assessments.isNotEmpty) {
      final recentAsms = state.assessments.take(5).toList().reversed.toList();
      for (var asm in recentAsms) {
        trendHealthScores.add(100.0 - asm.overallRiskScore);
        trendLabels.add('${asm.date.day}/${asm.date.month}');
      }
    }
    if (trendHealthScores.length < 2) {
      trendHealthScores = [75.0, 78.0, 80.0, 82.0, 85.0];
      trendLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    }

    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 600;

    Widget quickActionsGrid;
    if (isTablet) {
      quickActionsGrid = Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              context,
              isDark: isDark,
              title: 'Health Assessment',
              subtitle: 'Start checker wizard',
              icon: Icons.health_and_safety_rounded,
              color: AppColors.primaryTeal,
              onTap: () => setState(() => _currentIndex = 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              context,
              isDark: isDark,
              title: 'Book Appointment',
              subtitle: 'Consult a specialist',
              icon: Icons.calendar_month_rounded,
              color: Colors.blueAccent,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              context,
              isDark: isDark,
              title: 'Health Reports',
              subtitle: 'Track past assessments',
              icon: Icons.description_rounded,
              color: Colors.purpleAccent,
              onTap: () => setState(() => _currentIndex = 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              context,
              isDark: isDark,
              title: 'Emergency Alert',
              subtitle: 'Immediate medical help',
              icon: Icons.emergency_rounded,
              color: AppColors.riskCritical,
              onTap: () => Navigator.pushNamed(context, '/emergency'),
            ),
          ),
        ],
      );
    } else {
      quickActionsGrid = Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  isDark: isDark,
                  title: 'Health Assessment',
                  subtitle: 'Start checker wizard',
                  icon: Icons.health_and_safety_rounded,
                  color: AppColors.primaryTeal,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  isDark: isDark,
                  title: 'Book Appointment',
                  subtitle: 'Consult a specialist',
                  icon: Icons.calendar_month_rounded,
                  color: Colors.blueAccent,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  isDark: isDark,
                  title: 'Health Reports',
                  subtitle: 'Track past assessments',
                  icon: Icons.description_rounded,
                  color: Colors.purpleAccent,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  isDark: isDark,
                  title: 'Emergency Alert',
                  subtitle: 'Immediate medical help',
                  icon: Icons.emergency_rounded,
                  color: AppColors.riskCritical,
                  onTap: () => Navigator.pushNamed(context, '/emergency'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => state.reloadUserData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$timeGreeting,',
                      style: TextStyle(fontSize: 14, color: AppColors.getTextSecondary(isDark)),
                    ),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 22),
                      onPressed: () => state.toggleTheme(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_active_outlined, size: 22),
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 4),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
                        child: Text(
                          user.fullName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Health Score Card
            _buildHealthScoreCard(isDark, healthScore, riskLevel, riskColor),
            const SizedBox(height: 20),

            // 3. Quick Actions Grid
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            quickActionsGrid,
            const SizedBox(height: 20),

            // 4. AI Insights Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                Row(
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: _currentPage == index ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primaryTeal : (isDark ? Colors.white24 : Colors.black26),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: PageView(
                controller: _pageController,
                onPageChanged: (val) => setState(() => _currentPage = val),
                children: [
                  _buildInsightCard(
                    isDark: isDark,
                    title: 'Hydration Strategy',
                    icon: Icons.water_drop_outlined,
                    color: Colors.blueAccent,
                    description: 'Staying hydrated keeps your vascular system efficient. Target at least 2.5 to 3 Liters today.',
                  ),
                  _buildInsightCard(
                    isDark: isDark,
                    title: 'Daily Action Checklist',
                    icon: Icons.check_circle_outline,
                    color: AppColors.primaryTeal,
                    description: 'A light 20-minute walk post-lunch lowers cardiovascular risk and improves sleep statistics.',
                  ),
                  _buildInsightCard(
                    isDark: isDark,
                    title: 'Risk Profile Notification',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.riskModerate,
                    description: 'Higher atmospheric dust is forecast. If you have respiratory sensitivities, reduce outdoor runs.',
                  ),
                  _buildInsightCard(
                    isDark: isDark,
                    title: 'Circadian Sleep Hygiene',
                    icon: Icons.nights_stay_outlined,
                    color: Colors.indigoAccent,
                    description: 'Maintain consistent sleep timings. Dimming screens 30 minutes before bed enhances slow-wave rest.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Upcoming Appointment
            Text(
              'Upcoming Appointment',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            _buildUpcomingAppointmentCard(isDark, nextAppt),
            const SizedBox(height: 20),

            // 6. Recent Reports Card
            Text(
              'Recent Reports',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentReportsCard(context, isDark, latestAssessment),
            const SizedBox(height: 20),

            // 7. Health Trends
            Text(
              'Health Trends',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            _buildHealthTrendsCard(context, isDark, trendHealthScores, trendLabels),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(bool isDark, double healthScore, String riskLevel, Color riskColor) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Health Score Index',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on vitals & checkers.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: riskColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        riskLevel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: healthScore / 100,
                  strokeWidth: 8,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                  color: riskColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${healthScore.toInt()}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(fontSize: 8, color: AppColors.getTextSecondary(isDark)),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.getTextSecondary(isDark),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(bool isDark, AppointmentModel? initialAppt) {
    final state = AppStateProvider.of(context);
    return StreamBuilder<List<AppointmentModel>>(
      stream: state.streamUserAppointments(),
      builder: (context, snapshot) {
        final list = snapshot.data ?? (initialAppt != null ? [initialAppt] : state.appointments);

        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month_outlined, color: AppColors.primaryTeal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No Active Consultations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Schedule an appointment with a specialist.', style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          );
        }

        return Column(
          children: list.take(2).map((appt) {
            Color statusColor = AppColors.riskModerate;
            IconData statusIcon = Icons.hourglass_top_outlined;
            if (appt.status == 'Approved') {
              statusColor = AppColors.primaryGreen;
              statusIcon = Icons.check_circle_outline;
            } else if (appt.status == 'Pending') {
              statusColor = AppColors.riskModerate;
              statusIcon = Icons.hourglass_top_outlined;
            } else if (appt.status == 'Rejected') {
              statusColor = AppColors.riskCritical;
              statusIcon = Icons.cancel_outlined;
            } else if (appt.status == 'Rescheduled') {
              statusColor = Colors.blueAccent;
              statusIcon = Icons.update_outlined;
            }

            final dateStr = '${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year} @ ${appt.preferredDateTime.hour.toString().padLeft(2, '0')}:${appt.preferredDateTime.minute.toString().padLeft(2, '0')}';
            final docTitle = appt.doctorName.isNotEmpty ? appt.doctorName : appt.doctorSpecialty;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF102859).withOpacity(0.5), const Color(0xFF0F1A3A).withOpacity(0.5)]
                      : [Colors.blue.shade50.withOpacity(0.6), Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              docTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Specialty: ${appt.doctorSpecialty}',
                              style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark)),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          appt.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (appt.status == 'Rejected' && appt.rejectionReason != null && appt.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Rejection Reason: ${appt.rejectionReason}',
                      style: const TextStyle(fontSize: 10, color: AppColors.riskCritical, fontWeight: FontWeight.bold),
                    ),
                  ],
                  if (appt.status == 'Rescheduled' && appt.previousAppointmentDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Rescheduled from: ${appt.previousAppointmentDate!.day}/${appt.previousAppointmentDate!.month}/${appt.previousAppointmentDate!.year}',
                      style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInsightCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.getTextSecondary(isDark),
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecentReportsCard(BuildContext context, bool isDark, AssessmentModel? latestAsm) {
    if (latestAsm == null) {
      return GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.primaryTeal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Reports Available',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Complete an assessment to see your report here.',
                    style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text(
                'Start',
                style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final dateStr = '${latestAsm.date.day}/${latestAsm.date.month}/${latestAsm.date.year}';
    Color riskColor = AppColors.riskLow;
    if (latestAsm.riskCategory.contains('Moderate')) {
      riskColor = AppColors.riskModerate;
    } else if (latestAsm.riskCategory.contains('Critical')) {
      riskColor = AppColors.riskCritical;
    } else if (latestAsm.riskCategory.contains('High')) {
      riskColor = AppColors.riskHigh;
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: AppColors.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Last Diagnostic Checkup',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                  ),
                ],
              ),
              Text(
                dateStr,
                style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Symptoms: ${latestAsm.primarySymptoms.join(", ")}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latestAsm.clinicalSummary,
                      style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark), height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor.withOpacity(0.2)),
                ),
                child: Text(
                  latestAsm.riskCategory,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/results', arguments: latestAsm),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Details', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/report', arguments: latestAsm),
                icon: const Icon(Icons.picture_as_pdf, size: 12),
                label: const Text('PDF Report', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTrendsCard(BuildContext context, bool isDark, List<double> healthScores, List<String> labels) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: AppColors.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Health Index Progression',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                ],
              ),
              Text(
                'Progression History',
                style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomChart(
            dataPoints: healthScores,
            labels: labels,
            type: ChartType.line,
            color: AppColors.primaryTeal,
            height: 100,
            maxValue: 100,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. REPORTS TAB
  // ==========================================
  Widget _buildReportsTab(BuildContext context, bool isDark, AppState state, AppUser user) {
    if (state.assessments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, size: 60, color: AppColors.primaryTeal),
              const SizedBox(height: 16),
              const Text('No Diagnostic Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'Complete your initial symptom assessment inside the Checkup tab to view PDF reports.',
                style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _currentIndex = 1),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                child: const Text('Start Checkup', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Diagnostic Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.assessments.length,
        itemBuilder: (context, index) {
          final asm = state.assessments[index];
          final hasHeartRisk = asm.primarySymptoms.contains('Chest Pain') || asm.primarySymptoms.contains('Breathing Difficulty');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${asm.date.day}/${asm.date.month}/${asm.date.year}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryTeal),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (hasHeartRisk ? AppColors.riskHigh : AppColors.riskLow).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            asm.riskCategory,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: hasHeartRisk ? AppColors.riskHigh : AppColors.riskLow,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Symptoms: ${asm.primarySymptoms.join(", ")}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asm.clinicalSummary,
                      style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/results', arguments: asm);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('View Details', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/report', arguments: asm);
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 14),
                          label: const Text('PDF Report', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 3. APPOINTMENTS TAB
  // ==========================================
  Widget _buildAppointmentsTab(BuildContext context, bool isDark, AppState state, AppUser user) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Consultations Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/booking'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Book', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
      ),
      body: state.appointments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 60, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    const Text('No Appointments Scheduled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      'Schedule a remote or physical consultation with certified doctors.',
                      style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.appointments.length,
              itemBuilder: (context, index) {
                final appt = state.appointments[index];
                final isConfirmed = appt.status.toLowerCase() == 'confirmed';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.medical_services_outlined, color: AppColors.primaryBlue, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appt.doctorSpecialty,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Patient: ${appt.patientName}',
                                  style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                                ),
                                Text(
                                  '${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year} @ ${appt.preferredDateTime.hour.toString().padLeft(2, '0')}:${appt.preferredDateTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (appt.status == 'Completed' ? Colors.green : (isConfirmed ? AppColors.riskLow : AppColors.riskModerate)).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  appt.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: appt.status == 'Completed' ? Colors.green : (isConfirmed ? AppColors.riskLow : AppColors.riskModerate),
                                  ),
                                ),
                              ),
                              if (appt.status == 'Completed') ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final consultation = await state.dbService.getConsultationByAppointmentId(appt.id);
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('Consultation Result - ${appt.doctorSpecialty}'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Doctor: ${consultation?.doctorName.isNotEmpty == true ? consultation!.doctorName : appt.doctorName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text('Specialty: ${consultation?.doctorSpecialty.isNotEmpty == true ? consultation!.doctorSpecialty : appt.doctorSpecialty}', style: const TextStyle(color: AppColors.primaryTeal, fontSize: 12)),
                                                const Divider(),
                                                const Text('Clinical Assessment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                Text(consultation?.clinicalAssessment.isNotEmpty == true ? consultation!.clinicalAssessment : 'Completed consultation.'),
                                                const SizedBox(height: 10),
                                                const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                Text(consultation?.recommendations.isNotEmpty == true ? consultation!.recommendations : 'Follow regular care.'),
                                                const SizedBox(height: 10),
                                                const Text('Treatment & Medication Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                Text(consultation?.treatmentInstructions.isNotEmpty == true ? consultation!.treatmentInstructions : 'None specified.'),
                                                if (consultation?.followUpRequired == true) ...[
                                                  const SizedBox(height: 10),
                                                  const Text('Follow-Up Plan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                                                  Text(consultation?.followUpNotes.isNotEmpty == true ? consultation!.followUpNotes : 'Follow-up requested by physician.'),
                                                ],
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'View Doctor Result',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryTeal, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ==========================================
  // 4. PROFILE TAB
  // ==========================================
  Widget _buildProfileTab(BuildContext context, bool isDark, AppState state, AppUser user) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Health Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Avatar & Title header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
                    child: Text(
                      user.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.fullName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                child: Column(
                  children: [
                    _buildBioRow(isDark, 'Age', '${user.age} Years Old', Icons.cake),
                    const Divider(height: 1),
                    _buildBioRow(isDark, 'Gender Identification', user.gender, Icons.wc),
                    const Divider(height: 1),
                    _buildBioRow(isDark, 'Contact Number', user.mobileNumber, Icons.phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account settings list
            Text(
              'Account Preferences',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppColors.primaryTeal),
                    title: const Text('Dark Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    trailing: Switch(
                      value: isDark,
                      activeColor: AppColors.primaryTeal,
                      onChanged: (val) => state.toggleTheme(),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(isDark, 'Security Settings & Password', Icons.security),
                  const Divider(height: 1),
                  _buildSettingTile(isDark, 'Emergency Contact Information', Icons.contact_phone),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                await state.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out of Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.riskCritical.withOpacity(0.12),
                foregroundColor: AppColors.riskCritical,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(bool isDark, {required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 18),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 9, color: AppColors.getTextSecondary(isDark))),
        ],
      ),
    );
  }

  Widget _buildBioRow(bool isDark, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryTeal, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(bool isDark, String text, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryTeal, size: 20),
      title: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.chevron_right, color: AppColors.getTextSecondary(isDark), size: 18),
      onTap: () {},
    );
  }

  // ==========================================
  // CUSTOM BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavBar(BuildContext context, bool isDark) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.health_and_safety_rounded, 'label': 'Checkup'},
      {'icon': Icons.description_rounded, 'label': 'Reports'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Schedule'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorder(isDark).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final isSelected = _currentIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primaryTeal.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        items[index]['icon'],
                        color: isSelected 
                            ? AppColors.primaryTeal 
                            : AppColors.getTextSecondary(isDark),
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          items[index]['label'],
                          style: const TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
