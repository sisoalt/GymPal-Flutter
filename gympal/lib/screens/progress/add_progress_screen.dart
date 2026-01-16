import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/models/progress_model.dart';
import '../../providers/progress_provider.dart';

class AddProgressScreen extends StatefulWidget {
  final ProgressModel? existingLog; // NEW: Optional parameter for editing

  const AddProgressScreen({super.key, this.existingLog});

  @override
  State<AddProgressScreen> createState() => _AddProgressScreenState();
}

class _AddProgressScreenState extends State<AddProgressScreen> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _base64Image; 
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    // NEW: Check if we are in Edit Mode
    if (widget.existingLog != null) {
      _weightController.text = widget.existingLog!.weight.toString();
      _notesController.text = widget.existingLog!.notes;
      _base64Image = widget.existingLog!.photoPath;
      
      // If there is an existing image, decode it for preview
      if (_base64Image != null && _base64Image!.isNotEmpty) {
        try {
          _webImageBytes = base64Decode(_base64Image!);
        } catch (e) {
          debugPrint("Error decoding image: $e");
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _webImageBytes = bytes;
          _base64Image = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  void _save() {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter weight")));
      return;
    }

    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;

    final provider = Provider.of<ProgressProvider>(context, listen: false);

    if (widget.existingLog != null) {
      // NEW: Update Logic
      provider.editProgress(
        widget.existingLog!,
        weight,
        _notesController.text,
        _base64Image,
      );
    } else {
      // Add New Logic
      final log = ProgressModel(
        date: DateTime.now(),
        weight: weight,
        notes: _notesController.text,
        photoPath: _base64Image,
      );
      provider.addProgress(log);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingLog != null ? "Edit Log" : "Log Progress")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _webImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _webImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Tap to upload photo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Current Weight (kg)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.existingLog != null ? "Update Log" : "Save Log"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}