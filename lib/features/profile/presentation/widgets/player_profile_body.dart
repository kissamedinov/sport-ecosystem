import 'package:flutter/material.dart';
import 'package:mobile/features/player_stats/data/models/player_stats.dart';
import 'package:mobile/features/player_stats/presentation/screens/player_stats_screen.dart';
import 'package:mobile/core/api/stats_api_service.dart';
import 'package:mobile/features/auth/presentation/screens/parent_requests_screen.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/player_stats/presentation/widgets/career_history_chart.dart';
import 'package:mobile/features/player_stats/data/models/match_history_item.dart';
import 'package:mobile/features/player_stats/data/models/player_career_stats.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';

class PlayerProfileBody extends StatefulWidget {
  final String playerProfileId;

  const PlayerProfileBody({super.key, required this.playerProfileId});

  @override
  State<PlayerProfileBody> createState() => _PlayerProfileBodyState();
}

class _PlayerProfileBodyState extends State<PlayerProfileBody> {
  final StatsApiService _statsApi = StatsApiService();
  late Future<PlayerStats> _statsFuture;
  late Future<PlayerCareerStats> _careerFuture;
  late Future<List<MatchHistoryItem>> _historyFuture;
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _statsApi.getPlayerStats(widget.playerProfileId);
    _careerFuture = _statsApi.getCareerStats(widget.playerProfileId);
    _historyFuture = _statsApi.getMatchHistory(widget.playerProfileId);
    
    // Fetch detailed profile (height, weight, position, foot)
    final authRepo = AuthRepository(_statsApi.apiClient);
    _profileFuture = authRepo.getUserProfile(widget.playerProfileId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayerStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        final stats = snapshot.data!;

        return FutureBuilder<PlayerCareerStats>(
          future: _careerFuture,
          builder: (context, careerSnapshot) {
            final career = careerSnapshot.data;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSectionLabel("CAREER OVERVIEW"),
                  const SizedBox(height: 12),
                  if (career != null) _buildCareerGrid(career) else _buildStatsGrid(stats),
                  const SizedBox(height: 28),

                  FutureBuilder<Map<String, dynamic>>(
                    future: _profileFuture,
                    builder: (context, profileSnapshot) {
                      if (profileSnapshot.hasData) {
                        final p = profileSnapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel("PHYSICAL ATTRIBUTES"),
                            const SizedBox(height: 12),
                            _buildPhysicalGrid(p),
                            const SizedBox(height: 28),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  FutureBuilder<List<MatchHistoryItem>>(
                    future: _historyFuture,
                    builder: (context, historySnapshot) {
                      if (historySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
                          ),
                        );
                      }
                      if (!historySnapshot.hasData || historySnapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final history = historySnapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel("GOALS DYNAMICS"),
                          const SizedBox(height: 12),
                          CareerHistoryChart(history: history),
                          const SizedBox(height: 28),
                          _buildSectionLabel("RECENT MATCHES"),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: history.length > 5 ? 5 : history.length,
                              itemBuilder: (context, index) => _buildMatchCard(history[index]),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      );
                    },
                  ),

                  if (stats.awards.isNotEmpty) ...[
                    _buildSectionLabel("LATEST AWARDS"),
                    const SizedBox(height: 12),
                    _buildAwardsList(stats.awards),
                    const SizedBox(height: 28),
                  ],

                  _buildSectionLabel("QUICK ACTIONS"),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.analytics_rounded,
                    label: "View Detailed Career",
                    color: PremiumTheme.electricBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlayerStatsScreen(playerId: widget.playerProfileId)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildActionCard(
                    icon: Icons.group_add_rounded,
                    label: "Parent Requests",
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ParentRequestsScreen()),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            const CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
            const SizedBox(height: 20),
            Text(
              "SYNCING DATA...",
              style: TextStyle(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: PremiumCard(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 16),
              Text(
                "SYSTEM ERROR",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => setState(() {
                  _statsFuture = _statsApi.getPlayerStats(widget.playerProfileId);
                  _careerFuture = _statsApi.getCareerStats(widget.playerProfileId);
                  _historyFuture = _statsApi.getMatchHistory(widget.playerProfileId);
                }),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("RETRY CONNECTION"),
                style: TextButton.styleFrom(foregroundColor: PremiumTheme.neonGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCareerGrid(PlayerCareerStats career) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PremiumStatCard(
                title: "RATING",
                value: career.rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumStatCard(
                title: "MATCHES",
                value: "${career.matchesPlayed}",
                icon: Icons.stadium_rounded,
                color: PremiumTheme.electricBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PremiumStatCard(
                title: "GOALS",
                value: "${career.goals}",
                icon: Icons.sports_soccer_rounded,
                color: PremiumTheme.neonGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumStatCard(
                title: "ASSISTS",
                value: "${career.assists}",
                icon: Icons.transfer_within_a_station_rounded,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumStatCard(
                title: "AWARDS",
                value: "${career.bestPlayerAwards}",
                icon: Icons.emoji_events_rounded,
                color: Colors.purpleAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(PlayerStats stats) {
    return Row(
      children: [
        Expanded(
          child: PremiumStatCard(
            title: "GOALS",
            value: "${stats.goals}",
            icon: Icons.sports_soccer_rounded,
            color: PremiumTheme.neonGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumStatCard(
            title: "ASSISTS",
            value: "${stats.assists}",
            icon: Icons.transfer_within_a_station_rounded,
            color: PremiumTheme.electricBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumStatCard(
            title: "SAVES",
            value: "${stats.saves}",
            icon: Icons.front_hand_rounded,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(MatchHistoryItem match) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.opponent,
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (match.isBestPlayer)
                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
            ],
          ),
          Text(
            match.tournamentName,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              _buildMiniTag("${match.goals}G", PremiumTheme.neonGreen),
              const SizedBox(width: 6),
              _buildMiniTag("${match.assists}A", PremiumTheme.electricBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onSurface.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildAwardsList(List<String> awards) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: awards.length > 5 ? 5 : awards.length,
        itemBuilder: (context, index) {
          return PremiumCard(
            width: 140,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                const SizedBox(height: 8),
                Text(
                  awards[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhysicalGrid(Map<String, dynamic> p) {
    return Row(
      children: [
        Expanded(
          child: _buildPhysicalCard(
            label: "POSITION",
            value: p['preferred_position'] ?? "N/A",
            icon: Icons.gps_fixed_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPhysicalCard(
            label: "FOOT",
            value: p['dominant_foot'] ?? "N/A",
            icon: Icons.directions_run_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPhysicalCard(
            label: "HEIGHT",
            value: p['height'] ?? "N/A",
            icon: Icons.height_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPhysicalCard(
            label: "WEIGHT",
            value: p['weight'] ?? "N/A",
            icon: Icons.monitor_weight_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalCard({required String label, required String value, required IconData icon}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: PremiumTheme.neonGreen.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.4), letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: onSurface),
          ),
        ],
      ),
    );
  }
}
