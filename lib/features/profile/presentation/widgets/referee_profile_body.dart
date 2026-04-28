import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/matches/presentation/screens/match_events_screen.dart';

class RefereeProfileBody extends StatefulWidget {
  const RefereeProfileBody({super.key});

  @override
  State<RefereeProfileBody> createState() => _RefereeProfileBodyState();
}

class _RefereeProfileBodyState extends State<RefereeProfileBody> {
  final ProfileApiService _profileApi = ProfileApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _profileApi.getRefereeDashboard();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _profileApi.getRefereeDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final data = snapshot.data ?? {};
        final officiated = data['matches_officiated'] ?? 0;
        final upcomingCount = data['upcoming_count'] ?? 0;
        final recent = data['recent_officiated'] as List? ?? [];
        final upcoming = data['upcoming_matches'] as List? ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSectionLabel("OVERVIEW"),
              const SizedBox(height: 12),
              _buildStatsRow(officiated, upcomingCount),
              const SizedBox(height: 28),

              _buildSectionLabel("UPCOMING MATCHES"),
              const SizedBox(height: 12),
              _buildMatchList(upcoming),
              const SizedBox(height: 28),

              _buildSectionLabel("RECENTLY OFFICIATED"),
              const SizedBox(height: 12),
              _buildMatchList(recent),
              const SizedBox(height: 40),
            ],
          ),
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
              const Text(
                "SYSTEM ERROR",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _refresh,
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int officiated, int upcoming) {
    return Row(
      children: [
        Expanded(
          child: PremiumStatCard(
            title: "OFFICIATED",
            value: "$officiated",
            icon: Icons.gavel_rounded,
            color: PremiumTheme.neonGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumStatCard(
            title: "UPCOMING",
            value: "$upcoming",
            icon: Icons.event_rounded,
            color: PremiumTheme.electricBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchList(List matches) {
    if (matches.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.sports_soccer_rounded, color: Colors.white.withValues(alpha: 0.1), size: 32),
              const SizedBox(height: 12),
              Text(
                "NO MATCHES",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: matches.map((match) {
        final id = match['id']?.toString() ?? '';
        final scheduledAt = match['scheduled_at']?.toString() ?? '';
        final date = scheduledAt.length >= 10 ? scheduledAt.substring(0, 10) : 'TBD';
        final status = match['status']?.toString() ?? '';

        Color statusColor = status == 'SCHEDULED'
            ? PremiumTheme.neonGreen
            : status == 'FINISHED'
                ? Colors.white38
                : Colors.orangeAccent;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumCard(
            padding: const EdgeInsets.all(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: id)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sports_soccer_rounded, color: PremiumTheme.electricBlue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "MATCH",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
