import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/workout_model.dart';
import 'add_workout_screen.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutModel workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM d, y').format(workout.date), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to AddWorkoutScreen in EDIT mode
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddWorkoutScreen(existingWorkout: workout),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha((0.1*255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text("Category: ${workout.category}", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7*255).round()))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("Exercises Performed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 12),
            ...workout.exercises.map((ex) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Theme.of(context).cardColor,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                ),
                title: Text(ex.name, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                subtitle: Text("${ex.sets} Sets  ×  ${ex.reps.contains(',') ? '[${ex.reps}]' : ex.reps} Reps  @  ${ex.weight}kg", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7*255).round()))),
              ),
            )),
          ],
        ),
      ),
    );
  }
}