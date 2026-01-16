import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/workout_provider.dart';
import 'add_workout_screen.dart';
import 'workout_detail_screen.dart'; // We create this next

class WorkoutListScreen extends StatelessWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("My Workouts", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4A90E2)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWorkoutScreen())),
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.workouts.isEmpty) {
            return const Center(child: Text("No workouts logged yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.workouts.length,
            itemBuilder: (context, index) {
              final workout = provider.workouts[index];
              final isToday = DateUtils.isSameDay(workout.date, DateTime.now());

                return Dismissible(
                key: Key(workout.key.toString()), // Hive keys are unique
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                ),
                confirmDismiss: (direction) async {
                   return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Workout?"),
                      content: const Text("This cannot be undone."),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  provider.deleteWorkout(workout);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Workout deleted")));
                },
                child: Card(
                  elevation: isToday ? 4 : 1, // Highlight today
                  color: isToday ? Theme.of(context).colorScheme.primary.withAlpha((0.08*255).round()) : Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: workout)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(workout.category, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12)),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(
                                DateFormat('MMM d').format(workout.date),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7*255).round())),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(workout.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Text(
                            "${workout.exercises.length} Exercises • Total Sets: ${workout.exercises.fold(0, (sum, ex) => sum + int.parse(ex.sets))}",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7*255).round()), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWorkoutScreen())),
        backgroundColor: const Color(0xFF4A90E2),
        child: const Icon(Icons.add),
      ),
    );
  }
}