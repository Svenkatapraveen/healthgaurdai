import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_chart.dart';
import '../services/db_service.dart';

class AnalysisResultsScreen extends StatelessWidget {
  const AnalysisResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Attempt to parse AssessmentModel from arguments
    final assessment = ModalRoute.of(context)!.settings.arguments as AssessmentModel?;

    if (assessment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Analysis Results')),
        body: const Center(child: Text('No assessment data was provided.')),
      );
    }

    // Determine colors based on risk
    Color riskColor = AppColors.riskLow;
    if (assessment.riskCategory.contains('Moderate')) riskColor = AppColors.riskModerate;
    else if (assessment.riskCategory.contains('Critical')) riskColor = AppColors.riskCritical;
    else if (assessment.riskCategory.contains('High')) riskColor = AppColors.riskHigh;

    // Map probabilities for charts
    final diseaseProb = assessment.diseaseProbability;
    final List<double> chartPoints = diseaseProb.values.toList();
    final List<String> chartLabels = diseaseProb.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('AI Clinical Diagnosis', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.getTextPrimary(isDark)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Risk Score Callout
            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Risk Category',
                        style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          assessment.riskCategory,
                          style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${assessment.overallRiskScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  const Text(
                    'Overall Disease Risk Index',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: riskColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Urgency Level: ${assessment.urgencyLevel}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Probability chart
            Text(
              'Disease Probability Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: CustomChart(
                dataPoints: chartPoints,
                labels: chartLabels,
                type: ChartType.bar,
                height: 160,
                maxValue: 100,
              ),
            ),
            const SizedBox(height: 20),

            // Clinical Summary
            Text(
              'Clinical Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Text(
                assessment.clinicalSummary,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            // Possible Causes
            _buildSectionCard(
              isDark,
              title: 'Possible Conditions',
              items: assessment.possibleCauses,
              icon: Icons.biotech,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(height: 16),

            // AI Recommendations
            _buildSectionCard(
              isDark,
              title: 'AI Recommendations',
              items: assessment.recommendations,
              icon: Icons.psychology,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),

            // Preventive Actions
            _buildSectionCard(
              isDark,
              title: 'Preventive Measures',
              items: assessment.preventiveActions,
              icon: Icons.shield,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 24),

            // Route Navigation Buttons
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryTeal, AppColors.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/report', arguments: assessment);
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text('Generate Premium PDF Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forecast');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.getBorder(isDark)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Future Risk Forecast', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/recommendations', arguments: assessment.primarySymptoms.first);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.getBorder(isDark)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Recommend Doctor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
              child: Text('Return to Home Dashboard', style: TextStyle(color: AppColors.primaryTeal)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    bool isDark, {
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((it) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(it, style: const TextStyle(fontSize: 13, height: 1.4))),
                ],
              ),
            );
          }).toList()
        ],
      ),
    );
  }
}
