import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportScreen extends StatefulWidget {
  const PdfReportScreen({Key? key}) : super(key: key);

  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

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
    
    // This will trigger a file save dialog on web or desktop, and a share sheet on mobile.
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'HealthGuard_AI_Medical_Report.pdf',
    );

    setState(() {
      _downloadProgress = 1.0;
      _isDownloading = false;
    });
  }

  void _shareReport() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Share Report via',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.message, 'Messages'),
                _buildShareOption(Icons.email, 'Email'),
                _buildShareOption(Icons.cloud_upload, 'Google Drive'),
                _buildShareOption(Icons.copy, 'Copy Link'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
          child: Icon(icon, color: AppColors.primaryTeal),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final user = state.currentUser;
    final assessment = ModalRoute.of(context)!.settings.arguments as AssessmentModel?;

    if (user == null || assessment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medical Report')),
        body: const Center(child: Text('Invalid user or assessment state.')),
      );
    }

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
                      onPressed: _isDownloading ? null : () => _downloadReport(assessment, user),
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
                    onPressed: _shareReport,
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
                    _buildReportInfoRow('Full Name:', user.fullName),
                    _buildReportInfoRow('Email Address:', user.email),
                    _buildReportInfoRow('Mobile Phone:', user.mobileNumber),
                    _buildReportInfoRow('Demographics:', 'Age: ${user.age} yrs | Gender: ${user.gender}'),
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
