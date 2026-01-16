import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/food_log_model.dart';
import '../../data/services/food_api_service.dart'; // <--- Import API Service
import '../../providers/calorie_provider.dart';

class FoodInputSheet extends StatefulWidget {
  final DateTime selectedDate;
  final FoodLogModel? existingLog;

  const FoodInputSheet({
    super.key, 
    required this.selectedDate,
    this.existingLog,
  });

  @override
  State<FoodInputSheet> createState() => _FoodInputSheetState();
}

class _FoodInputSheetState extends State<FoodInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _selectedMeal = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  
  bool _isSearching = false; // To show loading spinner

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      _nameController.text = widget.existingLog!.name;
      _caloriesController.text = widget.existingLog!.calories.toString();
      _selectedMeal = widget.existingLog!.mealType;
    }
  }

  // --- NEW: Function to call API ---
  Future<void> _autoCalculateCalories() async {
    final query = _nameController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Type a food name first (e.g. '2 eggs')")));
      return;
    }

    setState(() => _isSearching = true); // Show loading

    final calories = await FoodApiService.getCalories(query);

    setState(() => _isSearching = false); // Hide loading

    if (calories != null) {
      _caloriesController.text = calories.toString();
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not find food info.")));
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final calories = int.parse(_caloriesController.text.trim());

    final provider = Provider.of<CalorieProvider>(context, listen: false);

    if (widget.existingLog != null) {
      provider.editFoodLog(widget.existingLog!, name, calories, _selectedMeal);
    } else {
      final newLog = FoodLogModel(
        name: name,
        calories: calories,
        date: widget.selectedDate,
        mealType: _selectedMeal,
      );
      provider.addFoodLog(newLog);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existingLog == null ? "Add Food" : "Edit Food",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // --- UPDATED: Food Name with Search Icon ---
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Food Name (e.g. '1 Banana')",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.fastfood_outlined),
                // The Magic Button
                suffixIcon: IconButton(
                  onPressed: _isSearching ? null : _autoCalculateCalories,
                  icon: _isSearching 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, color: Color(0xFF4A90E2)),
                  tooltip: "Auto-calculate Calories",
                ),
              ),
              validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
            ),
            const SizedBox(height: 5),
            const Text(
              "Tip: Tap the search icon to auto-fill calories",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.end,
            ),
            const SizedBox(height: 12),
            
            // Calories
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Calories",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department_outlined),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return "Enter calories";
                if (int.tryParse(val) == null || int.parse(val) < 0) return "Valid number required";
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Meal Category
            DropdownButtonFormField<String>(
              initialValue: _selectedMeal,
              items: _mealTypes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _selectedMeal = val!),
              decoration: const InputDecoration(
                labelText: "Meal Type",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(widget.existingLog == null ? "Add Entry" : "Update Entry"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}