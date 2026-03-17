import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/club_provider.dart';

class PlayerCareerScreen extends StatefulWidget {
  final String profileId;
  const PlayerCareerScreen({super.key, required this.profileId});

  @override
  State<PlayerCareerScreen> createState() => _PlayerCareerScreenState();
}

class _PlayerCareerScreenState extends State<PlayerCareerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ClubProvider>().fetchPlayerCareer(widget.profileId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career History'),
      ),
      body: Consumer<ClubProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.playerCareer == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final career = provider.playerCareer;
          if (career == null) {
            return const Center(child: Text('No career data available'));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.person, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        career.playerName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatBadge('Goals', career.totalGoals.toString(), Colors.orange),
                          const SizedBox(width: 16),
                          _buildStatBadge('Assists', career.totalAssists.toString(), Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Timeline',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = career.careerHistory[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (index < career.careerHistory.length - 1)
                                Container(width: 2, height: 80, color: Colors.grey.withOpacity(0.3)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.teamName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(record.clubName),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateFormat('MMM yyyy').format(record.joinedAt)} - ${record.leftAt != null ? DateFormat('MMM yyyy').format(record.leftAt!) : 'Present'}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(record.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        record.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(record.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: career.careerHistory.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return Colors.green;
      case 'TRANSFERRED': return Colors.blue;
      case 'LEFT': return Colors.orange;
      case 'RETIRED': return Colors.red;
      default: return Colors.grey;
    }
  }
}
