import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? "");
    _bioController = TextEditingController(text: user?.bio ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
      );
      
      if (image != null) {
        setState(() => _isUploadingImage = true);
        final success = await context.read<AuthProvider>().uploadAvatar(image.path);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await context.read<AuthProvider>().updateProfile({
        "name": _nameController.text,
        "bio": _bioController.text,
      });
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        title: const Text("EDIT PROFILE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text("SAVE", style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold)),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarEdit(),
              const SizedBox(height: 40),
              _buildSectionLabel("PERSONAL INFORMATION"),
              const SizedBox(height: 16),
              _buildTextField("Full Name", _nameController, Icons.person_outline_rounded),
              const SizedBox(height: 24),
              _buildSectionLabel("BIO / DESCRIPTION"),
              const SizedBox(height: 16),
              _buildTextField(
                "Tell us about yourself...", 
                _bioController, 
                Icons.description_outlined, 
                maxLines: 4,
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "Your information is visible to other club members and professionals.",
                  style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarEdit() {
    final user = context.watch<AuthProvider>().user;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtly glowing outer ring
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  PremiumTheme.neonGreen.withOpacity(0.5),
                  PremiumTheme.electricBlue.withOpacity(0.5),
                  PremiumTheme.neonGreen.withOpacity(0.5),
                ],
              ),
            ),
          ),
          // Inner avatar container
          GestureDetector(
            onTap: _isUploadingImage ? null : _pickImage,
            child: Container(
              width: 124, height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PremiumTheme.cardNavy,
                image: user?.avatarUrl != null 
                  ? DecorationImage(image: NetworkImage(user!.avatarUrl!), fit: BoxFit.cover)
                  : null,
                border: Border.all(color: PremiumTheme.deepNavy, width: 4),
              ),
              child: user?.avatarUrl == null 
                ? Center(
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : "?",
                      style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  )
                : null,
            ),
          ),
          // Uploading overlay
          if (_isUploadingImage)
            Container(
              width: 124, height: 124,
              decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2)),
            ),
          // Edit badge
          if (!_isUploadingImage)
            Positioned(
              bottom: 4, right: 4,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen, 
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: PremiumTheme.neonGreen.withOpacity(0.5), blurRadius: 10)],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: PremiumTheme.neonGreen.withOpacity(0.5), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide(color: PremiumTheme.neonGreen.withOpacity(0.3)),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
    );
  }
}
