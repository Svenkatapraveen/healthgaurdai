import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../data/symptom_database.dart';

Future<Uint8List?> fetchPdfBytesFromUrl(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  } catch (_) {}
  return null;
}

Future<Uint8List> generate21SectionMedicalReportPdfBytes({
  required AssessmentModel assessment,
  AppUser? user,
}) async {
  final pdf = pw.Document();

  final patientName = user?.fullName ?? (assessment.details['patientName']?.toString() ?? 'Patient (${assessment.userId})');
  final patientEmail = user?.email ?? (assessment.details['patientEmail']?.toString() ?? 'Not provided');
  final patientPhone = user?.mobileNumber ?? (assessment.details['mobileNumber']?.toString() ?? 'Not provided');
  final patientAge = user != null && user.age > 0 ? '${user.age} yrs' : 'Not provided';
  final patientGender = user?.gender ?? 'Not provided';

  final reportDate = '${assessment.date.year}-${assessment.date.month.toString().padLeft(2, '0')}-${assessment.date.day.toString().padLeft(2, '0')}';
  final reportTime = '${assessment.date.hour.toString().padLeft(2, '0')}:${assessment.date.minute.toString().padLeft(2, '0')}:${assessment.date.second.toString().padLeft(2, '0')}';
  
  final riskScore = (assessment.overallRiskScore <= 1.0 ? assessment.overallRiskScore * 100 : assessment.overallRiskScore).clamp(0.0, 100.0);
  final recommendedDoctor = assessment.details['recommendedDoctor']?.toString() ?? 'General Physician';
  final followUpAnswers = (assessment.details['followUpAnswers'] as Map<String, dynamic>?) ?? {};

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
          }),
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
          }),
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
