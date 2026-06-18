import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_chart.dart';

class FutureRiskForecastScreen extends StatefulWidget {
  const FutureRiskForecastScreen({Key? key}) : super(key: key);

  @override
  State<FutureRiskForecastScreen> createState() => _FutureRiskForecastScreenState();
}

class _FutureRiskForecastScreenState extends State<FutureRiskForecastScreen> {
  int _selectedHorizonIndex = 0; // 0: 3 Months, 1: 6 Months, 2: 12 Months

  final List<String> _horizons = ['3 Months', '6 Months', '12 Months'];

  // Data maps for forecasts depending on horizon selected
  final Map<int, List<double>> _heartRiskData = {
    0: [32, 34, 33, 35], // weekly/monthly plot
    1: [32, 35, 38, 40, 42, 45],
    2: [32, 38, 44, 52, 60, 68, 72, 70, 75, 78, 82, 85],
  };

  final Map<int, List<double>> _diabetesRiskData = {
    0: [15, 17, 16, 18],
    1: [15, 18, 22, 25, 29, 32],
    2: [15, 22, 30, 38, 45, 52, 58, 62, 65, 70, 72, 75],
  };

  final Map<int, List<String>> _labelsData = {
    0: ['W1', 'W2', 'W3', 'W4'],
    1: ['M1', 'M2', 'M3', 'M4', 'M5', 'M6'],
    2: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  };

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final heartPoints = _heartRiskData[_selectedHorizonIndex]!;
    final diabetesPoints = _diabetesRiskData[_selectedHorizonIndex]!;
    final labels = _labelsData[_selectedHorizonIndex]!;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Future Risk Forecast', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Horizon selector segment bar
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: List.generate(_horizons.length, (index) {
                  final isSelected = _selectedHorizonIndex == index;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedHorizonIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primaryTeal 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _horizons[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white 
                                : AppColors.getTextPrimary(isDark),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // AI analysis callout warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.riskModerate.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.riskModerate.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights, color: AppColors.riskModerate),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Warning: Based on your current exercise frequency, sleep patterns, and hypertension logs, cardiovascular risk exhibits an upward trend of +18% over the next 12 months.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.orange[200] : Colors.orange[900],
                        height: 1.4,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Heart Disease Forecast
            Text(
              'Heart Disease Risk Trajectory',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: CustomChart(
                dataPoints: heartPoints,
                labels: labels,
                type: ChartType.line,
                color: Colors.redAccent,
                height: 150,
                maxValue: 100,
              ),
            ),
            const SizedBox(height: 24),

            // Diabetes Forecast
            Text(
              'Diabetes Type-II Risk Progression',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: CustomChart(
                dataPoints: diabetesPoints,
                labels: labels,
                type: ChartType.line,
                color: Colors.blueAccent,
                height: 150,
                maxValue: 100,
              ),
            ),
            const SizedBox(height: 24),

            // Other Disease Trajectories (Text/Static Indicators)
            Text(
              'Other AI Predictions (12-Month Horizon)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _buildRiskRow(isDark, 'Hypertension Risk', 'Moderate', '58% Chance', AppColors.riskModerate),
                  const Divider(),
                  _buildRiskRow(isDark, 'Obesity Risk', 'Low', '15% Chance', AppColors.riskLow),
                  const Divider(),
                  _buildRiskRow(isDark, 'Kidney Disease Risk', 'Critical', '70% Chance', AppColors.riskCritical),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskRow(bool isDark, String name, String level, String probabilityText, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                probabilityText,
                style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
