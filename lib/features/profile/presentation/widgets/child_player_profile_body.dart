import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/player_stats/providers/player_stats_provider.dart';
import 'package:mobile/features/teams/providers/team_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';

class ChildPlayerProfileBody extends StatefulWidget {
  final User user;

  const ChildPlayerProfileBody({super.key, required this.user});

  @override
  State<ChildPlayerProfileBody> createState() => _ChildPlayerProfileBodyState();
}

class _ChildPlayerProfileBodyState extends State<ChildPlayerProfileBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchMyParents();
      context.read<TeamProvider>().fetchMyTeams();
    });
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.user.dateOfBirth ?? DateTime(2010),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: PremiumTheme.electricBlue,
              onPrimary: Colors.white,
              surface: PremiumTheme.surfaceCard(context),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final isSelf = authProvider.user?.id == widget.user.id;
      final success = isSelf
          ? await authProvider.updateProfile({
              'date_of_birth': picked.toIso8601String().split('T')[0],
            })
          : await authProvider.updateUserProfile(widget.user.id, {
              'date_of_birth': picked.toIso8601String().split('T')[0],
            });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Birthday updated!' : 'Failed: ${authProvider.error}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: success ? PremiumTheme.surfaceCard(context) : Colors.redAccent.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionLabel("CAREER STATS"),
          const SizedBox(height: 12),
          _buildCareerStats(context),
          const SizedBox(height: 28),
          _buildSectionLabel("MY TEAM"),
          const SizedBox(height: 12),
          _buildMyTeamsSection(context),
          const SizedBox(height: 28),
          _buildSectionLabel("MY FAMILY"),
          const SizedBox(height: 12),
          _buildMyFamilySection(context),
          const SizedBox(height: 40),
        ],
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

  Widget _buildCareerStats(BuildContext context) {
    final stats = context.watch<PlayerStatsProvider>().getCareerStats(widget.user.id);
    final user = widget.user.id == context.watch<AuthProvider>().user?.id
        ? context.watch<AuthProvider>().user!
        : widget.user;
    final age = _calculateAge(user.dateOfBirth);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectBirthday(context),
                child: PremiumStatCard(
                  title: "AGE",
                  value: age > 0 ? "$age yrs" : "SET",
                  icon: Icons.cake_rounded,
                  color: Colors.pinkAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumStatCard(
                title: "MATCHES",
                value: "${stats.matchesPlayed}",
                icon: Icons.sports_soccer_rounded,
                color: PremiumTheme.electricBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumStatCard(
                title: "GOALS",
                value: "${stats.totalGoals}",
                icon: Icons.sports_rounded,
                color: PremiumTheme.neonGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PremiumStatCard(
                title: "ASSISTS",
                value: "${stats.totalAssists}",
                icon: Icons.handshake_rounded,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumStatCard(
                title: "MVP",
                value: "${stats.totalMvpAwards}",
                icon: Icons.emoji_events_rounded,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumStatCard(
                title: "CARDS",
                value: "${stats.totalYellowCards + stats.totalRedCards}",
                icon: Icons.style_rounded,
                color: Colors.yellowAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyTeamsSection(BuildContext context) {
    final teams = context.watch<TeamProvider>().myTeams;

    if (teams.isEmpty) {
      return _buildEmptyCard("Not assigned to a team yet", Icons.group_off_rounded);
    }

    return Column(
      children: teams.map((team) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PremiumTheme.electricBlue.withValues(alpha: 0.2),
                    PremiumTheme.electricBlue.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.shield_rounded, color: PremiumTheme.electricBlue, size: 24),
            ),
            title: Text(
              team.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record, size: 8, color: PremiumTheme.neonGreen.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  const Text(
                    "ACTIVE ROSTER",
                    style: TextStyle(
                      color: PremiumTheme.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
              child: const Icon(Icons.chevron_right_rounded, color: PremiumTheme.neonGreen, size: 20),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMyFamilySection(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final parents = authProvider.myParents;

    if (authProvider.isLoading && parents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
        ),
      );
    }

    if (parents.isEmpty) {
      return _buildEmptyCard("No parents linked yet", Icons.person_off_rounded);
    }

    return Column(
      children: parents.map((parent) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  (parent['name'] as String?)?.isNotEmpty == true
                      ? (parent['name'] as String)[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            title: Text(
              parent['name'] ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "PARENT / GUARDIAN",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white12, size: 20),
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
}