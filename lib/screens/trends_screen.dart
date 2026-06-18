import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_chart.dart';

class HealthTrendsScreen extends StatelessWidget {
  const HealthTrendsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Simulated Trend Data
    final healthScoreData = [78.0, 80.0, 82.0, 81.0, 85.0, 84.0, 88.0];
    final healthScoreLabels = ['May 1', 'May 5', 'May 10', 'May 15', 'May 20', 'May 25', 'May 30'];

    final heartRateData = [68.0, 72.0, 75.0, 70.0, 73.0, 69.0, 72.0];
    final bloodPressureSystolic = [135.0, 130.0, 128.0, 126.0, 124.0, 122.0, 120.0];
    final bmiData = [24.5, 24.3, 24.2, 24.0, 23.8, 23.6, 23.5];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: AppBar(
          title: const Text('Trends Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.primaryTeal,
            unselectedLabelColor: AppColors.getTextSecondary(isDark),
            indicatorColor: AppColors.primaryTeal,
            tabs: const [
              Tab(text: 'Health Score'),
              Tab(text: 'Cardio Vitals'),
              Tab(text: 'Body Composition'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Health Score Trends
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Health Index progression (30 Days)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: CustomChart(
                      dataPoints: healthScoreData,
                      labels: healthScoreLabels,
                      type: ChartType.line,
                      color: AppColors.primaryTeal,
                      height: 180,
                      maxValue: 100,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trend Insights',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your Health Score has improved by +10% over the last 30 days due to regular hydration and sleep goals alignment.',
                                style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            // Tab 2: Cardio Vitals Trends (Heart rate & Blood pressure)
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Resting Heart Rate (BPM)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: CustomChart(
                      dataPoints: heartRateData,
                      labels: healthScoreLabels,
                      type: ChartType.line,
                      color: Colors.redAccent,
                      height: 150,
                      maxValue: 120,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Systolic Blood Pressure (mmHg)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: CustomChart(
                      dataPoints: bloodPressureSystolic,
                      labels: healthScoreLabels,
                      type: ChartType.line,
                      color: Colors.orangeAccent,
                      height: 150,
                      maxValue: 160,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Tab 3: Body Composition (BMI)
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Body Mass Index (BMI)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: CustomChart(
                      dataPoints: bmiData,
                      labels: healthScoreLabels,
                      type: ChartType.line,
                      color: Colors.blueAccent,
                      height: 160,
                      maxValue: 30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primaryTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Optimal BMI parameters for your demographic profile fall in the range 18.5 - 24.9. Maintain consistent calorie balance.',
                            style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
