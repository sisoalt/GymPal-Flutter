import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/workout_provider.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/progress_provider.dart';
import '../workouts/workout_detail_screen.dart';
import '../calories/calorie_tracker_screen.dart';
import '../progress/progress_screen.dart';

class AllActivityScreen extends StatelessWidget {
  const AllActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = Provider.of<WorkoutProvider>(context);
    final cp = Provider.of<CalorieProvider>(context);
    final pp = Provider.of<ProgressProvider>(context);

    final List<Map<String, dynamic>> items = [];

    for (var w in wp.workouts) {
      var ws = '${w.exercises.length} exercises · ${w.duration}';
      if (w.shortNote.isNotEmpty) ws = '$ws · ${w.shortNote}';
      items.add({
        'date': w.date,
        'title': w.name.isNotEmpty ? w.name : 'Workout',
        'subtitle': ws,
        'object': w,
        'icon': Icons.fitness_center,
        'color': Theme.of(context).colorScheme.primary,
        'type': 'workout',
      });
    }

    for (var f in cp.todayLogs) {
      items.add({
        'date': f.date,
        'title': f.name,
        'subtitle': '${f.calories} kcal · ${f.mealType}',
        'object': f,
        'icon': Icons.local_fire_department,
        'color': const Color(0xFFEF4444),
        'type': 'food',
      });
    }

    for (var p in pp.logs) {
      items.add({
        'date': p.date,
        'title': 'Weight: ${p.weight.toStringAsFixed(1)} kg',
        'subtitle': p.notes,
        'object': p,
        'icon': Icons.show_chart,
        'color': const Color(0xFF8B5CF6),
        'type': 'progress',
      });
    }

    items.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    final df = DateFormat('EEE, MMM d • h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('All Activity'), backgroundColor: Theme.of(context).colorScheme.surface, elevation: 0),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 12),
        itemBuilder: (ctx, idx) {
          final it = items[idx];
          final date = it['date'] as DateTime;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (it['color'] as Color).withAlpha((0.12 * 255).round()),
              child: Icon(it['icon'] as IconData, color: it['color'] as Color, size: 18),
            ),
            title: Text(it['title'] as String, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
            subtitle: it['subtitle'] != null && (it['subtitle'] as String).isNotEmpty ? Text(it['subtitle'] as String) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(df.format(date), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()))),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.redAccent,
                  tooltip: 'Delete activity',
                  onPressed: () async {
                    final type = it['type'] as String;
                    final obj = it['object'];
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete activity'),
                        content: const Text('Are you sure you want to delete this activity? This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    try {
                      if (type == 'workout') {
                        await Provider.of<WorkoutProvider>(context, listen: false).deleteWorkout(obj);
                      } else if (type == 'food') {
                        await Provider.of<CalorieProvider>(context, listen: false).deleteFoodLog(obj);
                      } else if (type == 'progress') {
                        await Provider.of<ProgressProvider>(context, listen: false).deleteProgress(obj);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity deleted')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete activity: $e')));
                      }
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              final type = it['type'] as String;
              if (type == 'workout') {
                final wobj = it['object'] as dynamic;
                Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: wobj)));
              } else if (type == 'food') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CalorieTrackerScreen()));
              } else if (type == 'progress') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
              }
            },
          );
        },
      ),
    );
  }
}
