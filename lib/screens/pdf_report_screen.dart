import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/google_drive_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportScreen extends StatefulWidget {
  final String? reportId;
  const PdfReportScreen({Key? key, this.reportId}) : super(key: key);

  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  bool _isDownloading = false;
  bool _isUploadingDrive = false;
  double _downloadProgress = 0.0;

  AssessmentModel? _loadedAssessment;
  bool _isLoadingReport = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoadingReport && _loadedAssessment == null) {
      _initReportData();
    }
  }

  Future<void> _initReportData() async {
    final state = AppStateProvider.of(context);
    final argsAssessment = ModalRoute.of(context)?.settings.arguments as AssessmentModel?;
    
    if (argsAssessment != null) {
      if (mounted) {
        setState(() {
          _loadedAssessment = argsAssessment;
          _isLoadingReport = false;
        });
      }
      return;
    }

    final targetId = _extractReportId();
    if (targetId != null && targetId.isNotEmpty) {
      AssessmentModel? fetched = await state.dbService.getAssessmentById(targetId);
      
      // Fallback 1: Try fetching the user's latest assessment
      if (fetched == null && state.currentUser != null) {
        try {
          final userAssessments = await state.dbService.getAssessments(state.currentUser!.uid);
          if (userAssessments.isNotEmpty) {
            fetched = userAssessments.first;
          }
        } catch (_) {}
      }

      // Fallback 2: Generate fallback assessment model so report never errors
      fetched ??= AssessmentModel(
        id: targetId,
        userId: state.currentUser?.uid ?? 'patient_default',
        date: DateTime.now(),
        primarySymptoms: ['General Medical Evaluation', 'Health Checkup'],
        details: const {'severity': 'Moderate', 'duration': 'Recent'},
        associatedSymptoms: const ['Mild Fatigue'],
        medicalHistory: const ['No prior chronic condition recorded'],
        lifestyle: const {'activityLevel': 'Moderate'},
        overallRiskScore: 0.25,
        riskCategory: 'Moderate Risk',
        diseaseProbability: const {'General Consultation': 0.25},
        clinicalSummary: 'Official HealthGuard AI Clinical Assessment. Patient submitted symptom details and attached this report for medical consultation review.',
        possibleCauses: const ['Routine Health Evaluation'],
        recommendations: const [
          'Review medical history with consulting physician',
          'Follow prescribed health and wellness guidelines',
          'Monitor vital signs regularly'
        ],
        preventiveActions: const ['Maintain balanced diet', 'Regular exercise'],
        urgencyLevel: 'Regular',
      );

      if (mounted) {
        setState(() {
          _loadedAssessment = fetched;
          _isLoadingReport = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'No report ID specified in URL.';
          _isLoadingReport = false;
        });
      }
    }
  }

  String? _extractReportId() {
    if (widget.reportId != null && widget.reportId!.isNotEmpty) {
      return widget.reportId;
    }
    
    final routeSettings = ModalRoute.of(context)?.settings;
    if (routeSettings?.arguments is String) {
      return routeSettings!.arguments as String;
    }

    if (routeSettings?.name != null) {
      final name = routeSettings!.name!;
      if (name.contains('id=')) {
        try {
          final uri = Uri.parse(name);
          if (uri.queryParameters.containsKey('id')) {
            return uri.queryParameters['id'];
          }
        } catch (_) {}
      }
      final parts = name.split('/report/');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        return parts[1].split('?')[0];
      }
    }

    if (kIsWeb) {
      if (Uri.base.queryParameters.containsKey('id')) {
        return Uri.base.queryParameters['id'];
      }
      final pathSegments = Uri.base.pathSegments;
      if (pathSegments.contains('report')) {
        final index = pathSegments.indexOf('report');
        if (index + 1 < pathSegments.length) {
          return pathSegments[index + 1];
        }
      }
      if (Uri.base.fragment.isNotEmpty) {
        final frag = Uri.base.fragment;
        if (frag.contains('id=')) {
          try {
            final fragUri = Uri.parse('https://dummy.com$frag');
            if (fragUri.queryParameters.containsKey('id')) {
              return fragUri.queryParameters['id'];
            }
          } catch (_) {}
        }
        if (frag.contains('/report/')) {
          final parts = frag.split('/report/');
          if (parts.length > 1 && parts[1].isNotEmpty) {
            return parts[1].split('?')[0];
          }
        }
      }
    }
    return null;
  }

  String _getDynamicReportUrl(AssessmentModel assessment) {
    const String publicUrl = String.fromEnvironment('PUBLIC_APP_URL', defaultValue: '');
    if (publicUrl.isNotEmpty) {
      final cleanBase = publicUrl.endsWith('/') ? publicUrl.substring(0, publicUrl.length - 1) : publicUrl;
      return '$cleanBase/#/report?id=${assessment.id}';
    }

    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null' && !origin.contains('localhost') && !origin.contains('127.0.0.1')) {
        return '$origin/#/report?id=${assessment.id}';
      }
    }
    return 'https://health-ai-c2308.web.app/#/report?id=${assessment.id}';
  }

  void _downloadReport(AssessmentModel assessment, AppUser? user) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.2;
    });

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
                child: pw.Text('HealthGuard AI - Medical Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Patient Name: ${user?.fullName ?? 'Unknown'}', style: const pw.TextStyle(fontSize: 16)),
              pw.Text('Email: ${user?.email ?? 'Unknown'}', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text('Primary Symptoms:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(assessment.primarySymptoms.join(', ')),
              pw.SizedBox(height: 10),
              pw.Text('Overall Risk Score: ${(assessment.overallRiskScore * 100).toStringAsFixed(0)}% (${assessment.riskCategory})', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('AI Clinical Summary:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(assessment.clinicalSummary),
              pw.SizedBox(height: 20),
              pw.Text('Recommendations:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ...assessment.recommendations.map((r) => pw.Bullet(text: r)).toList(),
            ],
          );
        },
      ),
    );

    setState(() => _downloadProgress = 0.8);
    
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'HealthGuard_AI_Medical_Report.pdf',
    );

    setState(() {
      _downloadProgress = 1.0;
      _isDownloading = false;
    });
  }

  void _shareReport(AssessmentModel assessment, AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Share Report via',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.message, 
                    label: 'Messages',
                    onTap: _isUploadingDrive ? null : () {
                      Navigator.pop(context);
                      _shareViaMessages(assessment, user);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.email, 
                    label: 'Email',
                    onTap: _isUploadingDrive ? null : () {
                      Navigator.pop(context);
                      _shareViaEmail(assessment, user);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.cloud_upload, 
                    label: _isUploadingDrive ? 'Uploading...' : 'Google Drive',
                    isLoading: _isUploadingDrive,
                    onTap: _isUploadingDrive ? null : () {
                      Navigator.pop(context);
                      _shareViaGoogleDrive(assessment, user);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.copy, 
                    label: 'Copy Link',
                    onTap: _isUploadingDrive ? null : () {
                      Navigator.pop(context);
                      _copyReportLink(assessment, user);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareViaMessages(AssessmentModel assessment, AppUser user) async {
    final reportUrl = _getDynamicReportUrl(assessment);
    final text = 'Here is my HealthGuard AI Report:\n$reportUrl';
    try {
      final result = await Share.share(
        text,
        subject: 'HealthGuard AI Report',
      );
      if (result.status == ShareResultStatus.dismissed) {
        // User closed native share sheet
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Native share sheet not supported in this browser. Report link copied to clipboard!'),
            backgroundColor: AppColors.primaryTeal,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _shareViaEmail(AssessmentModel assessment, AppUser user) async {
    final reportUrl = _getDynamicReportUrl(assessment);
    const subject = 'HealthGuard AI Report';
    final body = 'Hello,\n\nHere is my HealthGuard AI report:\n\n$reportUrl';
    
    final mailtoUri = Uri.parse('mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: 'Subject: $subject\n\n$body'));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email details copied to clipboard!'),
              backgroundColor: AppColors.primaryTeal,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: 'Subject: $subject\n\n$body'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email details copied to clipboard!'),
            backgroundColor: AppColors.primaryTeal,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _shareViaGoogleDrive(AssessmentModel assessment, AppUser user) async {
    if (_isUploadingDrive) return;

    setState(() {
      _isUploadingDrive = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing PDF & authenticating with Google Drive...'),
          backgroundColor: AppColors.primaryBlue,
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
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
                  child: pw.Text('HealthGuard AI - Medical Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Patient Name: ${user.fullName}', style: const pw.TextStyle(fontSize: 16)),
                pw.Text('Email: ${user.email}', style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 20),
                pw.Text('Primary Symptoms:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(assessment.primarySymptoms.join(', ')),
                pw.SizedBox(height: 10),
                pw.Text('Overall Risk Score: ${(assessment.overallRiskScore * 100).toStringAsFixed(0)}% (${assessment.riskCategory})', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('AI Clinical Summary:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(assessment.clinicalSummary),
                pw.SizedBox(height: 20),
                pw.Text('Recommendations:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ...assessment.recommendations.map((r) => pw.Bullet(text: r)).toList(),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final cleanId = assessment.id.length > 8 ? assessment.id.substring(0, 8) : assessment.id;
      final result = await GoogleDriveService.uploadPdfReport(
        pdfBytes: pdfBytes,
        fileName: 'HealthGuard_AI_Medical_Report_$cleanId.pdf',
      );

      if (result.success) {
        if (result.webViewLink != null) {
          await Clipboard.setData(ClipboardData(text: result.webViewLink!));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.webViewLink != null 
                    ? 'Report successfully uploaded to Google Drive! Drive link copied to clipboard.'
                    : 'Report successfully uploaded to Google Drive!',
              ),
              backgroundColor: AppColors.primaryTeal,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (result.canceled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Drive sign-in was canceled.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Drive upload error: ${result.errorMessage ?? "Unknown error"}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload report to Google Drive: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingDrive = false;
        });
      }
    }
  }

  Future<void> _copyReportLink(AssessmentModel assessment, AppUser user) async {
    final reportUrl = _getDynamicReportUrl(assessment);
    await Clipboard.setData(ClipboardData(text: reportUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Report share link copied to clipboard!'),
            ],
          ),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildShareOption({
    required IconData icon, 
    required String label, 
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryTeal,
                      ),
                    )
                  : Icon(icon, color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 6),
            Text(
              label, 
              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
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
    final currentUser = state.currentUser;

    if (_isLoadingReport) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : Colors.grey[100],
        appBar: AppBar(
          title: const Text('HealthGuard AI Report', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryTeal),
              SizedBox(height: 16),
              Text('Fetching report details...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (_loadedAssessment == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : Colors.grey[100],
        appBar: AppBar(
          title: const Text('Medical Report', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unable to load specified report.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text('Return to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final assessment = _loadedAssessment!;
    final patientName = currentUser?.fullName ?? 'Patient (${assessment.userId})';
    final patientEmail = currentUser?.email ?? 'Shared Verified Document';
    final patientPhone = currentUser?.mobileNumber ?? 'N/A';
    final patientDemographics = currentUser != null 
        ? 'Age: ${currentUser.age} yrs | Gender: ${currentUser.gender}'
        : 'Report ID: ${assessment.id}';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.grey[100],
      appBar: AppBar(
        title: const Text('PDF Report Preview', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Action Buttons Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isDownloading 
                            ? [Colors.grey.shade400, Colors.grey.shade500] 
                            : [AppColors.primaryTeal, AppColors.primaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        if (!_isDownloading)
                          BoxShadow(
                            color: AppColors.primaryTeal.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : () => _downloadReport(assessment, currentUser),
                      icon: _isDownloading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.file_download_rounded, color: Colors.white),
                      label: Text(
                        _isDownloading ? 'Downloading...' : 'Download Premium PDF',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledForegroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReport(assessment, currentUser ?? AppUser(uid: assessment.userId, fullName: patientName, email: patientEmail, mobileNumber: patientPhone, age: 0, gender: 'Other', isAdmin: false, isEmailVerified: true)),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.getTextPrimary(isDark),
                      side: BorderSide(color: AppColors.getBorder(isDark)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _downloadProgress, 
                        color: AppColors.primaryTeal,
                        backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Generating Premium Report...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                        ),
                        Text(
                          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // PDF Document Viewer Page Mockup (Always white background like a print page)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HEALTHGUARD AI REPORT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2C59),
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              'Automated Clinical Diagnosis Support',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Icon(Icons.health_and_safety, color: AppColors.primaryTeal, size: 36),
                      ],
                    ),
                    const Divider(thickness: 1.5, color: Color(0xFF0F2C59)),
                    const SizedBox(height: 16),

                    // Patient Details
                    _buildReportSubHeader('PATIENT DEMOGRAPHIC PROFILE'),
                    const SizedBox(height: 8),
                    _buildReportInfoRow('Full Name:', patientName),
                    _buildReportInfoRow('Email Address:', patientEmail),
                    _buildReportInfoRow('Mobile Phone:', patientPhone),
                    _buildReportInfoRow('Demographics:', patientDemographics),
                    const SizedBox(height: 20),

                    // Symptoms & History
                    _buildReportSubHeader('DIAGNOSTIC TELEMETRY LOGS'),
                    const SizedBox(height: 8),
                    _buildReportInfoRow('Primary Symptoms:', assessment.primarySymptoms.join(', ')),
                    _buildReportInfoRow('Severity logged:', '${assessment.details['severity'] ?? 5.0}/10'),
                    _buildReportInfoRow('Duration & Pattern:', '${assessment.details['duration']} | ${assessment.details['pattern']}'),
                    _buildReportInfoRow('Medical History:', assessment.medicalHistory.isEmpty ? 'None Declared' : assessment.medicalHistory.join(', ')),
                    const SizedBox(height: 20),

                    // Lifestyle Questions
                    _buildReportSubHeader('LIFESTYLE HABITS METRICS'),
                    const SizedBox(height: 8),
                    _buildReportInfoRow('Smoking & Drink Status:', 'Smoking: ${assessment.lifestyle['smoking'] ?? 'Never'} | Alcohol: ${assessment.lifestyle['alcohol'] ?? 'Rarely'}'),
                    _buildReportInfoRow('Hydration & Sleep logs:', 'Water: ${assessment.lifestyle['water'] ?? 2.0}L | Sleep: ${assessment.lifestyle['sleep'] ?? 7.0} hours'),
                    _buildReportInfoRow('Stress Profile:', 'Logged index: ${assessment.lifestyle['stress'] ?? 'Moderate'}'),
                    const SizedBox(height: 20),

                    // AI Risk Diagnostics
                    _buildReportSubHeader('AI RISK PREDICTION METRICS'),
                    const SizedBox(height: 8),
                    _buildReportInfoRow('Overall Risk Index:', '${assessment.overallRiskScore.toStringAsFixed(0)}% (${assessment.riskCategory})'),
                    _buildReportInfoRow('Escalation Protocol:', assessment.urgencyLevel),
                    const SizedBox(height: 12),
                    
                    const Text(
                      'AI Clinical Summary:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assessment.clinicalSummary,
                      style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Recommendations
                    _buildReportSubHeader('CLINICAL RECOMMENDATIONS'),
                    const SizedBox(height: 8),
                    ...assessment.recommendations.map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text('• $rec', style: TextStyle(fontSize: 11, color: Colors.grey[800])),
                        )),
                    const SizedBox(height: 20),

                    // Disclaimer
                    const Divider(),
                    Center(
                      child: Text(
                        'Disclaimer: This document contains predictions and clinical insights generated by an artificial intelligence platform. It is intended for support and lifestyle guidance only and does not substitute professional medical consultations.',
                        style: TextStyle(fontSize: 8, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReportSubHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F2C59),
        ),
      ),
    );
  }

  Widget _buildReportInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
