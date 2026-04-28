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

  @override
  void initState() {
    super.initState();
    _statsFuture = _statsApi.getPlayerStats(widget.playerProfileId);
    _careerFuture = _statsApi.getCareerStats(widget.playerProfileId);
    _historyFuture = _statsApi.getMatchHistory(widget.playerProfileId);
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
          return Center(child: Text("Error loading stats: ${snapshot.error}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
        }
        final stats = snapshot.data!;

        return FutureBuilder<PlayerCareerStats>(
          future: _careerFuture,
          builder: (context, careerSnapshot) {
            final career = careerSnapshot.data;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("CAREER OVERVIEW"),
                if (career != null) _buildCareerGrid(career) else _buildStatsGrid(stats),
                const SizedBox(height: 24),
                
                // Career History Dynamic Chart
                FutureBuilder<List<MatchHistoryItem>>(
                  future: _historyFuture,
                  builder: (context, historySnapshot) {
                    if (historySnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen)),
                      );
                    }
                    if (historySnapshot.hasError || !historySnapshot.hasData) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CareerHistoryChart(history: historySnapshot.data!),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Recent Matches List
                FutureBuilder<List<MatchHistoryItem>>(
                  future: _historyFuture,
                  builder: (context, historySnapshot) {
                    if (historySnapshot.hasData && historySnapshot.data!.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("RECENT MATCHES"),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: historySnapshot.data!.length > 5 ? 5 : historySnapshot.data!.length,
                              itemBuilder: (context, index) {
                                final match = historySnapshot.data![index];
                                return _buildMatchCard(match);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),

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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                            child: const Icon(Icons.analytics, color: PremiumTheme.electricBlue),
                          ),
                          title: Text("View Detailed Career", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PremiumCard(
                        padding: EdgeInsets.zero,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ParentRequestsScreen()),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                            child: const Icon(Icons.group_add_rounded, color: Colors.orangeAccent),
                          ),
                          title: Text("Parent Requests", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 2,
        ),
      ),
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
          const SizedBox(height: 4),
          Text(
            match.tournamentName,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
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

  Widget _buildCareerGrid(PlayerCareerStats career) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PremiumStatCard(
                  title: "Rating",
                  value: career.rating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumStatCard(
                  title: "Matches",
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
                  title: "Goals",
                  value: "${career.goals}",
                  icon: Icons.sports_soccer,
                  color: PremiumTheme.neonGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumStatCard(
                  title: "Assists",
                  value: "${career.assists}",
                  icon: Icons.assistant,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumStatCard(
                  title: "Awards",
                  value: "${career.bestPlayerAwards}",
                  icon: Icons.emoji_events_rounded,
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
        ],
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
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
