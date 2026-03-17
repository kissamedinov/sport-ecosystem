import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/models/user.dart';

class FieldOwnerProfile extends StatelessWidget {
  final User user;
  const FieldOwnerProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.stadium, size: 50)),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('FIELD OWNER / PARTNER', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildFinanceSummary(),
          const SizedBox(height: 24),
          _buildManagedFields(),
          const SizedBox(height: 24),
          _buildLogoutCard(context),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onTap: () async {
          await context.read<AuthProvider>().logout();
        },
      ),
    );
  }

  Widget _buildFinanceSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Active Fields', '2'),
            _buildStatItem('Bookings', '156'),
            _buildStatItem('Revenue', '850K ₸'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildManagedFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Registered Fields', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.stadium_outlined),
          title: const Text('Emirates Stadium (Mock)'),
          subtitle: const Text('Address: Isatay Batyr 141'),
        ),
        ListTile(
          leading: const Icon(Icons.stadium_outlined),
          title: const Text('Academy Training Pitch'),
          subtitle: const Text('Address: Abay Ave 45'),
        ),
      ],
    );
  }
}
