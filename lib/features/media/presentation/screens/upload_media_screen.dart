import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/media/data/repositories/media_repository.dart';

class UploadMediaScreen extends StatefulWidget {
  final String? clubId;
  final String? tournamentId;

  const UploadMediaScreen({
    super.key,
    this.clubId,
    this.tournamentId,
  });

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  File? _selectedFile;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);
    try {
      await context.read<MediaRepository>().uploadMedia(
        file: _selectedFile!,
        title: _titleController.text,
        description: _descriptionController.text,
        clubId: widget.clubId,
        tournamentId: widget.tournamentId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('UPLOAD MEDIA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: PremiumCard(
                height: 200,
                child: _selectedFile != null
                    ? Image.file(_selectedFile!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: PremiumTheme.neonGreen),
                          const SizedBox(height: 12),
                          const Text('Select Photo', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: PremiumTheme.inputDecorationOf(context, 'Title', prefixIcon: Icons.title),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: PremiumTheme.inputDecorationOf(context, 'Description', prefixIcon: Icons.description),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 40),
            if (_isUploading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _selectedFile == null ? null : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.neonGreen,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Upload to Cloud', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
          ],
        ),
      ),
    );
  }
}
