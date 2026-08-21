import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_sidebar.dart';
import '../services/db_service.dart';
import '../state/app_state.dart';
import '../utils/pdf_generator_helper.dart';
import '../utils/web_download_helper.dart';

class AnalysisResultsScreen extends StatelessWidget {
  const AnalysisResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final assessment = ModalRoute.of(context)!.settings.arguments as AssessmentModel?;

    if (assessment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Analysis Results')),
        body: const Center(child: Text('No assessment data was provided.')),
      );
    }

    return AppLayout(
      title: 'HealthGuard AI Assessment',
      subtitle: 'Clinical risk summary & AI diagnostic analysis',
      role: UserRole.patient,
      currentRoute: '/results',
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
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Header Badge & Disclaimer Banner
          AppCard(
            backgroundColor: AppColors.primaryBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AI-ASSISTED ASSESSMENT',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ID: ${assessment.id}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: (assessment.overallRiskScore / 100).clamp(0.0, 1.0),
                            strokeWidth: 8,
                            backgroundColor: Colors.white24,
                            color: assessment.overallRiskScore >= 75
                                ? AppColors.danger
                                : assessment.overallRiskScore >= 50
                                    ? AppColors.warning
                                    : AppColors.primaryTeal,
                          ),
                        ),
                        Text(
                          '${assessment.overallRiskScore.toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risk Score & Urgency: ${assessment.urgencyLevel}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          AppBadge.risk(assessment.riskCategory),
                          const SizedBox(height: 8),
                          Text(
                            'Recommended Specialty: ${(assessment.details["recommendedDoctor"] as String?) ?? "General Practitioner"}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This AI-assisted assessment is intended to support clinical review and does not replace professional medical diagnosis.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Symptoms & AI Summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reported Symptoms',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: assessment.symptoms.map((s) {
                          return Chip(
                            label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'AI Clinical Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assessment.clinicalSummary,
                        style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Possible Health Conditions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                      ),
                      const SizedBox(height: 12),
                      ...assessment.possibleCauses.map((cause) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.primaryTeal),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(cause, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark))),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'View Full Report',
                icon: Icons.visibility_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () {
                  Navigator.pushNamed(context, '/report?id=${assessment.id}');
                },
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Download PDF',
                icon: Icons.download_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final state = AppStateProvider.of(context);
                  final pdfBytes = await generate21SectionMedicalReportPdfBytes(
                    assessment: assessment,
                    user: state.currentUser,
                  );
                  await downloadPdfFileFromUrl('', 'Medical_Report_${assessment.id}.pdf', bytes: pdfBytes);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report PDF downloaded successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Book Appointment',
                icon: Icons.calendar_month_outlined,
                onPressed: () {
                  Navigator.pushNamed(context, '/booking', arguments: assessment);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
