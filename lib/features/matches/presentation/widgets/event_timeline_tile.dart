import 'package:flutter/material.dart';
import '../../data/models/match_event.dart';

class EventTimelineTile extends StatelessWidget {
  final MatchEvent event;
  final bool isLast;

  const EventTimelineTile({
    super.key,
    required this.event,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeline(context),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildEventIcon(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getEventTitle(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Player ID: ${event.playerId ?? event.childProfileId ?? 'Unknown'}", // In real app, we'd fetch player name
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${event.minute}'",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventIcon() {
    switch (event.eventType) {
      case EventType.GOAL:
      case EventType.PENALTY_GOAL:
        return const Text("⚽", style: TextStyle(fontSize: 24));
      case EventType.YELLOW_CARD:
        return Container(width: 20, height: 28, color: Colors.yellow);
      case EventType.RED_CARD:
        return Container(width: 20, height: 28, color: Colors.red);
      case EventType.SAVE:
        return const Icon(Icons.front_hand, color: Colors.green);
      default:
        return const Icon(Icons.event_note);
    }
  }

  String _getEventTitle() {
    switch (event.eventType) {
      case EventType.GOAL:
        return "Goal";
      case EventType.PENALTY_GOAL:
        return "Penalty Goal";
      case EventType.ASSIST:
        return "Assist";
      case EventType.YELLOW_CARD:
        return "Yellow Card";
      case EventType.RED_CARD:
        return "Red Card";
      case EventType.SAVE:
        return "Save";
      default:
        return event.eventType.name;
    }
  }
}
