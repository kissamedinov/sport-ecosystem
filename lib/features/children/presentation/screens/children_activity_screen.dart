import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/child_provider.dart';

class ChildrenActivityScreen extends StatefulWidget {
  final String? childId;
  final String? childName;

  const ChildrenActivityScreen({
    super.key, 
    this.childId, 
    this.childName
  });

  @override
  State<ChildrenActivityScreen> createState() => _ChildrenActivityScreenState();
}

class _ChildrenActivityScreenState extends State<ChildrenActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChildProvider>();
      if (widget.childId != null) {
        provider.fetchActivities(widget.childId!);
        provider.fetchAwards(widget.childId!);
      } else {
        provider.fetchChildren().then((_) {
          if (provider.children.isNotEmpty) {
            final firstChildId = provider.children.first.id;
            provider.fetchActivities(firstChildId);
            provider.fetchAwards(firstChildId);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildProvider>();
    final displayName = widget.childName ?? (provider.children.isNotEmpty ? provider.children.first.name : 'CHILD');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${displayName.toUpperCase()}\'S ACTIVITY'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'MATCHES'),
              Tab(text: 'AWARDS'),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildActivityList(provider.activities),
                  _buildAwardsList(provider.awards),
                ],
              ),
      ),
    );
  }

  Widget _buildActivityList(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return const Center(child: Text('No match activity found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.sports_soccer)),
            title: const Text('Match History'), 
            subtitle: Text('Score: ${activity['home_score']} - ${activity['away_score']}'),
            trailing: Text(activity['created_at']?.split('T')?.first ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildAwardsList(List<Map<String, dynamic>> awards) {
    if (awards.isEmpty) {
      return const Center(child: Text('No awards received yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: awards.length,
      itemBuilder: (context, index) {
        final award = awards[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.orange, size: 36),
            title: Text(award['award_type'] ?? 'Achievement', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(award['tournament_name'] ?? 'Tournament'),
            trailing: Text(award['awarded_at']?.split('T')?.first ?? ''),
          ),
        );
      },
    );
  }
}
