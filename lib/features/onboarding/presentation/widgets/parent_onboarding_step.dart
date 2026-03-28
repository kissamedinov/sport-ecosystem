import 'package:flutter/material.dart';

class ParentOnboardingStep extends StatefulWidget {
  final Function(String firstName, String lastName, DateTime dob, String position) onNext;

  const ParentOnboardingStep({super.key, required this.onNext});

  @override
  State<ParentOnboardingStep> createState() => _ParentOnboardingStepState();
}

class _ParentOnboardingStepState extends State<ParentOnboardingStep> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime _dob = DateTime.now().subtract(const Duration(days: 3650));
  String _position = 'MF';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.child_care, size: 60, color: Color(0xFF00E676)),
              const SizedBox(height: 24),
              Text(
                'Add Your Child',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Link your child profile to track their stats.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Child First Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Child Last Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Birth Date'),
                subtitle: Text('${_dob.day}/${_dob.month}/${_dob.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dob,
                    firstDate: DateTime(1990),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _dob = picked);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _position,
                decoration: const InputDecoration(labelText: 'Position'),
                items: ['GK', 'DF', 'MF', 'FW'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => _position = val!),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onNext(_firstNameController.text, _lastNameController.text, _dob, _position);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF00E676),
                ),
                child: const Text('ADD CHILD & CONTINUE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
