import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../../../core/api/stats_api_service.dart';
import '../../data/models/match_event.dart';
import '../../data/models/match_award.dart';

class MatchEventsScreen extends StatefulWidget {
  final String matchId;

  const MatchEventsScreen({super.key, required this.matchId});

  @override
  State<MatchEventsScreen> createState() => _MatchEventsScreenState();
}

class _MatchEventsScreenState extends State<MatchEventsScreen> {
  final StatsApiService _apiService = StatsApiService();
  late Future<List<MatchEvent>> _eventsFuture;
  late Future<List<MatchAward>> _awardsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _apiService.getMatchEvents(widget.matchId);
    _awardsFuture = _apiService.getMatchAwards(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'MATCH REPORT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildAwardsSection(),
            const SizedBox(height: 24),
            _buildSectionHeader("MATCH TIMELINE", Icons.timeline_rounded),
            const SizedBox(height: 16),
            _buildTimelineSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: PremiumTheme.neonGreen.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Container(
          width: 40, height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PremiumTheme.neonGreen.withValues(alpha: 0.3), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAwardsSection() {
    return FutureBuilder<List<MatchAward>>(
      future: _awardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2)),
          );
        }
        final awards = snapshot.data ?? [];
        if (awards.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("MATCH AWARDS", Icons.emoji_events_rounded),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: awards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _AwardCard(award: awards[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineSection() {
    return FutureBuilder<List<MatchEvent>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
            ),
          );
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.sports_soccer_rounded, color: Colors.white.withValues(alpha: 0.1), size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'NO EVENTS RECORDED',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: List.generate(events.length, (index) => _EventTile(
            event: events[index],
            isLast: index == events.length - 1,
          )),
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final MatchEvent event;
  final bool isLast;

  const _EventTile({required this.event, this.isLast = false});

  (IconData, Color, String) get _style {
    return switch (event.eventType) {
      EventType.GOAL         => (Icons.sports_soccer_rounded, PremiumTheme.neonGreen, 'GOAL'),
      EventType.PENALTY_GOAL => (Icons.sports_soccer_rounded, Colors.orangeAccent, 'PENALTY'),
      EventType.ASSIST       => (Icons.transfer_within_a_station_rounded, PremiumTheme.electricBlue, 'ASSIST'),
      EventType.YELLOW_CARD  => (Icons.square_rounded, Colors.amber, 'YELLOW CARD'),
      EventType.RED_CARD     => (Icons.square_rounded, Colors.redAccent, 'RED CARD'),
      EventType.SAVE         => (Icons.front_hand_rounded, Colors.purpleAccent, 'SAVE'),
      _                      => (Icons.circle_outlined, Colors.white38, event.eventType.name),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _style;
    final playerId = event.playerId ?? event.childProfileId;
    final shortId = playerId != null && playerId.length >= 8
        ? playerId.substring(0, 8).toUpperCase()
        : playerId?.toUpperCase() ?? '—';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: PremiumTheme.glassDecorationOf(context, radius: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shortId,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${event.minute}'",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardCard extends StatelessWidget {
  final MatchAward award;

  const _AwardCard({required this.award});

  (IconData, String, Color) get _style {
    return switch (award.awardType) {
      MatchAwardType.MVP            => (Icons.military_tech_rounded, 'MVP', Colors.amber),
      MatchAwardType.BEST_GOALKEEPER => (Icons.front_hand_rounded, 'BEST GK', PremiumTheme.electricBlue),
      MatchAwardType.BEST_DEFENDER  => (Icons.shield_rounded, 'BEST DF', PremiumTheme.neonGreen),
      MatchAwardType.BEST_STRIKER   => (Icons.sports_soccer_rounded, 'BEST FW', Colors.orangeAccent),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _style;
    final playerId = award.playerId ?? award.childProfileId ?? '—';
    final shortId = playerId.length >= 8 ? playerId.substring(0, 8).toUpperCase() : playerId.toUpperCase();

    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            shortId,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
