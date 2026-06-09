import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/orleon_widgets.dart';
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const OrleonSectionHeader(title: 'Overview'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      value: '$upcomingCount',
                      label: 'Upcoming',
                      icon: Icons.event_rounded,
                      accent: PremiumTheme.electricBlue,
                    ),
                  ),
                ],
              ),
            ),
            const OrleonSectionHeader(title: 'Upcoming Matches'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMatchList(context, upcoming, PremiumTheme.neonGreen),
            ),
            const OrleonSectionHeader(title: 'Recently Officiated'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMatchList(context, recent, PremiumTheme.electricBlue),
            ),
            const OrleonSectionHeader(title: 'Availability'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: _buildAvailabilityCard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchList(BuildContext context, List matches, Color accent) {
    final cs = Theme.of(context).colorScheme;

    if (matches.isEmpty) {
      return OrleonCard(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.sports_soccer_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.3), size: 28),
              const SizedBox(height: 8),
              Text(
                'NO MATCHES',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
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
        final status = (match['status']?.toString() ?? '').toUpperCase();
        final statusColor = status == 'SCHEDULED'
            ? PremiumTheme.neonGreen
            : status == 'FINISHED'
                ? cs.onSurfaceVariant
                : Colors.orangeAccent;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OrleonCard(
            padding: const EdgeInsets.all(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.10), accent.withValues(alpha: 0.03)],
            ),
            borderColor: accent.withValues(alpha: 0.22),
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
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8),
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

  Widget _buildAvailabilityCard() {
    final cs = Theme.of(context).colorScheme;
    return OrleonCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          PremiumTheme.neonGreen.withValues(alpha: 0.08),
          PremiumTheme.neonGreen.withValues(alpha: 0.02),
        ],
      ),
      borderColor: PremiumTheme.neonGreen.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [PremiumTheme.neonGreen.withValues(alpha: 0.25), PremiumTheme.neonGreen.withValues(alpha: 0.08)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: PremiumTheme.neonGreen, size: 16),
              ),
              const SizedBox(width: 12),
              const Text(
                'MANAGE SCHEDULE',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: PremiumTheme.neonGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('ACTIVE', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Mark yourself as unavailable for specific dates to stop receiving tournament invites.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 18),
          _buildBlockedDatesList(cs),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _pickAndBlockDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Center(
                child: Text(
                  'BLOCK NEW DATE',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedDatesList(ColorScheme cs) {
    final dates = ['2026-05-15', '2026-05-16'];
    if (dates.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dates.map((date) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(date, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Icon(Icons.close_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      )).toList(),
    );
  }

  Future<void> _pickAndBlockDate() async {
    await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: PremiumTheme.neonGreen,
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
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
              'SYNCING DATA...',
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
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: OrleonCard(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 16),
              Text('SYSTEM ERROR', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(error, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('RETRY CONNECTION'),
                style: TextButton.styleFrom(foregroundColor: PremiumTheme.neonGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
