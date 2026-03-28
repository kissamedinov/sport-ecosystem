import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/premium_theme.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Child'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Register Your Child',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Link your child\'s account to your parent dashboard to track their progress.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              // Name Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: PremiumTheme.inputDecoration('First Name'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: PremiumTheme.inputDecoration('Last Name'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date of Birth Field
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: PremiumTheme.neonGreen,
                          onPrimary: Colors.black,
                          surface: PremiumTheme.cardNavy,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null 
                            ? 'Select Date of Birth' 
                            : 'DOB: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.white38 : Colors.white,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: PremiumTheme.neonGreen, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: PremiumTheme.inputDecoration('Child Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: PremiumTheme.inputDecoration('Child Account Password'),
                obscureText: true,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Invite Code Field (Optional)
              TextFormField(
                controller: _inviteCodeController,
                decoration: PremiumTheme.inputDecoration('Academy Invite Code (Optional)'),
              ),
              const SizedBox(height: 32),
              
              Consumer<AuthProvider>(
                builder: (context, auth, _) => ElevatedButton(
                  onPressed: auth.isLoading ? null : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      if (_selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select Date of Birth')),
                        );
                        return;
                      }

                      final success = await auth.createChild(
                        firstName: _firstNameController.text,
                        lastName: _lastNameController.text,
                        dob: _selectedDate!,
                        email: _emailController.text,
                        password: _passwordController.text,
                        inviteCode: _inviteCodeController.text.isEmpty ? null : _inviteCodeController.text,
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Child account created for ${_firstNameController.text}!')),
                        );
                        Navigator.pop(context);
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(auth.error ?? 'Failed to create child account')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Create Child Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
