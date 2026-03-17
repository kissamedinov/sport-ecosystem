import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/club_provider.dart';

class CreateChildProfileScreen extends StatefulWidget {
  final String clubId;
  const CreateChildProfileScreen({super.key, required this.clubId});

  @override
  State<CreateChildProfileScreen> createState() => _CreateChildProfileScreenState();
}

class _CreateChildProfileScreenState extends State<CreateChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _positionController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Child Profile')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null 
                  ? 'Select Date of Birth' 
                  : 'DOB: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position (e.g. Forward)'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _selectedDate != null) {
                      final success = await context.read<ClubProvider>().createChildProfile({
                        'club_id': widget.clubId,
                        'first_name': _firstNameController.text,
                        'last_name': _lastNameController.text,
                        'date_of_birth': _selectedDate!.toIso8601String(),
                        'position': _positionController.text,
                      });
                      if (success && mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Create Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
