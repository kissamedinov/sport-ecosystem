import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/quiz/presentation/screens/daily_quiz_screen.dart';
import 'package:mobile/features/player_stats/providers/player_stats_provider.dart';
import 'package:mobile/features/teams/providers/team_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/core/presentation/widgets/orleon_widgets.dart';

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
    return age < 0 ? 0 : age;
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.user.dateOfBirth ?? DateTime(2010),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: PremiumTheme.electricBlue,
              onPrimary: Colors.white,
              surface: PremiumTheme.surfaceCard(context),
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
          _buildSectionLabel("DAILY CHALLENGE"),
          const SizedBox(height: 12),
          _buildDailyChallenge(context),
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

  Widget _buildCareerStats(BuildContext context) {
    final stats = context.watch<PlayerStatsProvider>().getCareerStats(widget.user.id);
    final teams = context.watch<TeamProvider>().myTeams;
    final user = widget.user.id == context.watch<AuthProvider>().user?.id
        ? context.watch<AuthProvider>().user!
        : widget.user;
    final isDefaultDob = user.dateOfBirth?.year == 2000 &&
        user.dateOfBirth?.month == 1 &&
        user.dateOfBirth?.day == 1;
    final age = _calculateAge(user.dateOfBirth);
    final showSet = user.dateOfBirth == null || isDefaultDob;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.cake_rounded,
          value: showSet ? 'SET' : '$age',
          label: showSet ? 'AGE • TAP' : 'AGE',
          accent: const Color(0xFFCE93D8),
          onTap: () => _selectBirthday(context),
        ),
        _buildStatCard(
          icon: Icons.shield_rounded,
          value: '${teams.length}',
          label: 'TEAMS',
          accent: PremiumTheme.electricBlue,
        ),
        _buildStatCard(
          icon: Icons.sports_soccer_rounded,
          value: '${stats.totalGoals}',
          label: 'GOALS',
          accent: PremiumTheme.neonGreen,
        ),
        _buildStatCard(
          icon: Icons.stadium_rounded,
          value: '${stats.matchesPlayed}',
          label: 'MATCHES',
          accent: Colors.amber,
        ),
        _buildStatCard(
          icon: Icons.handshake_rounded,
          value: '${stats.totalAssists}',
          label: 'ASSISTS',
          accent: PremiumTheme.neonGreen,
        ),
        _buildStatCard(
          icon: Icons.emoji_events_rounded,
          value: '${stats.totalMvpAwards}',
          label: 'MVP AWARDS',
          accent: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
    VoidCallback? onTap,
  }) {
    return OrleonCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      radius: 16,
      onTap: onTap,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.22),
          accent.withValues(alpha: 0.10),
        ],
      ),
      borderColor: accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge(BuildContext context) {
    const accent = Color(0xFF00E676);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DailyQuizScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A1F0A) : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1B5E20) : accent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bolt_rounded, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FOOTBALL KICK-OFF",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Win 7 points today to keep your streak!",
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 16),
          ],
        ),
      ),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "PARENT / GUARDIAN",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: muted.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 12),
            Text(
              message.toUpperCase(),
              style: TextStyle(
                color: muted,
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