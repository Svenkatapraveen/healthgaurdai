import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_chart.dart';

class LifestyleDashboard extends StatefulWidget {
  const LifestyleDashboard({super.key});

  @override
  State<LifestyleDashboard> createState() => _LifestyleDashboardState();
}

class _LifestyleDashboardState extends State<LifestyleDashboard> {
  double _waterDrank = 1.5; // liters
  double _sleepLogged = 7.2; // hours
  int _stepsWalked = 6200;
  int _caloriesBurned = 340;
  String _stress = 'Moderate';

  // Toggle for Trends
  int _trendIndex = 0; // 0: Weekly, 1: Monthly
  final List<String> _trendPeriods = ['Weekly Trends', 'Monthly Trends'];

  final Map<int, List<double>> _waterTrends = {
    0: [1.8, 2.2, 1.5, 2.0, 2.5, 1.5, 1.8], // 7 days
    1: [2.0, 1.8, 2.2, 2.5, 1.9, 2.1, 2.3, 1.8, 2.2, 2.0], // monthly subset
  };
  final Map<int, List<String>> _trendLabels = {
    0: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    1: ['D1', 'D3', 'D6', 'D9', 'D12', 'D15', 'D18', 'D21', 'D24', 'D27'],
  };

  void _addWater() {
    setState(() {
      _waterDrank = (_waterDrank + 0.25).clamp(0.0, 5.0);
    });
  }

  void _addSteps() {
    setState(() {
      _stepsWalked += 1000;
      _caloriesBurned += 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final trendPoints = _waterTrends[_trendIndex]!;
    final trendLabels = _trendLabels[_trendIndex]!;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Lifestyle Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.pushNamed(context, '/trends'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BMI Summary Header
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '23.5',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Healthy BMI Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weight: 72 kg | Height: 175 cm',
                          style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                        ),
                        Text(
                          'Your weight matches ideal indicators.',
                          style: TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Stats Progress Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                // Water intake
                _buildLogCard(
                  isDark,
                  title: 'Water Hydration',
                  value: '${_waterDrank.toStringAsFixed(2)}L / 3.0L',
                  icon: Icons.water_drop,
                  color: Colors.blueAccent,
                  buttonText: 'Add 250ml',
                  onTap: _addWater,
                ),
                // Step activity
                _buildLogCard(
                  isDark,
                  title: 'Steps Walked',
                  value: '$_stepsWalked / 10000\n($_caloriesBurned kcal)',
                  icon: Icons.directions_walk,
                  color: Colors.orangeAccent,
                  buttonText: 'Add 1k Steps',
                  onTap: _addSteps,
                ),
                // Sleep logged
                _buildLogCard(
                  isDark,
                  title: 'Sleep Tracking',
                  value: '$_sleepLogged Hrs / 8.0',
                  icon: Icons.bedtime,
                  color: Colors.indigoAccent,
                  buttonText: 'Log Nap (+0.5h)',
                  onTap: () {
                    setState(() => _sleepLogged = (_sleepLogged + 0.5).clamp(0.0, 12.0));
                  },
                ),
                // Stress & Calories
                _buildLogCard(
                  isDark,
                  title: 'Stress Level',
                  value: _stress,
                  icon: Icons.psychology_alt,
                  color: Colors.teal,
                  buttonText: 'Relax (De-Stress)',
                  onTap: () {
                    setState(() => _stress = 'Low');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Trends Header selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hydration & Activity Trends',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                ),
                DropdownButton<int>(
                  value: _trendIndex,
                  items: List.generate(_trendPeriods.length, (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text(_trendPeriods[index], style: const TextStyle(fontSize: 12)),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) setState(() => _trendIndex = val);
                  },
                  underline: const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: CustomChart(
                dataPoints: trendPoints,
                labels: trendLabels,
                type: ChartType.line,
                color: Colors.blueAccent,
                height: 160,
                maxValue: 3.0,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}
