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
  
  // Multiple images support
  final List<String> _base64Images = []; 
  final List<Uint8List> _webImageBytesList = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      _weightController.text = widget.existingLog!.weight.toString();
      _notesController.text = widget.existingLog!.notes;
      
      // Load existing images (from both photoPath and photoPaths)
      if (widget.existingLog!.photoPath != null && widget.existingLog!.photoPath!.isNotEmpty) {
        _addImageFromBase64(widget.existingLog!.photoPath!);
      }
      if (widget.existingLog!.photoPaths != null) {
        for (var path in widget.existingLog!.photoPaths!) {
          _addImageFromBase64(path);
        }
      }
    }
  }

  void _addImageFromBase64(String base64Str) {
    if (base64Str.isEmpty) return;
    try {
      final bytes = base64Decode(base64Str);
      setState(() {
        _base64Images.add(base64Str);
        _webImageBytesList.add(bytes);
      });
    } catch (e) {
      debugPrint("Error decoding image: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      // Using pickMultiImage for convenience
      final List<XFile> pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);
          
          setState(() {
            _webImageBytesList.add(bytes);
            _base64Images.add(base64String);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _webImageBytesList.removeAt(index);
      _base64Images.removeAt(index);
    });
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
      provider.editProgress(
        widget.existingLog!,
        weight,
        _notesController.text,
        _base64Images.isNotEmpty ? _base64Images.first : null, // Keep photoPath for compat
        _base64Images,
      );
    } else {
      final log = ProgressModel(
        date: DateTime.now(),
        weight: weight,
        notes: _notesController.text,
        photoPath: _base64Images.isNotEmpty ? _base64Images.first : null,
        photoPaths: _base64Images,
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
            // Images Gallery Section
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: _webImageBytesList.isEmpty
                  ? GestureDetector(
                      onTap: _pickImage,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Tap to upload photo(s)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _webImageBytesList.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _webImageBytesList.length) {
                              // Add more button at the end
                              return GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 150,
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add_photo_alternate_rounded, size: 40, color: Color(0xFF4A90E2)),
                                  ),
                                ),
                              );
                            }
                            return Stack(
                              children: [
                                Container(
                                  width: 200,
                                  margin: const EdgeInsets.all(8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _webImageBytesList[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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