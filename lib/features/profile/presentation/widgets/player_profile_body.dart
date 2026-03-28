import 'package:flutter/material.dart';
import 'package:mobile/features/player_stats/data/models/player_stats.dart';
import 'package:mobile/features/player_stats/presentation/screens/player_stats_screen.dart';
import 'package:mobile/core/api/stats_api_service.dart';
import 'package:mobile/features/auth/presentation/screens/parent_requests_screen.dart';

class PlayerProfileBody extends StatefulWidget {
  final String playerProfileId;

  const PlayerProfileBody({super.key, required this.playerProfileId});

  @override
  State<PlayerProfileBody> createState() => _PlayerProfileBodyState();
}

class _PlayerProfileBodyState extends State<PlayerProfileBody> {
  final StatsApiService _statsApi = StatsApiService();
  late Future<PlayerStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _statsApi.getPlayerStats(widget.playerProfileId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayerStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading stats: ${snapshot.error}"));
        }
        final stats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("PERFORMANCE STATS"),
            _buildStatsGrid(stats),
            const SizedBox(height: 24),
            if (stats.awards.isNotEmpty) ...[
              _buildSectionTitle("LATEST AWARDS"),
              _buildAwardsList(stats.awards),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle("QUICK ACTIONS"),
            _buildActionCard(
              context,
              "View Detailed Career",
              Icons.analytics,
              Colors.indigo,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlayerStatsScreen(playerId: widget.playerProfileId)),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              "Parent Requests",
              Icons.group_add_rounded,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParentRequestsScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildStatsGrid(PlayerStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("GOALS", "${stats.goals}", Colors.greenAccent),
          _buildStatItem("ASSISTS", "${stats.assists}", Colors.blueAccent),
          _buildStatItem("SAVES", "${stats.saves}", Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAwardsList(List<String> awards) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: awards.length > 5 ? 5 : awards.length,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                const SizedBox(height: 8),
                Text(
                  awards[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
