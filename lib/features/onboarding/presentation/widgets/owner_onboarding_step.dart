import 'package:flutter/material.dart';

class OwnerOnboardingStep extends StatefulWidget {
  final Function(String name, String address, String schedule) onNext;

  const OwnerOnboardingStep({super.key, required this.onNext});

  @override
  State<OwnerOnboardingStep> createState() => _OwnerOnboardingStepState();
}

class _OwnerOnboardingStepState extends State<OwnerOnboardingStep> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _scheduleController = TextEditingController();
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
              const Icon(Icons.business, size: 60, color: Color(0xFF00E676)),
              const SizedBox(height: 24),
              Text(
                'Club Registration',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Club Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Main Office Address'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(
                  labelText: 'Default Training Schedule',
                  hintText: 'e.g. Mon-Fri 17:00-19:00',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onNext(_nameController.text, _addressController.text, _scheduleController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF00E676),
                ),
                child: const Text('SUBMIT CLUB & CONTINUE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
