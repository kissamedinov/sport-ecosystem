import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/models/user.dart';

class ParentProfile extends StatelessWidget {
  final User user;
  const ParentProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.family_restroom, size: 50)),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user.email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildChildrenSection(),
          const SizedBox(height: 24),
          _buildContactInfo(context),
        ],
      ),
    );
  }

  Widget _buildChildrenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Linked Children', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.child_care),
          title: const Text('Leo'),
          subtitle: const Text('Academy: Tigers U12'),
        ),
        ListTile(
          leading: const Icon(Icons.child_care),
          title: const Text('Mia'),
          subtitle: const Text('Academy: Lions U10'),
        ),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Contact Support'),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              // Implementation detail: AuthProvider handles the logout state
              // In MainNavigationScreen, watch<AuthProvider>().user will trigger a rebuild.
              // However, explicitly calling logout here is good.
              await context.read<AuthProvider>().logout();
            },
          ),
        ),
      ],
    );
  }
}
