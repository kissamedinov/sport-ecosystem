import 'package:flutter/material.dart';
import '../../../../core/api/stats_api_service.dart';
import '../../data/models/match_event.dart';
import '../../data/models/match_award.dart';
import '../widgets/event_timeline_tile.dart';
import '../widgets/award_card.dart';

class MatchEventsScreen extends StatefulWidget {
  final String matchId;

  const MatchEventsScreen({super.key, required this.matchId});

  @override
  _MatchEventsScreenState createState() => _MatchEventsScreenState();
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
      appBar: AppBar(
        title: const Text("Match Statistics"),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAwardsSection(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                "Match Timeline",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildTimelineSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAwardsSection() {
    return FutureBuilder<List<MatchAward>>(
      future: _awardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final awards = snapshot.data ?? [];
        if (awards.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                "Match Awards",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: awards.length,
                itemBuilder: (context, index) => AwardCard(award: awards[index]),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("No events recorded for this match."),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return EventTimelineTile(
                event: events[index],
                isLast: index == events.length - 1,
              );
            },
          ),
        );
      },
    );
  }
}
