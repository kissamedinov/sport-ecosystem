import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
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
    _childrenFuture = _profileApi.getChildProfiles();
    _matchesFuture = _profileApi.getChildrenUpcomingMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("MY CHILDREN"),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyChildrenScreen())),
              child: const Text("MANAGE", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        _buildChildrenList(),
        const SizedBox(height: 24),
        _buildSectionTitle("UPCOMING MATCHES"),
        _buildUpcomingMatches(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildChildrenList() {
    return FutureBuilder<List<ChildProfile>>(
      future: _childrenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No children profiles found.", style: TextStyle(color: Colors.grey)),
          );
        }

        final children = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          itemBuilder: (context, index) {
            final child = children[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerStatsScreen(playerId: child.id)),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withOpacity(0.1),
                    child: const Icon(Icons.child_care, color: Colors.indigo),
                  ),
                  title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.position ?? "Player"),
                      Text('ID: ${child.id}', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                    ],
                  ),
                  trailing: const Icon(Icons.analytics, color: Colors.indigoAccent, size: 20),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUpcomingMatches() {
    return FutureBuilder<List<MatchModel>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No upcoming matches for your children.", style: TextStyle(color: Colors.grey)),
          );
        }

        final matches = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: match.id)),
                  ),
                  title: Text("Match ID: ${match.id.substring(0, 8)}"),
                  subtitle: Text(match.scheduledAt.substring(0, 16)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("UPCOMING", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
