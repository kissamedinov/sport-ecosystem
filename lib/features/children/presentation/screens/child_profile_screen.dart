import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/child.dart';

class ChildProfileScreen extends StatelessWidget {
  final Child child;

  const ChildProfileScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${child.name}\'s Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Age: ${child.age} | Team: ${child.teamName}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: child.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile ID copied to clipboard'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        child: Text('Profile ID: ${child.id.substring(0, 8)}...', 
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Season Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(context, 'Matches', child.matchesPlayed.toString(), Icons.sports_soccer),
                _buildStatCard(context, 'Goals', child.goals.toString(), Icons.sports_score),
                _buildStatCard(context, 'Assists', child.assists.toString(), Icons.handshake),
              ],
            ),
            const SizedBox(height: 32),
            
            // Coach Notes Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Coach Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                child.coachNotes.isNotEmpty ? child.coachNotes : 'No recent notes from the coach.',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
