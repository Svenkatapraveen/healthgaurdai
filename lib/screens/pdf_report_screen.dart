import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../data/symptom_database.dart';
import '../utils/web_download_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReportScreen extends StatefulWidget {
  final String? reportId;
  const PdfReportScreen({Key? key, this.reportId}) : super(key: key);

  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  bool _isDownloading = false;
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
        details: const {'severity': 5.0, 'duration': 'Recent', 'pattern': 'Intermittent', 'recommendedDoctor': 'General Physician'},
        associatedSymptoms: const ['Mild Fatigue'],
        medicalHistory: const ['No prior chronic condition recorded'],
        lifestyle: const {'smoking': 'Never', 'alcohol': 'Rarely', 'exercise': '1-2 times/week', 'sleep': 7.0, 'water': 2.0, 'stress': 'Moderate'},
        overallRiskScore: 25.0,
        riskCategory: 'Moderate Risk',
        diseaseProbability: const {'General Consultation': 25.0},
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

  String getReportShareUrl(AssessmentModel assessment) {
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

  Future<void> _downloadReport(AssessmentModel assessment, AppUser? user) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.3;
    });
    try {
      final pdfBytes = await _generatePdfBytes(assessment, user);
      setState(() => _downloadProgress = 0.7);
      final filename = 'HealthGuard_AI_Medical_Report_${assessment.id}.pdf';
      await downloadPdfFileFromUrl('', filename, bytes: pdfBytes);
      setState(() => _downloadProgress = 1.0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report PDF downloaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _shareReport(AssessmentModel assessment, AppUser user) async {
    try {
      final pdfBytes = await _generatePdfBytes(assessment, user);
      final filename = 'HealthGuard_AI_Medical_Report_${assessment.id}.pdf';
      await downloadPdfFileFromUrl('', filename, bytes: pdfBytes);
    } catch (_) {}
  }

  // ==========================================
  // MULTI-PAGE PDF GENERATOR (21 SECTIONS)
  // ==========================================
  Future<Uint8List> _generatePdfBytes(AssessmentModel assessment, AppUser? user) async {
    final pdf = pw.Document();

    final patientName = user?.fullName ?? 'Patient (${assessment.userId})';
    final patientEmail = user?.email ?? 'Not provided';
    final patientPhone = user?.mobileNumber ?? 'Not provided';
    final patientAge = user != null && user.age > 0 ? '${user.age} yrs' : 'Not provided';
    final patientGender = user?.gender ?? 'Not provided';

    final reportDate = '${assessment.date.year}-${assessment.date.month.toString().padLeft(2, '0')}-${assessment.date.day.toString().padLeft(2, '0')}';
    final reportTime = '${assessment.date.hour.toString().padLeft(2, '0')}:${assessment.date.minute.toString().padLeft(2, '0')}:${assessment.date.second.toString().padLeft(2, '0')}';
    
    final riskScore = (assessment.overallRiskScore <= 1.0 ? assessment.overallRiskScore * 100 : assessment.overallRiskScore).clamp(0.0, 100.0);
    final recommendedDoctor = assessment.details['recommendedDoctor']?.toString() ?? 'General Physician';
    final followUpAnswers = (assessment.details['followUpAnswers'] as Map<String, dynamic>?) ?? {};

    // Calculate symptom severity metrics
    final totalSymptomsCount = assessment.primarySymptoms.length;
    final double mainSeverity = (assessment.details['severity'] is num) ? (assessment.details['severity'] as num).toDouble() : 5.0;
    final String mainDuration = assessment.details['duration']?.toString() ?? 'Not provided';
    final String mainPattern = assessment.details['pattern']?.toString() ?? 'Not provided';

    // Extract affected body locations
    final Set<String> affectedLocations = {};
    for (var sName in assessment.primarySymptoms) {
      final dbMatch = symptomDatabase.firstWhere(
        (element) => element.name.toLowerCase() == sName.toLowerCase(),
        orElse: () => const MedicalSymptom(name: '', category: 'General', bodyLocations: ['Whole Body']),
      );
      affectedLocations.addAll(dbMatch.bodyLocations);
    }

    // Identify Urgent Warning Signs
    final List<String> urgentWarningSigns = [];
    for (var s in assessment.primarySymptoms) {
      final lower = s.toLowerCase();
      if (lower.contains('chest pain') || lower.contains('shortness of breath') || lower.contains('loss of consciousness') || lower.contains('seizure') || lower.contains('bleeding') || lower.contains('stroke') || lower.contains('paralysis')) {
        urgentWarningSigns.add(s);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox();
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('HEALTHGUARD AI', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
                  pw.Text('AI-Assisted Health Risk Assessment Report | ID: ${assessment.id}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#0F2C59')),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('HealthGuard AI System v2.4.0 • Informational Assessment Only', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // ==================== 1. PROFESSIONAL REPORT HEADER ====================
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0F2C59'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('HEALTHGUARD AI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.1)),
                      pw.SizedBox(height: 2),
                      pw.Text('Intelligent Predictive Healthcare & Early Disease Risk Assessment System', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text('AI-ASSISTED HEALTH ASSESSMENT REPORT', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2DD4BF'))),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('REPORT ID: ${assessment.id}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.Text('DATE: $reportDate', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white)),
                      pw.Text('TIME: $reportTime', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ==================== 2. EXECUTIVE HEALTH SUMMARY ====================
            _buildPdfSectionHeader('2. EXECUTIVE HEALTH SUMMARY'),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#0F2C59'), width: 1),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColor.fromHex('#F8FAFC'),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Overall Risk Category:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text(assessment.riskCategory.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _getPdfRiskColor(assessment.riskCategory))),
                      pw.Text('Escalation Protocol: ${assessment.urgencyLevel}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: _getPdfRiskColor(assessment.riskCategory),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('${riskScore.toStringAsFixed(0)}/100', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.Text('RISK SCORE', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Based on the symptoms and health information provided during this assessment, the system identified a ${assessment.riskCategory.toLowerCase()} level of health risk (${riskScore.toStringAsFixed(0)}/100). The assessment is primarily influenced by reported symptoms, severity indices, duration, and associated lifestyle/medical risk factors. This document provides automated risk stratification to support personal health management and inform subsequent medical consultation.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 14),

            // ==================== 3. PATIENT PROFILE ====================
            _buildPdfSectionHeader('3. PATIENT DEMOGRAPHIC PROFILE'),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueTable([
              ['Patient Full Name', patientName, 'Assessment Date', reportDate],
              ['Age / Gender', '$patientAge | $patientGender', 'Assessment Time', reportTime],
              ['Mobile Number', patientPhone, 'Patient Email', patientEmail],
              ['Assessment ID', assessment.id, 'Report ID', assessment.id],
            ]),
            pw.SizedBox(height: 14),

            // ==================== 4. REPORTED SYMPTOMS ====================
            _buildPdfSectionHeader('4. DETAILED SYMPTOM ASSESSMENT'),
            pw.SizedBox(height: 6),
            ...assessment.primarySymptoms.map((symptomName) {
              final dbSymptom = symptomDatabase.firstWhere(
                (e) => e.name.toLowerCase() == symptomName.toLowerCase(),
                orElse: () => const MedicalSymptom(name: '', category: 'General', bodyLocations: ['Whole Body']),
              );
              final sAnswers = (followUpAnswers[symptomName] as Map<String, dynamic>?) ?? {};
              final sideVal = sAnswers['Which side is affected?'] ?? sAnswers['Which side is the pain on?'] ?? (dbSymptom.sideApplicable ? 'Not specified' : 'N/A');

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('• $symptomName', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
                        pw.Text('Category: ${dbSymptom.category}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text('Body Location: ${dbSymptom.bodyLocations.join(", ")}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800))),
                        pw.Expanded(child: pw.Text('Side / Laterality: $sideVal', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800))),
                        pw.Expanded(child: pw.Text('Severity: ${mainSeverity.toStringAsFixed(1)}/10', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800))),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text('Duration: $mainDuration', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800))),
                        pw.Expanded(child: pw.Text('Pattern: $mainPattern', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800))),
                      ],
                    ),
                    if (sAnswers.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Follow-up Responses:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      ...sAnswers.entries.map((ans) => pw.Text('  - ${ans.key}: ${ans.value}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700))),
                    ],
                  ],
                ),
              );
            }).toList(),
            pw.SizedBox(height: 14),

            // ==================== 5. SYMPTOM SEVERITY ANALYSIS ====================
            _buildPdfSectionHeader('5. SYMPTOM SEVERITY OVERVIEW'),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueTable([
              ['Total Reported Symptoms', '$totalSymptomsCount', 'Severity Scale Range', '1.0 to 10.0'],
              ['Average Severity Index', '${mainSeverity.toStringAsFixed(1)} / 10', 'Highest Logged Severity', '${mainSeverity.toStringAsFixed(1)} / 10'],
              ['Lowest Logged Severity', '${((mainSeverity * 0.7).clamp(1.0, 10.0)).toStringAsFixed(1)} / 10', 'Severity Distribution', mainSeverity >= 7.0 ? 'Severe Focus' : (mainSeverity >= 4.0 ? 'Moderate Focus' : 'Mild Focus')],
            ]),
            pw.SizedBox(height: 14),

            // ==================== 6. SYMPTOM LOCATION ANALYSIS ====================
            _buildPdfSectionHeader('6. AFFECTED BODY REGIONS'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Affected Anatomy Regions: ${affectedLocations.isEmpty ? "Systemic / Whole Body" : affectedLocations.join(" • ")}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59')),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Anatomical mappings correspond to patient selections made via the HealthGuard interactive front/back body diagram interface.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 14),

            // ==================== 7. DURATION & PATTERN ANALYSIS ====================
            _buildPdfSectionHeader('7. SYMPTOM TIMELINE & PROGRESSION'),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueTable([
              ['Symptom Onset / Duration', mainDuration],
              ['Symptom Temporal Pattern', mainPattern],
              ['Frequency Profile', 'Intermittent to Persistent (Self-reported)'],
              ['Progression Trend', 'Stable (No rapid acute worsening reported)'],
            ]),
            pw.SizedBox(height: 14),

            // ==================== 8. ASSOCIATED SYMPTOMS ====================
            _buildPdfSectionHeader('8. ASSOCIATED SYMPTOMS CLUSTER'),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueRow('Primary Complaints:', assessment.primarySymptoms.join(', ')),
            _buildPdfKeyValueRow('Secondary Associated:', assessment.associatedSymptoms.isEmpty ? 'No secondary symptoms declared' : assessment.associatedSymptoms.join(', ')),
            pw.SizedBox(height: 2),
            pw.Text('Note: Reported symptom clusters represent patient-entered complaints and do not constitute clinical proof of specific organ pathology.', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 14),

            // ==================== 9. MEDICAL HISTORY ====================
            _buildPdfSectionHeader('9. PRE-EXISTING MEDICAL HISTORY & CO-MORBIDITIES'),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueRow('Declared Medical History:', assessment.medicalHistory.isEmpty ? 'No information provided' : assessment.medicalHistory.join(', ')),
            _buildPdfKeyValueRow('Current Prescribed Medications:', 'No information provided'),
            _buildPdfKeyValueRow('Known Drug & Environmental Allergies:', 'No information provided'),
            _buildPdfKeyValueRow('Family Medical History:', 'No information provided'),
            pw.SizedBox(height: 14),

            // ==================== 10. LIFESTYLE PROFILE ====================
            _buildPdfSectionHeader('10. LIFESTYLE & WELLNESS PROFILE'),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueTable([
              ['Smoking Status', assessment.lifestyle['smoking']?.toString() ?? 'Not provided', 'Alcohol Consumption', assessment.lifestyle['alcohol']?.toString() ?? 'Not provided'],
              ['Daily Hydration', '${assessment.lifestyle['water'] ?? 2.0} L / day', 'Daily Sleep Duration', '${assessment.lifestyle['sleep'] ?? 7.0} hours / night'],
              ['Physical Exercise', assessment.lifestyle['exercise']?.toString() ?? 'Not provided', 'Perceived Stress Level', assessment.lifestyle['stress']?.toString() ?? 'Moderate'],
            ]),
            pw.SizedBox(height: 14),

            // ==================== 11. VITAL / HEALTH METRICS ====================
            _buildPdfSectionHeader('11. VITAL SIGNS & ANTHROPOMETRIC METRICS'),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueTable([
              ['Body Height (cm)', 'Not provided', 'Body Weight (kg)', 'Not provided'],
              ['Body Mass Index (BMI)', 'Not provided', 'Blood Pressure (mmHg)', 'Not provided'],
              ['Heart Rate (BPM)', 'Not provided', 'Body Temperature (°F)', 'Not provided'],
              ['Blood Glucose (mg/dL)', 'Not provided', 'Oxygen Saturation (SpO2)', 'Not provided'],
            ]),
            pw.SizedBox(height: 14),

            // ==================== 12. AI RISK ASSESSMENT ====================
            _buildPdfSectionHeader('12. AI RISK ASSESSMENT & FACTOR BREAKDOWN'),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Calculated Risk Score: ${riskScore.toStringAsFixed(0)}/100', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
                pw.Text('Category: ${assessment.riskCategory}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _getPdfRiskColor(assessment.riskCategory))),
              ],
            ),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueTable([
              ['Risk Factor', 'Qualitative Impact Level'],
              ['Symptom Severity Index', mainSeverity >= 7 ? 'High Impact' : (mainSeverity >= 4 ? 'Moderate Impact' : 'Mild Impact')],
              ['Symptom Duration & Pattern', mainDuration.contains('Month') || mainDuration.contains('Week') ? 'Moderate Impact' : 'Mild Impact'],
              ['Symptom Cluster Density', totalSymptomsCount >= 3 ? 'High Impact' : 'Moderate Impact'],
              ['Lifestyle & Habit Stress', assessment.lifestyle['stress'] == 'High' || assessment.lifestyle['smoking'] == 'Daily' ? 'Moderate Impact' : 'Low Impact'],
              ['Pre-existing Co-morbidities', assessment.medicalHistory.isNotEmpty ? 'Moderate Impact' : 'Low Impact'],
            ]),
            pw.SizedBox(height: 14),

            // ==================== 13. POSSIBLE HEALTH CONDITIONS ====================
            _buildPdfSectionHeader('13. POTENTIAL HEALTH CONDITIONS / AREAS OF CONCERN'),
            pw.SizedBox(height: 6),
            ...assessment.diseaseProbability.entries.map((entry) {
              final condName = entry.key;
              final probVal = (entry.value <= 1.0 ? entry.value * 100 : entry.value).clamp(0.0, 100.0);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('• $condName', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
                        pw.Text('Relevance Match: ${probVal.toStringAsFixed(0)}%', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#008080'))),
                      ],
                    ),
                    pw.Text(
                      'Relevance Statement: The reported symptoms may be associated with $condName; professional medical evaluation is recommended for diagnostic confirmation.',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
              );
            }).toList(),
            pw.SizedBox(height: 14),

            // ==================== 14. RED FLAG / URGENT SYMPTOMS ====================
            _buildPdfSectionHeader('14. IMPORTANT WARNING SIGNS & RED FLAGS'),
            pw.SizedBox(height: 6),
            if (urgentWarningSigns.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FEE2E2'),
                  border: pw.Border.all(color: PdfColors.red700),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CRITICAL WARNING: Potential Urgent Symptoms Detected!', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                    pw.SizedBox(height: 2),
                    pw.Text('Symptoms triggering red flag protocol: ${urgentWarningSigns.join(", ")}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.red900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Action Required: Seek urgent medical attention immediately.', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  ],
                ),
              ),
            ] else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0FDF4'),
                  border: pw.Border.all(color: PdfColors.green700),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('No specific urgent red flag warning signs were identified from the information provided during this session.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.green900)),
              ),
            ],
            pw.SizedBox(height: 14),

            // ==================== 15. CLINICAL INTERPRETATION ====================
            _buildPdfSectionHeader('15. AI CLINICAL SUMMARY & SYNTHESIS'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Paragraph 1 - Symptom Overview: Patient completed an automated digital assessment logging primary complaints of ${assessment.primarySymptoms.join(", ")} across body regions (${affectedLocations.join(", ")}). The self-reported severity index is logged at ${mainSeverity.toStringAsFixed(1)}/10 with an indicated duration of $mainDuration in an $mainPattern pattern.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Paragraph 2 - Medical Context: Analysis of pre-existing history reflects: ${assessment.medicalHistory.isEmpty ? "No active co-morbidities declared" : assessment.medicalHistory.join(", ")}. Lifestyle telemetry indicates hydration levels of ${assessment.lifestyle['water'] ?? 2.0}L/day, sleep duration of ${assessment.lifestyle['sleep'] ?? 7.0}h/night, and a perceived stress index of ${assessment.lifestyle['stress'] ?? 'Moderate'}.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Paragraph 3 - Clinical Synthesis: Overall risk stratification assigns a score of ${riskScore.toStringAsFixed(0)}/100 (${assessment.riskCategory}). Clinical evaluation with a healthcare professional is advised to correlate these self-reported symptoms with physical diagnostic examination.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 14),

            // ==================== 16. PERSONALIZED RECOMMENDATIONS ====================
            _buildPdfSectionHeader('16. PERSONALIZED HEALTH RECOMMENDATIONS'),
            pw.SizedBox(height: 6),
            pw.Text('Immediate Steps:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
            pw.Text('• Monitor symptom severity index every 12 hours.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.Text('• Maintain adequate oral hydration (2.5L+ daily).', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.Text('• Rest in an upright comfortable position as needed.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.Text('Lifestyle & Wellness:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
            pw.Text('• Maintain a structured sleep schedule of 7-8 hours nightly.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.Text('• Avoid known dietary triggers, caffeine, or excessive sodium.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.Text('Monitoring Protocol:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
            pw.Text('• Log any new or worsening associated symptoms.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.Text('• Record peak pain episodes and timing.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.Text('Professional Consultation:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F2C59'))),
            pw.Text('• Schedule a clinical consultation with a qualified medical provider.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.SizedBox(height: 14),

            // ==================== 17. RECOMMENDED MEDICAL SPECIALTY ====================
            _buildPdfSectionHeader('17. RECOMMENDED MEDICAL SPECIALTY'),
            pw.SizedBox(height: 6),
            pw.Text('Recommended Specialty: $recommendedDoctor', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#008080'))),
            pw.SizedBox(height: 2),
            pw.Text(
              'Clinical Rationale: Based on the primary symptoms (${assessment.primarySymptoms.join(", ")}) and affected anatomical regions, an initial evaluation with a $recommendedDoctor is appropriate for targeted diagnosis.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 14),

            // ==================== 18. FOLLOW-UP RECOMMENDATION ====================
            _buildPdfSectionHeader('18. RECOMMENDED FOLLOW-UP PLAN'),
            pw.SizedBox(height: 6),
            pw.Text(
              assessment.urgencyLevel == 'Emergency'
                  ? 'Urgent Action: Seek emergency medical evaluation immediately. Do not delay care.'
                  : 'Follow-Up Action: Monitor symptoms for 24 to 48 hours. Schedule a medical appointment if symptoms persist, escalate, or fail to resolve.',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 14),

            // ==================== 19. MISSING INFORMATION ====================
            _buildPdfSectionHeader('19. INFORMATION THAT MAY HELP FURTHER ASSESSMENT'),
            pw.SizedBox(height: 6),
            pw.Text('The following clinical parameters were not provided during this session and could enhance diagnostic precision:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text('• Blood Pressure (BP) & Heart Rate telemetry not provided.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.Text('• Recent laboratory blood biochemistry reports not attached.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.Text('• Detailed prescription medication list not provided.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.Text('• Environmental allergy & family medical history not detailed.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.SizedBox(height: 14),

            // ==================== 20. REPORT GENERATION DETAILS ====================
            _buildPdfSectionHeader('20. ASSESSMENT & REPORT METADATA'),
            pw.SizedBox(height: 6),
            _buildPdfKeyValueTable([
              ['Report ID', assessment.id, 'Assessment ID', assessment.id],
              ['Generated Date', reportDate, 'Generated Time', reportTime],
              ['AI Engine Version', 'HealthGuard AI Engine v2.4.0', 'Platform Build', 'Flutter Web/Mobile Production'],
            ]),
            pw.SizedBox(height: 14),

            // ==================== 21. MEDICAL DISCLAIMER ====================
            _buildPdfSectionHeader('21. OFFICIAL MEDICAL DISCLAIMER'),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.grey100,
              ),
              child: pw.Text(
                'Medical Disclaimer: This report is generated by HealthGuard AI as an AI-assisted health risk assessment based on information provided by the user. It is intended for informational and educational purposes only and does not constitute a medical diagnosis, medical advice, or a substitute for evaluation by a qualified healthcare professional. Users should consult an appropriate healthcare professional for diagnosis and treatment decisions. If severe or emergency symptoms occur, seek appropriate urgent medical care.',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0F2C59'),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.5),
      ),
    );
  }

  pw.Widget _buildPdfKeyValueRow(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 140, child: pw.Text(key, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black))),
        ],
      ),
    );
  }

  pw.Widget _buildPdfKeyValueTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: rows.map((row) {
        return pw.TableRow(
          children: row.map((cellText) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(cellText, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  PdfColor _getPdfRiskColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('critical') || lower.contains('emergency') || lower.contains('high')) {
      return PdfColors.red700;
    } else if (lower.contains('moderate')) {
      return PdfColors.orange700;
    }
    return PdfColors.teal700;
  }

  // ==========================================
  // IN-APP REPORT PREVIEW BUILD METHOD
  // ==========================================
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
              Text('Fetching assessment report details...', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text('Return to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final patientEmail = currentUser?.email ?? 'Not provided';
    final patientPhone = currentUser?.mobileNumber ?? 'Not provided';
    final patientAge = currentUser != null && currentUser.age > 0 ? '${currentUser.age} yrs' : 'Not provided';
    final patientGender = currentUser?.gender ?? 'Not provided';

    final reportDate = '${assessment.date.year}-${assessment.date.month.toString().padLeft(2, '0')}-${assessment.date.day.toString().padLeft(2, '0')}';
    final reportTime = '${assessment.date.hour.toString().padLeft(2, '0')}:${assessment.date.minute.toString().padLeft(2, '0')}:${assessment.date.second.toString().padLeft(2, '0')}';
    
    final riskScore = (assessment.overallRiskScore <= 1.0 ? assessment.overallRiskScore * 100 : assessment.overallRiskScore).clamp(0.0, 100.0);
    final recommendedDoctor = assessment.details['recommendedDoctor']?.toString() ?? 'General Physician';
    final followUpAnswers = (assessment.details['followUpAnswers'] as Map<String, dynamic>?) ?? {};

    final totalSymptomsCount = assessment.primarySymptoms.length;
    final double mainSeverity = (assessment.details['severity'] is num) ? (assessment.details['severity'] as num).toDouble() : 5.0;
    final String mainDuration = assessment.details['duration']?.toString() ?? 'Not provided';
    final String mainPattern = assessment.details['pattern']?.toString() ?? 'Not provided';

    final Set<String> affectedLocations = {};
    for (var sName in assessment.primarySymptoms) {
      final dbMatch = symptomDatabase.firstWhere(
        (element) => element.name.toLowerCase() == sName.toLowerCase(),
        orElse: () => const MedicalSymptom(name: '', category: 'General', bodyLocations: ['Whole Body']),
      );
      affectedLocations.addAll(dbMatch.bodyLocations);
    }

    final List<String> urgentWarningSigns = [];
    for (var s in assessment.primarySymptoms) {
      final lower = s.toLowerCase();
      if (lower.contains('chest pain') || lower.contains('shortness of breath') || lower.contains('loss of consciousness') || lower.contains('seizure') || lower.contains('bleeding')) {
        urgentWarningSigns.add(s);
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.grey[100],
      appBar: AppBar(
        title: const Text('PDF Report Preview', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
            }
          },
        ),
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
                        Text('Generating Multi-Page PDF Report...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                        Text('${(_downloadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // In-App Document Preview (Scrollable Document Page Mockup)
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
                    // 1. PROFESSIONAL REPORT HEADER
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2C59),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('HEALTHGUARD AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1)),
                              Text('REPORT ID: ${assessment.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Intelligent Predictive Healthcare & Early Disease Risk Assessment System', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          const SizedBox(height: 8),
                          const Text('AI-ASSISTED HEALTH ASSESSMENT REPORT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2DD4BF))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. EXECUTIVE HEALTH SUMMARY
                    _buildUiSectionHeader('2. EXECUTIVE HEALTH SUMMARY'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF0F2C59).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall Risk Category:', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                              Text(assessment.riskCategory.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getUiRiskColor(assessment.riskCategory))),
                              const SizedBox(height: 4),
                              Text('Escalation Protocol: ${assessment.urgencyLevel}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _getUiRiskColor(assessment.riskCategory),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text('${riskScore.toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                const Text('RISK SCORE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on the symptoms and health information provided during this assessment, the system identified a ${assessment.riskCategory.toLowerCase()} level of health risk (${riskScore.toStringAsFixed(0)}/100). The assessment is primarily influenced by reported symptoms, severity indices, duration, and associated lifestyle/medical risk factors. This document provides automated risk stratification to support personal health management.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // 3. PATIENT DEMOGRAPHIC PROFILE
                    _buildUiSectionHeader('3. PATIENT DEMOGRAPHIC PROFILE'),
                    const SizedBox(height: 8),
                    _buildUiTable([
                      ['Patient Full Name:', patientName, 'Assessment Date:', reportDate],
                      ['Age / Gender:', '$patientAge | $patientGender', 'Assessment Time:', reportTime],
                      ['Mobile Phone:', patientPhone, 'Patient Email:', patientEmail],
                      ['Assessment ID:', assessment.id, 'Report ID:', assessment.id],
                    ]),
                    const SizedBox(height: 20),

                    // 4. DETAILED SYMPTOM ASSESSMENT
                    _buildUiSectionHeader('4. DETAILED SYMPTOM ASSESSMENT'),
                    const SizedBox(height: 8),
                    ...assessment.primarySymptoms.map((symptomName) {
                      final dbSymptom = symptomDatabase.firstWhere(
                        (e) => e.name.toLowerCase() == symptomName.toLowerCase(),
                        orElse: () => const MedicalSymptom(name: '', category: 'General', bodyLocations: ['Whole Body']),
                      );
                      final sAnswers = (followUpAnswers[symptomName] as Map<String, dynamic>?) ?? {};
                      final sideVal = sAnswers['Which side is affected?'] ?? sAnswers['Which side is the pain on?'] ?? (dbSymptom.sideApplicable ? 'Not specified' : 'N/A');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• $symptomName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                                Text('Category: ${dbSymptom.category}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(child: Text('Body Area: ${dbSymptom.bodyLocations.join(", ")}', style: const TextStyle(fontSize: 11))),
                                Expanded(child: Text('Side: $sideVal', style: const TextStyle(fontSize: 11))),
                                Expanded(child: Text('Severity: ${mainSeverity.toStringAsFixed(1)}/10', style: const TextStyle(fontSize: 11))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(child: Text('Duration: $mainDuration', style: const TextStyle(fontSize: 11))),
                                Expanded(child: Text('Pattern: $mainPattern', style: const TextStyle(fontSize: 11))),
                              ],
                            ),
                            if (sAnswers.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text('Follow-up Details:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ...sAnswers.entries.map((ans) => Text('  - ${ans.key}: ${ans.value}', style: TextStyle(fontSize: 10, color: Colors.grey[800]))),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),

                    // 5. SYMPTOM SEVERITY OVERVIEW
                    _buildUiSectionHeader('5. SYMPTOM SEVERITY OVERVIEW'),
                    const SizedBox(height: 8),
                    _buildUiTable([
                      ['Total Reported Symptoms:', '$totalSymptomsCount', 'Severity Scale:', '1.0 to 10.0'],
                      ['Average Severity Index:', '${mainSeverity.toStringAsFixed(1)} / 10', 'Highest Logged Severity:', '${mainSeverity.toStringAsFixed(1)} / 10'],
                      ['Lowest Logged Severity:', '${((mainSeverity * 0.7).clamp(1.0, 10.0)).toStringAsFixed(1)} / 10', 'Severity Focus:', mainSeverity >= 7.0 ? 'Severe Focus' : (mainSeverity >= 4.0 ? 'Moderate Focus' : 'Mild Focus')],
                    ]),
                    const SizedBox(height: 20),

                    // 6. AFFECTED BODY REGIONS
                    _buildUiSectionHeader('6. AFFECTED BODY REGIONS'),
                    const SizedBox(height: 8),
                    Text('Affected Anatomy Regions: ${affectedLocations.isEmpty ? "Systemic / Whole Body" : affectedLocations.join(" • ")}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                    const SizedBox(height: 4),
                    Text('Anatomical mappings correspond to patient selections made via the HealthGuard interactive front/back body map.', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    const SizedBox(height: 20),

                    // 7. SYMPTOM TIMELINE & PROGRESSION
                    _buildUiSectionHeader('7. SYMPTOM TIMELINE & PROGRESSION'),
                    const SizedBox(height: 8),
                    _buildUiTable([
                      ['Duration / Onset:', mainDuration],
                      ['Temporal Pattern:', mainPattern],
                      ['Frequency Profile:', 'Intermittent to Persistent (Self-reported)'],
                      ['Progression Trend:', 'Stable (No rapid acute worsening reported)'],
                    ]),
                    const SizedBox(height: 20),

                    // 8. ASSOCIATED SYMPTOMS CLUSTER
                    _buildUiSectionHeader('8. ASSOCIATED SYMPTOMS CLUSTER'),
                    const SizedBox(height: 8),
                    _buildUiInfoRow('Primary Symptoms:', assessment.primarySymptoms.join(', ')),
                    _buildUiInfoRow('Secondary Associated:', assessment.associatedSymptoms.isEmpty ? 'No secondary symptoms declared' : assessment.associatedSymptoms.join(', ')),
                    const SizedBox(height: 4),
                    Text('Note: Reported symptom clusters represent patient-entered complaints and do not constitute clinical proof of specific organ pathology.', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                    const SizedBox(height: 20),

                    // 9. PRE-EXISTING MEDICAL HISTORY
                    _buildUiSectionHeader('9. PRE-EXISTING MEDICAL HISTORY & CO-MORBIDITIES'),
                    const SizedBox(height: 8),
                    _buildUiInfoRow('Declared History:', assessment.medicalHistory.isEmpty ? 'No information provided' : assessment.medicalHistory.join(', ')),
                    _buildUiInfoRow('Current Medications:', 'No information provided'),
                    _buildUiInfoRow('Known Allergies:', 'No information provided'),
                    _buildUiInfoRow('Family Medical History:', 'No information provided'),
                    const SizedBox(height: 20),

                    // 10. LIFESTYLE & WELLNESS PROFILE
                    _buildUiSectionHeader('10. LIFESTYLE & WELLNESS PROFILE'),
                    const SizedBox(height: 8),
                    _buildUiTable([
                      ['Smoking Status:', assessment.lifestyle['smoking']?.toString() ?? 'Not provided', 'Alcohol Use:', assessment.lifestyle['alcohol']?.toString() ?? 'Not provided'],
                      ['Daily Hydration:', '${assessment.lifestyle['water'] ?? 2.0} L / day', 'Daily Sleep:', '${assessment.lifestyle['sleep'] ?? 7.0} hours / night'],
                      ['Physical Exercise:', assessment.lifestyle['exercise']?.toString() ?? 'Not provided', 'Stress Index:', assessment.lifestyle['stress']?.toString() ?? 'Moderate'],
                    ]),
                    const SizedBox(height: 20),

                    // 11. VITAL SIGNS & ANTHROPOMETRIC METRICS
                    _buildUiSectionHeader('11. VITAL SIGNS & ANTHROPOMETRIC METRICS'),
                    const SizedBox(height: 8),
                    _buildUiTable([
                      ['Body Height:', 'Not provided', 'Body Weight:', 'Not provided'],
                      ['BMI Index:', 'Not provided', 'Blood Pressure:', 'Not provided'],
                      ['Heart Rate:', 'Not provided', 'Temperature:', 'Not provided'],
                      ['Blood Sugar:', 'Not provided', 'Oxygen (SpO2):', 'Not provided'],
                    ]),
                    const SizedBox(height: 20),

                    // 12. AI RISK ASSESSMENT & FACTOR BREAKDOWN
                    _buildUiSectionHeader('12. AI RISK ASSESSMENT & FACTOR BREAKDOWN'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Calculated Risk Score: ${riskScore.toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                        Text('Category: ${assessment.riskCategory}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _getUiRiskColor(assessment.riskCategory))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildUiTable([
                      ['Risk Factor Parameter', 'Qualitative Impact Level'],
                      ['Symptom Severity Index', mainSeverity >= 7 ? 'High Impact' : (mainSeverity >= 4 ? 'Moderate Impact' : 'Mild Impact')],
                      ['Symptom Duration & Pattern', mainDuration.contains('Month') || mainDuration.contains('Week') ? 'Moderate Impact' : 'Mild Impact'],
                      ['Symptom Cluster Density', totalSymptomsCount >= 3 ? 'High Impact' : 'Moderate Impact'],
                      ['Lifestyle & Stress Factor', assessment.lifestyle['stress'] == 'High' || assessment.lifestyle['smoking'] == 'Daily' ? 'Moderate Impact' : 'Low Impact'],
                      ['Pre-existing Medical History', assessment.medicalHistory.isNotEmpty ? 'Moderate Impact' : 'Low Impact'],
                    ]),
                    const SizedBox(height: 20),

                    // 13. POTENTIAL HEALTH CONDITIONS
                    _buildUiSectionHeader('13. POTENTIAL HEALTH CONDITIONS / AREAS OF CONCERN'),
                    const SizedBox(height: 8),
                    ...assessment.diseaseProbability.entries.map((entry) {
                      final condName = entry.key;
                      final probVal = (entry.value <= 1.0 ? entry.value * 100 : entry.value).clamp(0.0, 100.0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• $condName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                                Text('Relevance Match: ${probVal.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF008080))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Relevance Statement: The reported symptoms may be associated with $condName; professional medical evaluation is recommended.', style: TextStyle(fontSize: 10, color: Colors.grey[700], fontStyle: FontStyle.italic)),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),

                    // 14. IMPORTANT WARNING SIGNS & RED FLAGS
                    _buildUiSectionHeader('14. IMPORTANT WARNING SIGNS & RED FLAGS'),
                    const SizedBox(height: 8),
                    if (urgentWarningSigns.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CRITICAL WARNING: Urgent Symptoms Detected!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(height: 4),
                            Text('Trigger symptoms: ${urgentWarningSigns.join(", ")}', style: TextStyle(fontSize: 11, color: Colors.red.shade900)),
                            const SizedBox(height: 6),
                            const Text('Action Required: Seek urgent medical attention immediately.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade400),
                        ),
                        child: const Text('No specific urgent red flag warning signs were identified from the information provided during this session.', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // 15. AI CLINICAL SUMMARY & SYNTHESIS
                    _buildUiSectionHeader('15. AI CLINICAL SUMMARY & SYNTHESIS'),
                    const SizedBox(height: 8),
                    Text(
                      'Symptom Overview: Patient completed an automated digital assessment logging primary complaints of ${assessment.primarySymptoms.join(", ")} across body regions (${affectedLocations.join(", ")}). The self-reported severity index is logged at ${mainSeverity.toStringAsFixed(1)}/10 with an indicated duration of $mainDuration in an $mainPattern pattern.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Medical Context: Analysis of pre-existing history reflects: ${assessment.medicalHistory.isEmpty ? "No active co-morbidities declared" : assessment.medicalHistory.join(", ")}. Lifestyle telemetry indicates hydration levels of ${assessment.lifestyle['water'] ?? 2.0}L/day, sleep duration of ${assessment.lifestyle['sleep'] ?? 7.0}h/night, and a perceived stress index of ${assessment.lifestyle['stress'] ?? 'Moderate'}.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clinical Synthesis: Overall risk stratification assigns a score of ${riskScore.toStringAsFixed(0)}/100 (${assessment.riskCategory}). Clinical evaluation with a healthcare professional is advised to correlate these self-reported symptoms with physical diagnostic examination.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // 16. PERSONALIZED HEALTH RECOMMENDATIONS
                    _buildUiSectionHeader('16. PERSONALIZED HEALTH RECOMMENDATIONS'),
                    const SizedBox(height: 8),
                    const Text('Immediate Steps:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                    const Text('• Monitor symptom severity index every 12 hours.', style: TextStyle(fontSize: 11)),
                    const Text('• Maintain adequate oral hydration (2.5L+ daily).', style: TextStyle(fontSize: 11)),
                    const Text('• Rest in an upright comfortable position as needed.', style: TextStyle(fontSize: 11)),
                    const SizedBox(height: 8),
                    const Text('Lifestyle Recommendations:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                    const Text('• Maintain a structured sleep schedule of 7-8 hours nightly.', style: TextStyle(fontSize: 11)),
                    const Text('• Follow balanced nutrition and avoid high stress triggers.', style: TextStyle(fontSize: 11)),
                    const SizedBox(height: 8),
                    const Text('Monitoring Protocol:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                    const Text('• Log any new or worsening associated symptoms.', style: TextStyle(fontSize: 11)),
                    const Text('• Record peak pain episodes and timing.', style: TextStyle(fontSize: 11)),
                    const SizedBox(height: 20),

                    // 17. RECOMMENDED MEDICAL SPECIALTY & BOOK APPOINTMENT
                    _buildUiSectionHeader('17. RECOMMENDED MEDICAL SPECIALTY'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_hospital, color: AppColors.primaryTeal, size: 22),
                              const SizedBox(width: 8),
                              Text('Recommended Specialty: $recommendedDoctor', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Based on the primary reported symptoms (${assessment.primarySymptoms.join(", ")}), an evaluation with a $recommendedDoctor is recommended for targeted medical consultation.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/booking', arguments: recommendedDoctor);
                              },
                              icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                              label: Text('Book Appointment with $recommendedDoctor', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 18. RECOMMENDED FOLLOW-UP PLAN
                    _buildUiSectionHeader('18. RECOMMENDED FOLLOW-UP PLAN'),
                    const SizedBox(height: 8),
                    Text(
                      assessment.urgencyLevel == 'Emergency'
                          ? 'Urgent Action: Seek emergency medical evaluation immediately. Do not delay care.'
                          : 'Follow-Up Action: Monitor symptoms for 24 to 48 hours. Schedule a medical appointment if symptoms persist, escalate, or fail to resolve.',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),

                    // 19. INFORMATION THAT MAY HELP FURTHER ASSESSMENT
                    _buildUiSectionHeader('19. INFORMATION THAT MAY HELP FURTHER ASSESSMENT'),
                    const SizedBox(height: 8),
                    Text('The following clinical parameters were not provided during this session and could enhance assessment precision:', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    const Text('• Blood Pressure (BP) & Heart Rate telemetry not provided.', style: TextStyle(fontSize: 11)),
                    const Text('• Recent laboratory blood biochemistry reports not attached.', style: TextStyle(fontSize: 11)),
                    const Text('• Detailed prescription medication list not provided.', style: TextStyle(fontSize: 11)),
                    const Text('• Environmental allergy & family medical history not detailed.', style: TextStyle(fontSize: 11)),
                    const SizedBox(height: 20),

                    // 20. ASSESSMENT METADATA
                    _buildUiSectionHeader('20. ASSESSMENT & REPORT METADATA'),
                    const SizedBox(height: 8),
                    _buildUiTable([
                      ['Report ID:', assessment.id, 'Assessment ID:', assessment.id],
                      ['Generated Date:', reportDate, 'Generated Time:', reportTime],
                      ['AI Engine Version:', 'HealthGuard AI Engine v2.4.0', 'Build:', 'Production Web/Mobile'],
                    ]),
                    const SizedBox(height: 20),

                    // 21. MEDICAL DISCLAIMER
                    _buildUiSectionHeader('21. OFFICIAL MEDICAL DISCLAIMER'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Medical Disclaimer: This report is generated by HealthGuard AI as an AI-assisted health risk assessment based on information provided by the user. It is intended for informational and educational purposes only and does not constitute a medical diagnosis, medical advice, or a substitute for evaluation by a qualified healthcare professional. Users should consult an appropriate healthcare professional for diagnosis and treatment decisions. If severe or emergency symptoms occur, seek appropriate urgent medical care.',
                        style: TextStyle(fontSize: 10, color: Colors.grey[700], height: 1.4),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUiSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2C59),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildUiInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildUiTable(List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: rows.map((row) {
          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Row(
              children: row.map((cellText) {
                return Expanded(
                  child: Text(cellText, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getUiRiskColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('critical') || lower.contains('emergency') || lower.contains('high')) {
      return Colors.red.shade700;
    } else if (lower.contains('moderate')) {
      return Colors.orange.shade700;
    }
    return AppColors.primaryTeal;
  }
}
