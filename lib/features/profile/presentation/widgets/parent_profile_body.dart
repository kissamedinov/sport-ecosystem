import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/clubs/data/models/child_profile.dart';
import 'package:mobile/features/matches/data/models/match.dart';
import 'package:mobile/features/player_stats/presentation/screens/player_stats_screen.dart';
import 'package:mobile/features/matches/presentation/screens/match_events_screen.dart';
import 'package:mobile/features/auth/presentation/screens/my_children_screen.dart';

class ParentProfileBody extends StatefulWidget {
  const ParentProfileBody({super.key});

  @override
  State<ParentProfileBody> createState() => _ParentProfileBodyState();
}

class _ParentProfileBodyState extends State<ParentProfileBody> {
  final ProfileApiService _profileApi = ProfileApiService();
  late Future<List<ChildProfile>> _childrenFuture;
  late Future<List<MatchModel>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _childrenFuture = _profileApi.getChildProfiles().catchError((_) => <ChildProfile>[]);
    _matchesFuture = _profileApi.getChildrenUpcomingMatches().catchError((_) => <MatchModel>[]);
  }

  void _refresh() {
    setState(() {
      _childrenFuture = _profileApi.getChildProfiles().catchError((_) => <ChildProfile>[]);
      _matchesFuture = _profileApi.getChildrenUpcomingMatches().catchError((_) => <MatchModel>[]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChildProfile>>(
      future: _childrenFuture,
      builder: (context, childSnapshot) {
        return FutureBuilder<List<MatchModel>>(
          future: _matchesFuture,
          builder: (context, matchSnapshot) {
            final isLoading =
                childSnapshot.connectionState == ConnectionState.waiting ||
                matchSnapshot.connectionState == ConnectionState.waiting;

            if (isLoading) return _buildLoadingState();

            final children = childSnapshot.data ?? [];
            final matches = matchSnapshot.data ?? [];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSectionLabel("OVERVIEW"),
                  const SizedBox(height: 12),
                  _buildStatsRow(children.length, matches.length),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSectionLabel("MY CHILDREN  •  ${children.length}"),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyChildrenScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            "MANAGE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: PremiumTheme.electricBlue,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildChildrenList(children),
                  const SizedBox(height: 28),

                  _buildSectionLabel("UPCOMING MATCHES"),
                  const SizedBox(height: 12),
                  _buildUpcomingMatches(matches),
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

  Widget _buildStatsRow(int childCount, int matchCount) {
    return Row(
      children: [
        Expanded(
          child: PremiumStatCard(
            title: "CHILDREN",
            value: "$childCount",
            icon: Icons.child_care_rounded,
            color: PremiumTheme.neonGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumStatCard(
            title: "MATCHES",
            value: "$matchCount",
            icon: Icons.event_rounded,
            color: PremiumTheme.electricBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenList(List<ChildProfile> children) {
    if (children.isEmpty) {
      return _buildEmptyCard("No children profiles linked", Icons.child_care_rounded);
    }
    return Column(
      children: children.map((child) {
        final age = _calculateAge(child.dateOfBirth);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumCard(
            padding: EdgeInsets.zero,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlayerStatsScreen(playerId: child.id)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PremiumTheme.neonGreen.withValues(alpha: 0.2),
                      PremiumTheme.neonGreen.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.child_care_rounded, color: PremiumTheme.neonGreen, size: 22),
              ),
              title: Text(
                child.fullName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.sports_soccer_rounded, size: 11, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 4),
                    Text(
                      (child.position ?? "PLAYER").toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.cake_rounded, size: 11, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 4),
                    Text(
                      "$age YRS",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_rounded, color: PremiumTheme.neonGreen, size: 18),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingMatches(List<MatchModel> matches) {
    if (matches.isEmpty) {
      return _buildEmptyCard("No upcoming matches scheduled", Icons.event_busy_rounded);
    }
    return Column(
      children: matches.map((match) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: const EdgeInsets.all(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: match.id)),
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
                    Text(
                      "MATCH",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.id.substring(0, 8).toUpperCase(),
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
                    match.scheduledAt.substring(0, 10),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "KICK-OFF",
                    style: TextStyle(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.7),
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
      )).toList(),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.1), size: 32),
            const SizedBox(height: 12),
            Text(
              message.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}