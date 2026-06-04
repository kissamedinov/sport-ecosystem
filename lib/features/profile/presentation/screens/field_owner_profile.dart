import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
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
          Text('club.field_owner_label'.tr(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildFinanceSummary(context),
          const SizedBox(height: 24),
          _buildManagedFields(context),
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
        title: Text('profile.logout'.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onTap: () async {
          await context.read<AuthProvider>().logout();
        },
      ),
    );
  }

  Widget _buildFinanceSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('profile.my_fields'.tr(), '2'),
            _buildStatItem('field.my_bookings'.tr(), '156'),
            _buildStatItem('profile.total_revenue'.tr(), '850K ₸'),
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

  Widget _buildManagedFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('profile.my_fields'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const ListTile(
          leading: Icon(Icons.stadium_outlined),
          title: Text('Emirates Stadium (Mock)'),
          subtitle: Text('Address: Isatay Batyr 141'),
        ),
        const ListTile(
          leading: Icon(Icons.stadium_outlined),
          title: Text('Academy Training Pitch'),
          subtitle: Text('Address: Abay Ave 45'),
        ),
      ],
    );
  }
}
