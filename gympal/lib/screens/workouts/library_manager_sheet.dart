import 'package:flutter/material.dart';
import '../../data/services/exercise_library_service.dart';

class LibraryManagerSheet extends StatefulWidget {
  final Map<String, List<String>> initial;
  const LibraryManagerSheet({super.key, required this.initial});

  @override
  State<LibraryManagerSheet> createState() => _LibraryManagerSheetState();
}

class _LibraryManagerSheetState extends State<LibraryManagerSheet> {
  late Map<String, List<String>> _lib;
  late String _activeCategory;
  final _newCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lib = Map.fromEntries(widget.initial.entries.map((e) => MapEntry(e.key, List<String>.from(e.value))));
    _activeCategory = _lib.keys.first;
  }

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  void _addExercise() {
    final name = _newCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _lib[_activeCategory]!.add(name);
      _newCtrl.clear();
    });
  }

  void _removeExercise(int idx) {
    setState(() => _lib[_activeCategory]!.removeAt(idx));
  }

  Future<void> _save() async {
    await ExerciseLibraryService.saveLibrary(_lib);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: _lib.keys.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(cat),
                selected: _activeCategory == cat,
                onSelected: (_) => setState(() => _activeCategory = cat),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: _lib[_activeCategory]!.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(_lib[_activeCategory]![i]),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeExercise(i)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _newCtrl, decoration: const InputDecoration(labelText: 'New exercise'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addExercise, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}
