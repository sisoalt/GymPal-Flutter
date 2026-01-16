import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:intl/intl.dart';
import '../../providers/progress_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/calorie_provider.dart';
import 'add_progress_screen.dart';
import 'goal_settings_sheet.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("My Progress", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())),
            tooltip: 'Goal settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const GoalSettingsSheet(),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGoalCard(context),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBMICard(context),
                const SizedBox(height: 16),
                _buildConsistencyCard(context),
              ],
            ),
            const SizedBox(height: 16),
            _buildCalorieProgress(context),
            const SizedBox(height: 16),
            
            
            const SizedBox(height: 20),
            _buildHistoryHeader(context),
            
            // Updated History List
            _buildHistoryList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProgressScreen()),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- WIDGETS ---

  // ... (Keep GoalCard, BMICard, ConsistencyCard, CalorieProgress exactly as they were) ...
  // Assuming those didn't change, here are the two functions that DID change:

  Widget _buildGoalCard(BuildContext context) {
    // (Paste previous code here or use existing)
    return Consumer<ProgressProvider>(
      builder: (context, p, _) {
        double progressPercent = 0.0;
        final denom = (p.targetWeight - p.startingWeight);
        if (p.logs.isNotEmpty && denom != 0 && !p.currentWeight.isNaN && !p.startingWeight.isNaN) {
          progressPercent = (p.totalChange / denom).abs().clamp(0.0, 1.0);
        }

        String currentWeightText;
        if (p.currentWeight.isNaN) {
          currentWeightText = 'Not set';
        } else {
          currentWeightText = "${p.currentWeight.toStringAsFixed(1)} kg";
        }

        String weightLeftText;
        if (p.currentWeight.isNaN) {
          weightLeftText = '—';
        } else if (p.weightLeft.isNaN) {
          weightLeftText = '—';
        } else {
          weightLeftText = "${p.weightLeft.toStringAsFixed(1)} kg left";
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("Current: ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(currentWeightText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          if (p.currentWeight.isNaN)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddProgressScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, elevation: 0),
                              child: const Text('Set', style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
                      Text("Goal: ${p.targetWeight} kg", style: const TextStyle(color: Color.fromRGBO(255,255,255,0.9))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color.fromRGBO(255,255,255,0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(weightLeftText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(value: progressPercent, backgroundColor: const Color.fromRGBO(255,255,255,0.3), color: Colors.white),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBMICard(BuildContext context) {
    return Consumer2<ProgressProvider, AuthProvider>(
      builder: (context, p, auth, _) {
        final bmiData = p.bmiCategory;
        final heightM = p.heightCm / 100;

        // Age & gender from user profile (fallbacks)
        final age = auth.currentUser?.age ?? 30;
        final genderStr = auth.currentUser?.gender ?? 'Female';
        final genderVal = (genderStr.toLowerCase() == 'male') ? 1 : 0;

        final bmiVal = p.bmi;

        // Body Fat % formula
        double bodyFatPercent = (1.20 * bmiVal) + (0.23 * age) - (10.8 * genderVal) - 5.4;
        if (bodyFatPercent.isNaN || bodyFatPercent.isInfinite) bodyFatPercent = 0.0;
        bodyFatPercent = bodyFatPercent.clamp(0.0, 100.0);

        // Lean Mass
        double leanMass = double.nan;
        if (!p.currentWeight.isNaN) {
          leanMass = p.currentWeight * (1 - (bodyFatPercent / 100));
        }

        // Ideal weight range (BMI 18.5 - 24.9)
        final lowIdeal = 18.5 * heightM * heightM;
        final highIdeal = 24.9 * heightM * heightM;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("BMI Score", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()))),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bmiVal.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(bmiData['label'], style: TextStyle(color: bmiData['color'], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Body Fat: ${bodyFatPercent.toStringAsFixed(1)}%", style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text(leanMass.isNaN ? "Lean Mass: —" : "Lean Mass: ${leanMass.toStringAsFixed(1)} kg", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("Ideal weight: ${lowIdeal.toStringAsFixed(1)} - ${highIdeal.toStringAsFixed(1)} kg", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsistencyCard(BuildContext context) {
      return Consumer<WorkoutProvider>(
      builder: (context, wp, _) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final workoutsThisWeek = wp.workouts.where((w) => w.date.isAfter(startOfWeek)).length;

        return Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("This Week", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()))),
              Text("$workoutsThisWeek", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              Text("Workouts", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalorieProgress(BuildContext context) {
      return Consumer<CalorieProvider>(
      builder: (context, cp, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Calories", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  Text("${cp.totalCalories} / ${cp.dailyGoal}", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6*255).round()))),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (cp.totalCalories / cp.dailyGoal).clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).colorScheme.onSurface.withAlpha((0.08*255).round()),
                color: Theme.of(context).colorScheme.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      },
    );
  }

  

  Widget _buildHistoryHeader(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text("Weight History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // --- NEW: EDITABLE HISTORY LIST ---
  Widget _buildHistoryList(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, p, _) {
        if (p.logs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No logs yet."));
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: p.logs.take(5).length,
          itemBuilder: (ctx, i) {
            final log = p.logs[i];
            final hasImage = log.photoPath != null && log.photoPath!.isNotEmpty;

            return Card(
              margin: const EdgeInsets.only(top: 8),
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                onTap: () {
                  // Navigate to Edit Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProgressScreen(existingLog: log),
                    ),
                  );
                },
                leading: Container(
                   width: 50, height: 50,
                   decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                   clipBehavior: Clip.hardEdge,
                   child: hasImage
                    ? Image.memory(
                        base64Decode(log.photoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                      )
                    : const Icon(Icons.monitor_weight, color: Colors.blue),
                ),
                title: Text("${log.weight} kg", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(log.notes.isNotEmpty ? log.notes : "No notes"),
                trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}