import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';

class MedicineReminderScreen extends StatefulWidget {
  const MedicineReminderScreen({Key? key}) : super(key: key);

  @override
  State<MedicineReminderScreen> createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends State<MedicineReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  
  String _frequency = 'Once Daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  final List<String> _frequencies = ['Once Daily', 'Twice Daily', 'Thrice Daily', 'As Needed'];

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final state = AppStateProvider.of(context);
    final formattedTime = _selectedTime.format(context);

    await state.createReminder(
      name: _nameController.text,
      dosage: _dosageController.text,
      frequency: _frequency,
      reminderTime: formattedTime,
    );

    // Clear fields
    _nameController.clear();
    _dosageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine reminder successfully registered.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final reminders = state.reminders;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Medicine Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add reminder form
            Text(
              'Add New Medication',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name',
                        prefixIcon: Icon(Icons.medication),
                      ),
                      validator: (val) => val != null && val.isNotEmpty ? null : 'Enter medicine name.',
                    ),
                    const SizedBox(height: 12),
                    
                    // Dosage & Frequency row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dosageController,
                            decoration: const InputDecoration(
                              labelText: 'Dosage',
                              hintText: 'e.g. 10mg / 1 tablet',
                            ),
                            validator: (val) => val != null && val.isNotEmpty ? null : 'Enter dosage.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _frequency,
                            items: _frequencies.map((f) {
                              return DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (val) => setState(() => _frequency = val ?? 'Once Daily'),
                            decoration: const InputDecoration(labelText: 'Frequency'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Time picker
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.alarm),
                      label: Text('Reminder Time: ${_selectedTime.format(context)}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Button
                    ElevatedButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Add Medication reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Active reminders list
            Text(
              'Medication Log & Reminders',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            const SizedBox(height: 12),
            if (reminders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.medication_outlined, size: 48, color: AppColors.getTextSecondary(isDark)),
                      const SizedBox(height: 8),
                      Text(
                        'No medication reminders scheduled.',
                        style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final rem = reminders[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.medication_liquid_rounded,
                          color: rem.isTaken ? AppColors.primaryGreen : AppColors.primaryTeal,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${rem.name} (${rem.dosage})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: rem.isTaken ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              Text(
                                '${rem.frequency} @ ${rem.reminderTime}',
                                style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              rem.isTaken ? 'Taken' : 'Take Now',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: rem.isTaken ? AppColors.primaryGreen : AppColors.getTextSecondary(isDark),
                              ),
                            ),
                            Checkbox(
                              value: rem.isTaken,
                              activeColor: AppColors.primaryGreen,
                              onChanged: (val) {
                                state.updateReminderStatus(rem.id, val ?? false);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
