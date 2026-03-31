import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';

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
              const Text(
                "Your information is visible to other club members and professionals. Profile picture upload is coming soon.",
                style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
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
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: PremiumTheme.neonGreen.withOpacity(0.3), width: 2),
              gradient: const LinearGradient(colors: [Color(0xFF1E2734), Color(0xFF161B22)]),
            ),
            child: Center(
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : "?",
                style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: PremiumTheme.neonGreen, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.black),
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
