import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_chart.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../utils/web_download_helper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTabIndex = 0;

  // Mock Admin State data
  final List<_AdminUserMock> _users = [
    _AdminUserMock(id: 'usr_01', name: 'Alex Carter', email: 'user@gmail.com', status: 'Active', age: 29),
    _AdminUserMock(id: 'usr_02', name: 'John Miller', email: 'john.miller@gmail.com', status: 'Active', age: 45),
    _AdminUserMock(id: 'usr_03', name: 'Clarissa Finch', email: 'finch.c@gmail.com', status: 'Blocked', age: 62),
    _AdminUserMock(id: 'usr_04', name: 'Markus Rowe', email: 'markus@gmail.com', status: 'Active', age: 34),
  ];

  final List<_HighRiskMockPatient> _criticalPatients = [
    _HighRiskMockPatient(name: 'Clarissa Finch', riskScore: 82.0, condition: 'Severe Dyspnea', lastChecked: '10 mins ago'),
    _HighRiskMockPatient(name: 'John Miller', riskScore: 78.0, condition: 'Angina Pectoris', lastChecked: '1 hour ago'),
  ];

  void _blockUser(String id) {
    setState(() {
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        final current = _users[index];
        _users[index] = _AdminUserMock(
          id: current.id,
          name: current.name,
          email: current.email,
          status: current.status == 'Blocked' ? 'Active' : 'Blocked',
          age: current.age,
        );
      }
    });
  }

  void _deleteUser(String id) {
    setState(() {
      _users.removeWhere((u) => u.id == id);
    });
  }

  Future<void> _handleViewReport(AppointmentModel appt) async {
    print('Debug Appointment Data: id=${appt.id}, reportUrl=${appt.reportUrl}, reportStoragePath=${appt.reportStoragePath}, reportFileName=${appt.reportFileName}');

    String targetUrl = appt.reportUrl.trim();

    if (targetUrl.isEmpty && appt.reportStoragePath.isNotEmpty) {
      try {
        targetUrl = await FirebaseStorage.instance
            .ref(appt.reportStoragePath)
            .getDownloadURL();
      } catch (e) {
        print('Firebase Storage getDownloadURL error: $e');
      }
    }

    if (targetUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical report is not available.'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
      return;
    }

    // Convert remote domain to local origin when running locally on web
    if (targetUrl.contains('health-ai-c2308.web.app') || targetUrl.contains('/#/report?id=')) {
      if (kIsWeb && Uri.base.origin.isNotEmpty && !Uri.base.origin.contains('null')) {
        String reportId = appt.id;
        if (targetUrl.contains('id=')) {
          reportId = targetUrl.split('id=').last.split('&')[0];
        }
        targetUrl = '${Uri.base.origin}/#/report?id=$reportId';
      }
    }

    try {
      await openPdfUrlInNewTab(targetUrl);
    } catch (e) {
      print('Error launching View Report URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access the medical report. Please try again.'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generateMedicalReportPdfBytes(AppointmentModel appt) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('HealthGuard AI - Clinical Medical Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text('CONFIDENTIAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Patient Name: ${appt.patientName}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Mobile Number: ${appt.mobileNumber}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Doctor Specialty: ${appt.doctorSpecialty}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Scheduled Date: ${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year} at ${appt.preferredDateTime.hour}:${appt.preferredDateTime.minute.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text('Medical Assessment File: ${appt.reportFileName.isNotEmpty ? appt.reportFileName : 'HealthGuard_AI_Medical_Report.pdf'}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Status: ${appt.status}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Text('Health Assessment Summary:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Patient completed AI preliminary symptom analysis and attached this official report for consultation review.', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 30),
              pw.Text('HealthGuard AI Enterprise System • Confidential Patient Record', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );
    return await pdf.save();
  }

  Future<void> _handleDownloadReport(AppointmentModel appt) async {
    print('Debug Download Report Data: id=${appt.id}, reportUrl=${appt.reportUrl}, reportStoragePath=${appt.reportStoragePath}, reportFileName=${appt.reportFileName}');

    String targetUrl = appt.reportUrl.trim();
    final fileName = appt.reportFileName.isNotEmpty
        ? appt.reportFileName
        : 'HealthGuard_AI_Medical_Report.pdf';

    if (targetUrl.isEmpty && appt.reportStoragePath.isNotEmpty) {
      try {
        targetUrl = await FirebaseStorage.instance
            .ref(appt.reportStoragePath)
            .getDownloadURL();
      } catch (e) {
        print('Firebase Storage getDownloadURL error: $e');
      }
    }

    Uint8List? pdfBytes;
    if (appt.reportStoragePath.isNotEmpty) {
      try {
        pdfBytes = await FirebaseStorage.instance
            .ref(appt.reportStoragePath)
            .getData(10 * 1024 * 1024);
      } catch (e) {
        print('Firebase Storage getData error: $e');
      }
    }

    if (pdfBytes == null && targetUrl.startsWith('http') && !targetUrl.contains('/#/report?id=')) {
      try {
        final res = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          pdfBytes = res.bodyBytes;
        }
      } catch (e) {
        print('HTTP download error: $e');
      }
    }

    // Dynamic PDF bytes generation fallback if file bytes are unavailable
    if (pdfBytes == null) {
      try {
        pdfBytes = await _generateMedicalReportPdfBytes(appt);
      } catch (e) {
        print('Error generating dynamic PDF bytes: $e');
      }
    }

    try {
      await downloadPdfFileFromUrl(targetUrl, fileName, pdfBytes);
    } catch (e) {
      print('Error executing Download Report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to download the report. Please try again.'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
  }

  Widget _buildAvatarWidget(String pic, {double size = 16}) {
    IconData icon = Icons.person;
    if (pic == 'admin_avatar_1') {
      icon = Icons.support_agent;
    } else if (pic == 'admin_avatar_2') {
      icon = Icons.local_hospital;
    } else if (pic == 'admin_avatar_3') {
      icon = Icons.security;
    } else if (pic == 'admin_avatar_4') {
      icon = Icons.engineering;
    }
    return Icon(icon, color: AppColors.accentCyan, size: size);
  }

  void _showAvatarPickerDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose your enterprise security avatar:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption(context, state, 'admin_avatar_1', Icons.support_agent, 'Tech Support'),
                _buildAvatarOption(context, state, 'admin_avatar_2', Icons.local_hospital, 'Medical Officer'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption(context, state, 'admin_avatar_3', Icons.security, 'Security Chief'),
                _buildAvatarOption(context, state, 'admin_avatar_4', Icons.engineering, 'Dev Ops'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOption(BuildContext context, AppState state, String code, IconData icon, String label) {
    final isSelected = state.currentUser?.profilePic == code;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await state.updateAdminProfile(
          name: state.currentUser!.fullName,
          email: state.currentUser!.email,
          profilePic: code,
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentCyan.withOpacity(0.15) : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.accentCyan : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accentCyan, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (idx) => setState(() => _currentTabIndex = idx),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      selectedItemColor: AppColors.accentCyan,
      unselectedItemColor: AppColors.getTextSecondary(isDark),
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Appts'),
        BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: 'Critical'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    // Strict Role verification Guard
    if (state.currentUser == null || !state.currentUser!.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_outlined, color: AppColors.riskCritical, size: 80),
                const SizedBox(height: 20),
                Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                ),
                const SizedBox(height: 10),
                Text(
                  'Access Denied. Administrator privileges required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.getTextSecondary(isDark)),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Welcome', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.accentCyan, size: 24),
            const SizedBox(width: 8),
            const Text(
              'HG Enterprise Portal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Notifications icon
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
          
          // User profile picture and name display
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accentCyan.withOpacity(0.15),
                child: _buildAvatarWidget(state.currentUser?.profilePic ?? ''),
              ),
              const SizedBox(width: 8),
              if (!isMobile) ...[
                Text(
                  state.currentUser?.fullName.split(' ').first ?? 'Admin',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
              ]
            ],
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNavBar(isDark) : null,
      body: Row(
        children: [
          // Sidebar Rail for Tablet/Desktop
          if (!isMobile)
            NavigationRail(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              labelType: NavigationRailLabelType.selected,
              selectedIconTheme: const IconThemeData(color: AppColors.accentCyan),
              unselectedIconTheme: IconThemeData(color: AppColors.getTextSecondary(isDark)),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.people_outline), label: Text('Users')),
                NavigationRailDestination(icon: Icon(Icons.event_note_outlined), label: Text('Appts')),
                NavigationRailDestination(icon: Icon(Icons.warning_amber_rounded), label: Text('Critical')),
                NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profile')),
              ],
            ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _buildSelectedTab(isDark, state),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSelectedTab(bool isDark, AppState state) {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeTab(isDark, state);
      case 1:
        return _buildUsersTab(isDark);
      case 2:
        return _buildAppointmentsTab(isDark, state);
      case 3:
        return _buildCriticalTab(isDark);
      case 4:
        return _buildProfileTab(isDark, state);
      default:
        return const SizedBox();
    }
  }

  // ==========================================
  // TAB 1: KPI HOME & ANALYTICS
  // ==========================================
  Widget _buildHomeTab(bool isDark, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Clinical Network Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 16),
        
        // Compact Responsive KPI statistics Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            int crossAxisCount = 4;
            double childAspectRatio = 2.2;
            if (width < 600) {
              crossAxisCount = 1;
              childAspectRatio = 3.2;
            } else if (width < 1000) {
              crossAxisCount = 2;
              childAspectRatio = 2.4;
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
              children: [
                StreamBuilder<int>(
                  stream: state.streamUserCount(),
                  builder: (context, snapshot) {
                    final val = snapshot.data ?? 104;
                    return _buildCompactKpiCard(
                      isDark,
                      'Total Registrations',
                      '$val',
                      'Registered Patients',
                      Icons.people_alt_outlined,
                      AppColors.accentCyan,
                      '+12%',
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: state.streamAssessmentCount(),
                  builder: (context, snapshot) {
                    final val = snapshot.data ?? 3482;
                    return _buildCompactKpiCard(
                      isDark,
                      'Assessments Run',
                      '$val',
                      'AI Completed',
                      Icons.biotech_outlined,
                      AppColors.primaryTeal,
                      '+8.4%',
                    );
                  },
                ),
                StreamBuilder<List<AppointmentModel>>(
                  stream: state.streamAllAppointmentsAdmin(),
                  builder: (context, snapshot) {
                    final appts = snapshot.data ?? [];
                    final count = appts.length;
                    final pending = appts.where((a) => a.status == 'Pending').length;
                    return _buildCompactKpiCard(
                      isDark,
                      'Appointments',
                      '$count',
                      '$pending Pending / Scheduled',
                      Icons.calendar_today_outlined,
                      Colors.purpleAccent,
                      '$pending pending',
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: state.streamAlertCount(),
                  builder: (context, snapshot) {
                    final val = snapshot.data ?? 5;
                    return _buildCompactKpiCard(
                      isDark,
                      'Alerts',
                      '$val',
                      'Requires Attention',
                      Icons.warning_amber_rounded,
                      AppColors.riskCritical,
                      'Action Required',
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Analytics user growth chart
        Text(
          'Monthly Registration Growth',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: CustomChart(
            dataPoints: const [20, 35, 48, 60, 85, 120, 150],
            labels: const ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'],
            type: ChartType.line,
            color: AppColors.accentCyan,
            height: 160,
            maxValue: 200,
          ),
        ),
        const SizedBox(height: 24),

        // Risk distribution stats
        Text(
          'Patient Risk Profiles Distribution',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: CustomChart(
            dataPoints: const [70, 45, 18, 5],
            labels: const ['Low', 'Mod', 'High', 'Crit'],
            type: ChartType.bar,
            color: AppColors.primaryTeal,
            height: 160,
            maxValue: 100,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCompactKpiCard(
    bool isDark,
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String badgeText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? color.withOpacity(0.25) : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(isDark),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.getTextSecondary(isDark),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: USER MANAGEMENT
  // ==========================================
  Widget _buildUsersTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Directory Management',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 16),
        ..._users.map((usr) {
          final isBlocked = usr.status == 'Blocked';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accentCyan.withOpacity(0.15),
                  child: Text(usr.name.substring(0, 1), style: const TextStyle(color: AppColors.accentCyan)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usr.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${usr.email} • Age: ${usr.age}', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark))),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isBlocked ? Icons.lock_open : Icons.block,
                        color: isBlocked ? Colors.green : AppColors.riskModerate,
                        size: 18,
                      ),
                      tooltip: isBlocked ? 'Unblock user' : 'Block user',
                      onPressed: () => _blockUser(usr.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.riskCritical, size: 18),
                      tooltip: 'Remove user record',
                      onPressed: () => _deleteUser(usr.id),
                    ),
                  ],
                )
              ],
            ),
          );
        }).toList()
      ],
    );
  }

  // ==========================================
  // TAB 3: APPOINTMENT ACTIONS
  // ==========================================
  Widget _buildAppointmentsTab(bool isDark, AppState state) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: state.streamAllAppointmentsAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final appts = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appointment Request Hub',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${appts.length} Total',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (appts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'No active clinical appointment requests.',
                    style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13),
                  ),
                ),
              )
            else
              ...appts.map((appt) {
                Color statusColor = Colors.grey;
                if (appt.status == 'Approved') statusColor = AppColors.primaryGreen;
                else if (appt.status == 'Pending') statusColor = AppColors.riskModerate;
                else if (appt.status == 'Rejected') statusColor = AppColors.riskCritical;

                final hasReport = appt.reportUrl.isNotEmpty;
                final reportName = appt.reportFileName.isNotEmpty 
                    ? appt.reportFileName 
                    : (hasReport ? 'HealthGuard_Medical_Report.pdf' : 'No Report Uploaded');

                final dateStr = '${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year}';
                final timeStr = '${appt.preferredDateTime.hour.toString().padLeft(2, '0')}:${appt.preferredDateTime.minute.toString().padLeft(2, '0')}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              appt.patientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                appt.status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Doctor Specialty: ${appt.doctorSpecialty} • Phone: ${appt.mobileNumber}',
                          style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                        ),
                        Text(
                          'Schedule Date: $dateStr • Time: $timeStr',
                          style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                        ),
                        const SizedBox(height: 12),

                        // Medical Report Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasReport ? AppColors.primaryTeal.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hasReport ? Icons.picture_as_pdf : Icons.report_off_outlined,
                                    color: hasReport ? Colors.redAccent : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Medical Report / Health Assessment',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: hasReport ? AppColors.primaryTeal : Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          reportName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: hasReport ? AppColors.getTextPrimary(isDark) : Colors.grey,
                                            fontStyle: hasReport ? FontStyle.normal : FontStyle.italic,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (hasReport)
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _handleViewReport(appt),
                                      icon: const Icon(Icons.visibility, size: 14),
                                      label: const Text('View Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryTeal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _handleDownloadReport(appt),
                                      icon: const Icon(Icons.download, size: 14),
                                      label: const Text('Download Report', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.accentCyan,
                                        side: const BorderSide(color: AppColors.accentCyan),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Report Not Available',
                                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Action buttons
                        if (appt.status == 'Pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  await state.updateAppointmentStatusAdmin(appt.id, 'Rejected');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Appointment rejected successfully.'),
                                        backgroundColor: AppColors.riskCritical,
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.riskCritical,
                                  side: const BorderSide(color: AppColors.riskCritical),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                                child: const Text('Reject', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  await state.updateAppointmentStatusAdmin(appt.id, 'Approved');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Appointment approved successfully.'),
                                        backgroundColor: AppColors.primaryGreen,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                                child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                );
              }).toList()
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 4: HIGH-RISK CRITICAL PATIENTS
  // ==========================================
  Widget _buildCriticalTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Critical Patient Alerts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 16),
        
        ..._criticalPatients.map((pat) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.riskCritical.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.riskCritical.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.riskCritical, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      Text('Condition: ${pat.condition} • Alerted: ${pat.lastChecked}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.riskCritical,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${pat.riskScore.toStringAsFixed(0)}% RISK',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                )
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        
        const Text(
          'Protocol Advice: Trigger ambulance routing or contact critical cases immediately to confirm emergency care.',
          style: TextStyle(color: AppColors.riskCritical, fontSize: 11, fontStyle: FontStyle.italic),
        )
      ],
    );
  }

  // ==========================================
  // TAB 5: ADMIN PROFILE SETTINGS
  // ==========================================
  Widget _buildProfileTab(bool isDark, AppState state) {
    final adminUser = state.currentUser!;
    
    // We will use local text controllers
    final nameController = TextEditingController(text: adminUser.fullName);
    final emailController = TextEditingController(text: adminUser.email);
    
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final profileFormKey = GlobalKey<FormState>();
    final passwordFormKey = GlobalKey<FormState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Security Profile Console',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 20),
        
        // Large Avatar Banner Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showAvatarPickerDialog(context, state),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.accentCyan.withOpacity(0.12),
                      child: _buildAvatarWidget(adminUser.profilePic ?? '', size: 40),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.accentCyan, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                adminUser.fullName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                adminUser.email,
                style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SYSTEM ADMINISTRATOR',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Profile Info Edit Form
        Text(
          'General Administration Credentials',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.12)),
          ),
          child: Form(
            key: profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) => val != null && val.isNotEmpty ? null : 'Name cannot be empty.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Security Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) => val != null && val.contains('@') ? null : 'Enter correct admin email.',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!profileFormKey.currentState!.validate()) return;
                    await state.updateAdminProfile(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      profilePic: adminUser.profilePic,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin profile details updated successfully.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Change Password Form
        Text(
          'Enterprise Password Security',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.12)),
          ),
          child: Form(
            key: passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (val) => val != null && val.length >= 3 ? null : 'Password must be min 3 chars.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_clock_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Confirm password.';
                    if (val != passwordController.text) return 'Passwords do not match.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!passwordFormKey.currentState!.validate()) return;
                    await state.updateAdminPassword(
                      newPassword: passwordController.text,
                    );
                    if (!mounted) return;
                    passwordController.clear();
                    confirmPasswordController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Administrator password updated successfully.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Log out button
        OutlinedButton.icon(
          onPressed: () async {
            await state.logout();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/welcome');
          },
          icon: const Icon(Icons.logout, color: AppColors.riskCritical),
          label: const Text('Terminate Session (Log Out)', style: TextStyle(color: AppColors.riskCritical, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.riskCritical),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _AdminUserMock {
  final String id;
  final String name;
  final String email;
  final String status;
  final int age;

  _AdminUserMock({required this.id, required this.name, required this.email, required this.status, required this.age});
}

class _HighRiskMockPatient {
  final String name;
  final double riskScore;
  final String condition;
  final String lastChecked;

  _HighRiskMockPatient({required this.name, required this.riskScore, required this.condition, required this.lastChecked});
}
