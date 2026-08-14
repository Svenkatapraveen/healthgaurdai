import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({Key? key}) : super(key: key);

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Chest Pain', 'Headache', 'Hypertension'];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final assessments = state.assessments;

    // Filter and search logic
    final filteredAssessments = assessments.where((asm) {
      // Search matches
      final matchesSearch = _searchQuery.isEmpty ||
          asm.primarySymptoms.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          asm.clinicalSummary.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter matches
      bool matchesFilter = _selectedFilter == 'All';
      if (_selectedFilter == 'Chest Pain') {
        matchesFilter = asm.primarySymptoms.contains('Chest Pain');
      } else if (_selectedFilter == 'Headache') {
        matchesFilter = asm.primarySymptoms.contains('Headache');
      } else if (_selectedFilter == 'Hypertension') {
        matchesFilter = asm.medicalHistory.contains('Hypertension') || asm.diseaseProbability.containsKey('Hypertension');
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Assessment History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Search Box
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search assessment records...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter chips list
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppColors.primaryTeal.withOpacity(0.25),
                          onSelected: (val) {
                            if (val) setState(() => _selectedFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: filteredAssessments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: AppColors.getTextSecondary(isDark)),
                        const SizedBox(height: 16),
                        Text(
                          'No assessment records found.',
                          style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredAssessments.length,
                    itemBuilder: (context, index) {
                      final asm = filteredAssessments[index];
                      
                      Color riskColor = AppColors.riskLow;
                      if (asm.riskCategory.contains('Moderate')) riskColor = AppColors.riskModerate;
                      else if (asm.riskCategory.contains('Critical')) riskColor = AppColors.riskCritical;
                      else if (asm.riskCategory.contains('High')) riskColor = AppColors.riskHigh;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/results', arguments: asm);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.medical_services_outlined, color: AppColors.primaryTeal, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          asm.primarySymptoms.join(', '),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${asm.date.day}/${asm.date.month}/${asm.date.year}',
                                      style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  asm.clinicalSummary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(shape: BoxShape.circle, color: riskColor),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          asm.riskCategory,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskColor),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Severity Score: ${asm.details['severity'] ?? 5.0}/10',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
