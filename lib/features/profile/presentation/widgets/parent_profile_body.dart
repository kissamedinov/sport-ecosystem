import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/clubs/data/models/child_profile.dart';
import 'package:mobile/features/matches/data/models/match.dart';
import 'package:mobile/features/player_stats/presentation/screens/player_stats_screen.dart';
import 'package:mobile/features/matches/presentation/screens/match_events_screen.dart';

class ParentProfileBody extends StatefulWidget {
  const ParentProfileBody({super.key});

  @override
  State<ParentProfileBody> createState() => _ParentProfileBodyState();
}

class _ParentProfileBodyState extends State<ParentProfileBody> {
  final ProfileApiService _profileApi = ProfileApiService();
  late Future<List<ChildProfile>> _childrenFuture;
  late Future<List<MatchModel>> _matchesFuture;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _childrenFuture = _profileApi.getChildProfiles().catchError((_) => <ChildProfile>[]);
    _matchesFuture = _profileApi.getChildrenUpcomingMatches().catchError((_) => <MatchModel>[]);
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  Future<void> _handleLinkChild() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PLEASE ENTER A VALID EMAIL"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      final result = await _profileApi.linkChildByEmail(email);
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "LINK REQUEST SENT"),
            backgroundColor: PremiumTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ERROR: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showLinkChildSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text(
              "LINK TO CHILD ACCOUNT",
              style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter your child's registered email to send a link request.",
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            PremiumTextField(
              controller: _emailController,
              label: "CHILD'S EMAIL",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            PremiumButton(
              text: "SEND LINK REQUEST",
              onPressed: _handleLinkChild,
            ),
          ],
        ),
      ),
    );
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
                  _buildStatsRow(children.length, matches.length),
                  const SizedBox(height: 24),
                  
                  _buildSectionLabel("MY CHILDREN"),
                  const SizedBox(height: 12),
                  _buildChildrenList(children),
                  const SizedBox(height: 12),
                  _buildLinkChildAction(),
                  const SizedBox(height: 32),

                  if (matches.isNotEmpty) ...[
                    _buildSectionLabel("NEXT HIGHLIGHTS"),
                    const SizedBox(height: 12),
                    _buildMatchHighlight(matches.first),
                    const SizedBox(height: 12),
                  ],

                  _buildSectionLabel("UPCOMING SCHEDULE"),
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

  Widget _buildLinkChildAction() {
    return GestureDetector(
      onTap: _showLinkChildSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: PremiumTheme.neonGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: PremiumTheme.neonGreen, size: 20),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LINK NEW CHILD",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                  Text(
                    "Connect via registered email",
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHighlight(MatchModel match) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: match.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "NEXT MATCH",
                  style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
              const Spacer(),
              Text(
                match.scheduledAt.substring(0, 10),
                style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Text("HOME", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                child: const Text("VS", style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              Expanded(child: Text("AWAY", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Venue: Central Field • 18:30",
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(100),
        child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.5,
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
            title: "GAMES",
            value: "$matchCount",
            icon: Icons.sports_soccer_rounded,
            color: PremiumTheme.electricBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenList(List<ChildProfile> children) {
    if (children.isEmpty) {
      return Container();
    }
    return Column(
      children: children.map((child) {
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: PremiumTheme.neonGreen, size: 20),
              ),
              title: Text(
                child.fullName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              subtitle: Text(
                child.position?.toUpperCase() ?? "PLAYER",
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingMatches(List<MatchModel> matches) {
    if (matches.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.event_busy_rounded, color: Colors.white10, size: 32),
              const SizedBox(height: 12),
              const Text("NO UPCOMING SCHEDULE", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: matches.skip(1).map((match) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: const EdgeInsets.all(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: match.id)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white24, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Match vs Academy B",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Text(
                match.scheduledAt.substring(0, 10),
                style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}