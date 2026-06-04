import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
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
          _buildChildrenSection(context),
          const SizedBox(height: 24),
          _buildContactInfo(context),
        ],
      ),
    );
  }

  Widget _buildChildrenSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('children.my_children'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const ListTile(
          leading: Icon(Icons.child_care),
          title: Text('Leo'),
          subtitle: Text('Academy: Tigers U12'),
        ),
        const ListTile(
          leading: Icon(Icons.child_care),
          title: Text('Mia'),
          subtitle: Text('Academy: Lions U10'),
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
            title: Text('profile.contact_support'.tr()),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('profile.logout'.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
        ),
      ],
    );
  }
}
