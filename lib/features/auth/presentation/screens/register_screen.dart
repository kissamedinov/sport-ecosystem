import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedRole = 'PLAYER_ADULT';
  final List<Map<String, String>> _roles = [
    {'value': 'PLAYER_ADULT', 'label': 'Adult Player', 'icon': 'person'},
    {'value': 'PLAYER_CHILD', 'label': 'Youth Player', 'icon': 'child_care'},
    {'value': 'PARENT', 'label': 'Parent', 'icon': 'family_restroom'},
    {'value': 'COACH', 'label': 'Coach', 'icon': 'sports'},
    {'value': 'TOURNAMENT_ORGANIZER', 'label': 'Organizer', 'icon': 'event_note'},
    {'value': 'CLUB_OWNER', 'label': 'Club Owner', 'icon': 'business'},
    {'value': 'CLUB_MANAGER', 'label': 'Club Manager', 'icon': 'manage_accounts'},
    {'value': 'FIELD_OWNER', 'label': 'Field Owner', 'icon': 'stadium'},
    {'value': 'REFEREE', 'label': 'Referee', 'icon': 'gavel'},
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register({
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': _selectedRole,
      'date_of_birth': '2000-01-01', // Default; can be updated in profile
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please log in.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join the Ecosystem',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Role Selection
                const Text('I am a...', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roles.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      final isSelected = _selectedRole == role['value'];
                      final accent = PremiumTheme.accent(context);
                      final muted = Theme.of(context).colorScheme.onSurfaceVariant;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRole = role['value']!),
                        child: Container(
                          width: 90,
                          decoration: BoxDecoration(
                            color: isSelected ? accent.withValues(alpha: 0.1) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? accent : Theme.of(context).colorScheme.outline,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getIconData(role['icon']!),
                                color: isSelected ? accent : muted,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role['label']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? accent : muted,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => 
                    (value == null || value.isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => 
                    (value == null || value.isEmpty) ? 'Please enter email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) => 
                    (value == null || value.length < 6) ? 'Password too short' : null,
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      child: auth.isLoading 
                        ? const CircularProgressIndicator() 
                        : const Text('REGISTER'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'person': return Icons.person;
      case 'child_care': return Icons.child_care;
      case 'family_restroom': return Icons.family_restroom;
      case 'sports': return Icons.sports;
      case 'event_note': return Icons.event_note;
      case 'stadium': return Icons.stadium;
      case 'gavel': return Icons.gavel;
      case 'business': return Icons.business;
      case 'manage_accounts': return Icons.manage_accounts;
      default: return Icons.help;
    }
  }
}
