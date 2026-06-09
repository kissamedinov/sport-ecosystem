import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/orleon_widgets.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/matches/presentation/screens/match_events_screen.dart';

class RefereeDashboard extends StatefulWidget {
  const RefereeDashboard({super.key});

  @override
  State<RefereeDashboard> createState() => _RefereeDashboardState();
}

class _RefereeDashboardState extends State<RefereeDashboard> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = ProfileApiService().getRefereeDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: SafeArea(
        child: RefreshIndicator(
          color: PremiumTheme.neonGreen,
          onRefresh: () async {
            setState(() {
              _dashboardFuture = ProfileApiService().getRefereeDashboard();
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, user?.name ?? 'Referee', cs),
                FutureBuilder<Map<String, dynamic>>(
                  future: _dashboardFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(60),
                        child: Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2)),
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildError(cs);
                    }
                    final data = snapshot.data ?? {};
                    final officiated = data['matches_officiated'] ?? 0;
                    final upcomingCount = data['upcoming_count'] ?? 0;
                    final upcoming = data['upcoming_matches'] as List? ?? [];
                    final recent = data['recent_officiated'] as List? ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsStrip(officiated, upcomingCount),
                        const OrleonSectionHeader(title: 'Upcoming Matches'),
                        _buildMatchSection(context, upcoming, PremiumTheme.neonGreen),
                        const OrleonSectionHeader(title: 'Recently Officiated'),
                        _buildMatchSection(context, recent, PremiumTheme.electricBlue),
                        const SizedBox(height: 120),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, String name, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name!',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'REFEREE',
                  style: TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PremiumTheme.neonGreen.withValues(alpha: 0.25), PremiumTheme.neonGreen.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.gavel_rounded, color: PremiumTheme.neonGreen, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(int officiated, int upcoming) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OrleonStatCard(
              value: '$officiated',
              label: 'Officiated',
              icon: Icons.gavel_rounded,
              accent: PremiumTheme.neonGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OrleonStatCard(
              value: '$upcoming',
              label: 'Upcoming',
              icon: Icons.event_rounded,
              accent: PremiumTheme.electricBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSection(BuildContext context, List matches, Color accent) {
    final cs = Theme.of(context).colorScheme;
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OrleonCard(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.sports_soccer_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.3), size: 28),
                const SizedBox(height: 8),
                Text('NO MATCHES', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: matches.map((match) {
        final id = match['id']?.toString() ?? '';
        final scheduledAt = match['scheduled_at']?.toString() ?? '';
        final date = scheduledAt.length >= 10 ? scheduledAt.substring(0, 10) : 'TBD';
        final status = (match['status']?.toString() ?? '').toUpperCase();
        final statusColor = status == 'SCHEDULED'
            ? PremiumTheme.neonGreen
            : status == 'FINISHED'
                ? cs.onSurfaceVariant
                : Colors.orangeAccent;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: OrleonCard(
            padding: const EdgeInsets.all(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.10), accent.withValues(alpha: 0.03)],
            ),
            borderColor: accent.withValues(alpha: 0.20),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: id))),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.08)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sports_soccer_rounded, color: accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MATCH', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        id.length >= 8 ? '#${id.substring(0, 8).toUpperCase()}' : '#$id',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(date, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
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

  Widget _buildError(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: OrleonCard(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text('Failed to load data', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() { _dashboardFuture = ProfileApiService().getRefereeDashboard(); }),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('RETRY'),
              style: TextButton.styleFrom(foregroundColor: PremiumTheme.neonGreen),
            ),
          ],
        ),
      ),
    );
  }
}
