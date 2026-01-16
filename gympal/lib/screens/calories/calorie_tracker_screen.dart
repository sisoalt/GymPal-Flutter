import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/calorie_provider.dart';
import 'food_input_sheet.dart';

class CalorieTrackerScreen extends StatelessWidget {
  const CalorieTrackerScreen({super.key});

  // Helper to open the bottom sheet
  void _showInputSheet(BuildContext context, {dynamic existingLog}) {
    final provider = Provider.of<CalorieProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to expand with keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FoodInputSheet(
        selectedDate: provider.selectedDate,
        existingLog: existingLog,
      ),
    );
  }

  // Helper for delete confirmation
  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Day?"),
        content: const Text("This will delete all food entries for the selected date."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Provider.of<CalorieProvider>(context, listen: false).clearDailyLogs();
              Navigator.pop(ctx);
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Calorie Tracker", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          // Optional: Clear All Button
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.grey),
            onPressed: () => _confirmDeleteAll(context),
            tooltip: "Clear All",
          )
        ],
      ),
      body: Consumer<CalorieProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // 1. Top Section: Date & Total
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.only(bottom: 20, top: 10),
                child: Column(
                  children: [
                    // Date Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => provider.loadLogs(provider.selectedDate.subtract(const Duration(days: 1))),
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: provider.selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) provider.loadLogs(picked);
                          },
                              child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEE, MMM d').format(provider.selectedDate),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => provider.loadLogs(provider.selectedDate.add(const Duration(days: 1))),
                        ),
                      ],
                    ),
                        const SizedBox(height: 10),
                    // Total Calories Display
                    Column(
                      children: [
                        Text("Total Intake", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()), fontSize: 12)),
                        Text(
                          "${provider.totalCalories}",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text("kcal", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()), fontSize: 14)),
                        
                        const SizedBox(height: 20),
                        
                        // Progress Bar & Calories Left
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: provider.dailyGoal > 0 
                                      ? (provider.totalCalories / provider.dailyGoal).clamp(0.0, 1.0)
                                      : 0.0,
                                  minHeight: 10,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.1*255).round()),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    provider.totalCalories > provider.dailyGoal 
                                        ? Colors.red 
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${provider.dailyGoal - provider.totalCalories >= 0 ? provider.dailyGoal - provider.totalCalories : 0} kcal left",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: provider.totalCalories > provider.dailyGoal 
                                          ? Colors.red 
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    "Goal: ${provider.dailyGoal} kcal",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Food List
              Expanded(
                child: provider.todayLogs.isEmpty
                    ? Center(
                        child: Text("No food logged for this day.", style: TextStyle(color: Colors.grey[400])),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.todayLogs.length,
                        itemBuilder: (ctx, i) {
                          final log = provider.todayLogs[i];
                          return Card(
                            color: Theme.of(context).cardColor,
                            elevation: 2,
                            shadowColor: const Color.fromRGBO(0,0,0,0.05),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () => _showInputSheet(context, existingLog: log), // Open Edit
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withAlpha((0.1*255).round()),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.restaurant, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(
                                log.name,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              subtitle: Text(
                                log.mealType,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round())),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${log.calories}",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  const SizedBox(width: 4),
                                  Text("kcal", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()))),
                                  const SizedBox(width: 16),
                                  // Delete Button
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (dCtx) => AlertDialog(
                                          title: const Text("Delete Item?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Cancel")),
                                            TextButton(
                                              onPressed: () {
                                                provider.deleteFoodLog(log);
                                                Navigator.pop(dCtx);
                                              },
                                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()), size: 20),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A90E2),
        onPressed: () => _showInputSheet(context), // Open Add
        child: const Icon(Icons.add),
      ),
    );
  }
}