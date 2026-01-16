import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../workouts/workout_detail_screen.dart';
import '../calories/calorie_tracker_screen.dart';
import '../progress/progress_screen.dart';
import '../activity/all_activity_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/progress_provider.dart';

import '../../widgets/charts/workout_bar_chart.dart';
import '../../widgets/charts/detailed_calorie_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final userName = user?.fullName.split(' ')[0] ?? 'User';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(context, userName, user),
              const SizedBox(height: 24),

              // Stats Summary Cards
              Text(
                "Today's Summary",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Consumer2<CalorieProvider, WorkoutProvider>(builder: (context, cp, wp, _) {
                return _buildStatsGrid(context, cp, wp);
              }),
              const SizedBox(height: 24),

              // Weekly Overview
              Text(
                "This Week",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildWeeklyOverview(context),
              const SizedBox(height: 24),

              // Charts
              const WorkoutBarChart(),
              const SizedBox(height: 16),
              const DetailedCalorieChart(),
              const SizedBox(height: 24),

              // Body Metrics (if available)
              if (user?.height != null && user?.weight != null) ...[
                Text(
                  "Body Metrics",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBodyMetrics(context, user!),
                const SizedBox(height: 24),
              ],

              // Recent Activity
              Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentActivity(context),
              const SizedBox(height: 8),
              _buildShowAllButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Photo or Initial
          _buildProfileAvatar(context, user),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, $userName 👋",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  "Let's crush your goals today!",
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, user) {
    // Note: Profile photos work on mobile/desktop builds
    // For web builds, we show the initial since File operations aren't supported
    return CircleAvatar(
      radius: 30,
      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
      child: Text(
        user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : "?",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, CalorieProvider cp, WorkoutProvider wp) {
    final now = DateTime.now();
    final todayWorkouts = wp.workouts.where((w) => 
      w.date.year == now.year && w.date.month == now.month && w.date.day == now.day
    ).toList();
    
    final workoutCount = todayWorkouts.length;
    final exerciseCount = todayWorkouts.fold(0, (sum, w) => sum + w.exercises.length);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context,
            "Calories",
            cp.totalCalories.toString(),
            "kcal",
            Icons.local_fire_department,
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(context,
            "Workouts",
            workoutCount.toString(),
            "$exerciseCount exercises",
            Icons.fitness_center,
            const Color(0xFF4A90E2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()))),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview(BuildContext context) {
    final wp = Provider.of<WorkoutProvider>(context);
    final pp = Provider.of<ProgressProvider>(context);
    final cp = Provider.of<CalorieProvider>(context);

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Workouts completed this week
    final workoutsCompleted = wp.workouts.where((w) {
      final d = w.date;
      return !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek);
    }).length;

    // Total calories this week
    final totalCaloriesWeek = cp.totalCaloriesForRange(startOfWeek, endOfWeek);

    // Progress entries this week
    final progressEntries = pp.logs.where((l) {
      final d = l.date;
      return !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek);
    }).length;

    // Active days (unique workout days)
    final activeDaysSet = <String>{};
    for (var w in wp.workouts) {
      final d = w.date;
      if (!d.isBefore(startOfWeek) && !d.isAfter(endOfWeek)) {
        activeDaysSet.add('${d.year}-${d.month}-${d.day}');
      }
    }
    final activeDays = activeDaysSet.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
        child: Column(
        children: [
              _buildWeeklyStatRow(context, "Workouts Completed", workoutsCompleted.toString(), Icons.fitness_center,
                const Color(0xFF4A90E2)),
            const Divider(height: 24),
            _buildWeeklyStatRow(context, "Total Calories", "$totalCaloriesWeek kcal",
              Icons.local_fire_department, const Color(0xFFEF4444)),
            const Divider(height: 24),
            _buildWeeklyStatRow(context, "Progress Entries", progressEntries.toString(), Icons.trending_up,
              const Color(0xFF10B981)),
            const Divider(height: 24),
            _buildWeeklyStatRow(context, "Active Days", "$activeDays / 7", Icons.calendar_today,
              const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatRow(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500))),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildBodyMetrics(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withAlpha((0.3 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(context, "Height",
              "${user.height?.toStringAsFixed(0) ?? 'N/A'} cm", Icons.height),
          Container(
              width: 1, height: 40, color: Colors.white.withAlpha((0.3 * 255).round())),
          _buildMetricItem(
              context,
              "Weight",
              "${user.weight?.toStringAsFixed(1) ?? 'N/A'} kg",
              Icons.monitor_weight),
          Container(
              width: 1, height: 40, color: Colors.white.withAlpha((0.3 * 255).round())),
          _buildMetricItem(
              context,
              "BMI", user.bmi?.toStringAsFixed(1) ?? 'N/A', Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha((0.8 * 255).round()),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final wp = Provider.of<WorkoutProvider>(context);
    final cp = Provider.of<CalorieProvider>(context);
    final pp = Provider.of<ProgressProvider>(context);

    // Collect recent items from workouts, food logs (today), and progress logs
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

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round())),
            const SizedBox(height: 12),
            Text(
              "No activity yet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())),
            ),
            const SizedBox(height: 4),
            Text(
              "Start logging workouts and meals to see your activity here",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round())),
            ),
          ],
        ),
      );
    }

    items.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    final df = DateFormat('MMM d, h:mm a');
    final showCount = items.length > 5 ? 5 : items.length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: showCount,
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

  Widget _buildShowAllButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AllActivityScreen()));
        },
        child: const Text('Show all activity'),
      ),
    );
  }
}
