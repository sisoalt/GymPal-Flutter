import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/progress_provider.dart';
import '../../providers/calorie_provider.dart';

class GoalSettingsSheet extends StatefulWidget {
  const GoalSettingsSheet({super.key});

  @override
  State<GoalSettingsSheet> createState() => _GoalSettingsSheetState();
}

class _GoalSettingsSheetState extends State<GoalSettingsSheet> {
  final _heightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _dailyGoalCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Lose Weight';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProgressProvider>(context, listen: false);
    _heightCtrl.text = provider.heightCm.toString();
    _targetWeightCtrl.text = provider.targetWeight.toString();
    _selectedDate = provider.targetDate;
    _selectedType = provider.goalType;
    // Load calorie daily goal if available
    try {
      final cp = Provider.of<CalorieProvider>(context, listen: false);
      _dailyGoalCtrl.text = cp.dailyGoal.toString();
    } catch (_) {
      _dailyGoalCtrl.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Set Fitness Goals",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Height (cm)", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  items: ['Lose Weight', 'Gain Muscle', 'Maintain']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                  decoration: const InputDecoration(
                      labelText: "Goal Type", border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _dailyGoalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: "Daily Calorie Goal (kcal)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetWeightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Target Weight (kg)",
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030));
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: "Target Date", border: OutlineInputBorder()),
                    child: Text(DateFormat('MMM d, y').format(_selectedDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Provider.of<ProgressProvider>(context, listen: false)
                    .updateSettings(
                  double.parse(_heightCtrl.text),
                  double.parse(_targetWeightCtrl.text),
                  _selectedDate,
                  _selectedType,
                );
                // Save calorie daily goal if provided
                if (_dailyGoalCtrl.text.isNotEmpty) {
                  final cp = Provider.of<CalorieProvider>(context, listen: false);
                  final g = int.tryParse(_dailyGoalCtrl.text);
                  if (g != null) cp.updateGoal(g);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white),
              child: const Text("Save Goals"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
