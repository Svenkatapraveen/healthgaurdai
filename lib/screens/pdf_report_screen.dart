import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';

class PdfReportScreen extends StatefulWidget {
  const PdfReportScreen({Key? key}) : super(key: key);

  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  void _downloadReport() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _downloadProgress = i / 10.0;
      });
    }

    setState(() {
      _isDownloading = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Completed'),
        content: const Text(
          'HealthGuard_AI_Medical_Report.pdf has been stored successfully in your device\'s local storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
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
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadReport,
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              child: Column(
                children: [
                  LinearProgressIndicator(value: _downloadProgress, color: AppColors.primaryTeal),
                  const SizedBox(height: 6),
                  Text(
                    'Generating PDF Report... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
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
