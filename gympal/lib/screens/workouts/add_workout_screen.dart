import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/workout_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/exercise_library.dart';
import '../../data/services/exercise_library_service.dart';
import 'library_manager_sheet.dart';
import '../../providers/workout_provider.dart';

class AddWorkoutScreen extends StatefulWidget {
  final WorkoutModel? existingWorkout; // If null = Add Mode, If set = Edit Mode

  const AddWorkoutScreen({super.key, this.existingWorkout});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _nameController = TextEditingController();

  // Data State
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Chest';
  List<ExerciseModel> _exercises = [];
  String _shortNote = 'None';
  final _customNoteCtrl = TextEditingController();
  Map<String, List<String>> _library = {};

  final List<String> _categories = [
    'Chest', 'Back', 'Legs', 'Arms', 'Shoulders', 'Cardio', 'Abs', 'Full Body'
  ];

  @override
  void initState() {
    super.initState();
    // Check if we are editing
    if (widget.existingWorkout != null) {
      final w = widget.existingWorkout!;
      _nameController.text = w.name;

      if (_categories.contains(w.category)) {
        _selectedCategory = w.category;
      } else {
        _selectedCategory = _categories.first;
      }

      _selectedDate = w.date;
      _exercises = List.from(w.exercises);

      if (w.shortNote.isNotEmpty) {
        if (['Felt strong', 'Lower energy today'].contains(w.shortNote)) {
          _shortNote = w.shortNote;
        } else {
          _shortNote = 'Custom...';
          _customNoteCtrl.text = w.shortNote;
        }
      }
    }

    // Load library (from settings if saved)
    try {
      _library = ExerciseLibraryService.loadLibrary();
      // Ensure categories from defaults exist
      for (final k in exerciseLibrary.keys) {
        _library.putIfAbsent(k, () => List<String>.from(exerciseLibrary[k]!));
      }
    } catch (_) {
      _library = Map<String, List<String>>.from(exerciseLibrary);
    }
  }

  // --- Helper: Date Picker ---
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }



  void _showExerciseDialogWithInitial(String initialName) {
    final nameCtrl = TextEditingController(text: initialName);
    final setsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    
    // For single reps mode
    final repsCtrl = TextEditingController();
    
    // For individual reps mode
    bool sameReps = true;
    List<TextEditingController> indivRepCtrls = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState2) => AlertDialog(
          title: const Text('Add Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exercise Name')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: setsCtrl, 
                        keyboardType: TextInputType.number, 
                        decoration: const InputDecoration(labelText: 'Sets'),
                        onChanged: (val) {
                          final s = int.tryParse(val) ?? 0;
                          setState2(() {
                            // Sync indivRepCtrls list with sets number
                            if (indivRepCtrls.length < s) {
                              while (indivRepCtrls.length < s) {
                                indivRepCtrls.add(TextEditingController());
                              }
                            } else if (indivRepCtrls.length > s) {
                              indivRepCtrls.removeRange(s, indivRepCtrls.length);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)'))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: sameReps, 
                      onChanged: (val) => setState2(() => sameReps = val ?? true),
                    ),
                    const Text('Same reps for all sets', style: TextStyle(fontSize: 13)),
                  ],
                ),
                if (sameReps)
                  TextField(controller: repsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps per set'))
                else
                  ...List.generate(indivRepCtrls.length, (index) => Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: indivRepCtrls[index],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Reps for Set ${index + 1}',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final setsStr = setsCtrl.text.trim();
                final sets = int.tryParse(setsStr);
                final weight = double.tryParse(weightCtrl.text) ?? 0.0;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter exercise name')));
                  return;
                }
                if (sets == null || sets < 1 || sets > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sets must be between 1 and 100')));
                  return;
                }

                String finalReps = "";
                if (sameReps) {
                  final r = int.tryParse(repsCtrl.text);
                  if (r == null || r < 1) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid reps')));
                    return;
                  }
                  finalReps = r.toString();
                } else {
                  List<String> repList = [];
                  for (var ctrl in indivRepCtrls) {
                    final r = int.tryParse(ctrl.text);
                    if (r == null || r < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('One or more sets have invalid reps')));
                      return;
                    }
                    repList.add(r.toString());
                  }
                  finalReps = repList.join(', ');
                }

                setState(() => _exercises.add(ExerciseModel(
                  name: name, 
                  sets: sets.toString(), 
                  reps: finalReps, 
                  weight: weight.toString()
                )));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLibraryDialog(void Function(String) onSelected) {
    String activeCategory = _selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState2) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _library.keys.map((cat) => Padding(
                          padding: const EdgeInsets.only(right:8.0),
                          child: ChoiceChip(label: Text(cat), selected: activeCategory == cat, onSelected: (_) => setState2(() => activeCategory = cat)),
                        )).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit Library',
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final saved = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => LibraryManagerSheet(initial: _library),
                      );
                      if (saved == true) {
                        setState(() => _library = ExerciseLibraryService.loadLibrary());
                        setState2(() => activeCategory = _selectedCategory);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: ListView(children: (_library[activeCategory] ?? []).map((ex) => ListTile(title: Text(ex), onTap: () { Navigator.pop(ctx); onSelected(ex); })).toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  void _saveWorkout() {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one exercise')));
      return;
    }

    final note = _shortNote == 'Custom...' ? _customNoteCtrl.text : (_shortNote == 'None' ? '' : _shortNote);

    final workoutData = WorkoutModel(
      name: _nameController.text.isEmpty ? "$_selectedCategory Workout" : _nameController.text,
      category: _selectedCategory,
      date: _selectedDate,
      exercises: _exercises,
      duration: '0',
      shortNote: note,
    );

    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    if (widget.existingWorkout != null) {
      provider.editWorkout(widget.existingWorkout!, workoutData);
    } else {
      provider.addWorkout(workoutData);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingWorkout == null ? 'New Workout' : 'Edit Workout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                      child: Text(DateFormat('MMM d, y').format(_selectedDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Description (Optional)', hintText: 'e.g. Heavy Lift Day')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exercises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(children: [
                  // Top 'Add' removed per UI change request — use library or bottom Add
                  TextButton.icon(icon: const Icon(Icons.list), label: const Text('Library'), onPressed: () => _showLibraryDialog((sel) => _showExerciseDialogWithInitial(sel))),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _exercises.isEmpty
                  ? Center(child: Text('No exercises yet', style: TextStyle(color: Colors.grey[500])))
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (ctx, i) {
                        final ex = _exercises[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text(ex.name),
                            subtitle: Text('${ex.sets} sets × ${ex.reps.contains(',') ? '[${ex.reps}]' : ex.reps} reps • ${ex.weight}kg'),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _exercises.removeAt(i))),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _shortNote,
                  items: ['None', 'Felt strong', 'Lower energy today', 'Custom...'].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (v) => setState(() => _shortNote = v ?? 'None'),
                  decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
                ),
              ),
            ]),
            if (_shortNote == 'Custom...') ...[
              const SizedBox(height: 8),
              TextField(controller: _customNoteCtrl, decoration: const InputDecoration(labelText: 'Custom note', border: OutlineInputBorder())),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _saveWorkout, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2), foregroundColor: Colors.white), child: Text(widget.existingWorkout == null ? 'Log Workout' : 'Update Workout')),
            ),
          ],
        ),
      ),
    );
  }
}