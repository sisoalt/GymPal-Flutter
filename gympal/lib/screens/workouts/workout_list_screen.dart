import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // For JSON
import '../../providers/workout_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/hive_service.dart';
import 'add_workout_screen.dart';
import 'workout_detail_screen.dart';

class Reminder {
  final int id;
  final DateTime dateTime;
  final String note;

  Reminder({required this.id, required this.dateTime, required this.note});

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'note': note,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'],
        dateTime: DateTime.parse(json['dateTime']),
        note: json['note'],
      );
}

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    final box = HiveService.settingsBox;
    final List<dynamic>? stored = box.get('scheduled_reminders');
    if (stored != null) {
      setState(() {
        _reminders = stored
            .map((e) => Reminder.fromJson(jsonDecode(e)))
            .toList();
      });
    }
  }

  Future<void> _saveReminders() async {
    final box = HiveService.settingsBox;
    final List<String> data = _reminders.map((e) => jsonEncode(e.toJson())).toList();
    await box.put('scheduled_reminders', data);
  }
  
  void _setReminder() async {
    // Request permissions
    await NotificationService().requestPermissions();

    // 1. Pick Date
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A90E2)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // 2. Pick Time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A90E2)),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // 3. Enter Note
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Note"),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: "e.g., Leg Day, Cardio...",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Skip"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, noteController.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    // Combine Date & Time
    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    
    // Ensure it's in the future
    if (scheduledDateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot schedule in the past!")),
        );
      }
      return;
    }

    final reminderBody = (note != null && note.isNotEmpty) ? note : "Time to workout!";

    // Schedule
    // Using a simple generating ID based on time for now to allow multiple
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await NotificationService().scheduleNotification(
      scheduledDateTime,
      "GymPal Reminder",
      reminderBody,
      id: id,
    );
    
    // Add to list and save
    final newReminder = Reminder(id: id, dateTime: scheduledDateTime, note: reminderBody);
    setState(() {
      _reminders.add(newReminder);
      // Sort by date handy
      _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
    await _saveReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reminder set for ${DateFormat('MMM d, h:mm a').format(scheduledDateTime)}"),
          backgroundColor: const Color(0xFF4A90E2),
        ),
      );
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    // Cancel notification
    // fln cancel uses int id
    await NotificationService().flutterLocalNotificationsPlugin.cancel(reminder.id);
    
    setState(() {
      _reminders.removeWhere((r) => r.id == reminder.id);
    });
    await _saveReminders();
    
    if(mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reminder deleted")));
    }
  }

  void _showRemindersList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
           return Column(
             children: [
               const SizedBox(height: 12),
               Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
               const Padding(
                 padding: EdgeInsets.all(16.0),
                 child: Text("Scheduled Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               ),
               Expanded(
                 child: _reminders.isEmpty
                     ? const Center(child: Text("No reminders set.", style: TextStyle(color: Colors.grey)))
                     : ListView.builder(
                         controller: controller,
                         itemCount: _reminders.length,
                         itemBuilder: (ctx, i) {
                           final r = _reminders[i];
                           return ListTile(
                             leading: const Icon(Icons.notifications_active, color: Color(0xFF4A90E2)),
                             title: Text(DateFormat('EEE, MMM d • h:mm a').format(r.dateTime)),
                             subtitle: Text(r.note),
                             trailing: IconButton(
                               icon: const Icon(Icons.delete_outline, color: Colors.grey),
                               onPressed: () {
                                 _deleteReminder(r);
                                 // Ideally update the state inside this sheet? 
                                 // Since the sheet is built from parent state, calling _deleteReminder (which calls setState) SHOULD rebuild the parent and thus the sheet?
                                 // Actually bottom sheets can be tricky with parent setStates.
                                 // Let's rely on Navigation.pop and re-open or use StatefulWidget wrapper if needed.
                                 // But simple setState in parent usually rebuilds the sheet IF the sheet builder is part of the parent's build... wait, showModalBottomSheet builder is separate.
                                 // To make the list update LIVE, we might need to wrap the sheet content in a StatefulBuilder OR just pop and re-open (clunky) OR use Provider.
                                 // Simple fix: Wrap the content in `StatefulBuilder` and pass the *internal* setState to _delete, OR purely rely on parent rebuild if Flutter handles it (it often doesn't for imperative push).
                                 // Actually, easiest way: Close sheet, delete, reopen? No.
                                 // Better: Use `StatefulBuilder` inside the sheet.
                                 Navigator.pop(ctx);
                                 _deleteReminder(r);
                                 _showRemindersList(); // Re-open (simple hack for instant update view)
                               }, 
                             ),
                           );
                         },
                       ),
               ),
             ],
           );
        },
      ),
    );
  }

  void _showReminderOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Color(0xFF4A90E2)),
              title: const Text("Schedule Workout"),
              onTap: () {
                Navigator.pop(ctx);
                _setReminder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Color(0xFF4A90E2)),
              title: const Text("My Reminders"),
              onTap: () {
                Navigator.pop(ctx);
                _showRemindersList();
              },
            ),
          ],
        ),
      ),
    );
  }

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
            icon: const Icon(Icons.alarm, color: Color(0xFF4A90E2)),
            tooltip: "Workout Reminder",
            onPressed: _showReminderOptions,
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