import 'package:flutter/material.dart';
import 'package:mobile/features/player_stats/data/models/player_stats.dart';
import 'package:mobile/features/player_stats/presentation/screens/player_stats_screen.dart';
import 'package:mobile/core/api/stats_api_service.dart';
import 'package:mobile/features/auth/presentation/screens/parent_requests_screen.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';

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
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: PremiumTheme.neonGreen)));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading stats: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  PremiumCard(
                    padding: EdgeInsets.zero,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlayerStatsScreen(playerId: widget.playerProfileId)),
                    ),
                    child: const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.analytics, color: PremiumTheme.electricBlue),
                      ),
                      title: Text("View Detailed Career", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PremiumCard(
                    padding: EdgeInsets.zero,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ParentRequestsScreen()),
                    ),
                    child: const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.group_add_rounded, color: Colors.orangeAccent),
                      ),
                      title: Text("Parent Requests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.chevron_right, color: Colors.white24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w900, 
          color: Colors.white38, 
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(PlayerStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: PremiumStatCard(
              title: "Goals",
              value: "${stats.goals}",
              icon: Icons.sports_soccer,
              color: PremiumTheme.neonGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PremiumStatCard(
              title: "Assists",
              value: "${stats.assists}",
              icon: Icons.assistant,
              color: PremiumTheme.electricBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PremiumStatCard(
              title: "Saves",
              value: "${stats.saves}",
              icon: Icons.security,
              color: Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsList(List<String> awards) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: awards.length > 5 ? 5 : awards.length,
        itemBuilder: (context, index) {
          return PremiumCard(
            width: 140,
            padding: const EdgeInsets.all(12),
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
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
