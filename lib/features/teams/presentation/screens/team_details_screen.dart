import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';
import '../../data/models/team.dart';
import '../widgets/team_form_indicator.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  Team? _team;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final team = await context.read<TeamProvider>().fetchTeamById(widget.teamId);
    if (mounted) {
      setState(() {
        _team = team;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_team == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Team not found')),
      );
    }

    final team = _team!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(team.name),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue[900]!, Colors.blue[400]!],
                  ),
                ),
                child: const Icon(Icons.groups, size: 100, color: Colors.white24),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('PERFORMANCE'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CURRENT FORM', style: TextStyle(fontWeight: FontWeight.bold)),
                              TeamFormIndicator(form: team.form, size: 28),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('RATING', team.rating.toString(), Colors.orange),
                              _buildStatItem('WINS', team.wins.toString(), Colors.green),
                              _buildStatItem('LOSSES', team.losses.toString(), Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('RECENT MATCHES'),
                  const SizedBox(height: 12),
                  if (team.recentMatches.isEmpty)
                    const Center(child: Text('No recent matches recorded'))
                  else
                    ...team.recentMatches.map((match) => _buildMatchTile(match, team.id)),
                  const SizedBox(height: 24),
                  _buildSectionTitle('INFO'),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('City'),
                    subtitle: Text(team.city),
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Age Category'),
                    subtitle: Text(team.ageCategory ?? 'Open'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMatchTile(dynamic match, String teamId) {
    // Note: match is MatchModel but I'll use dynamic to avoid casting issues in this quick block
    final isHome = match.homeTeamId == teamId;
    final teamScore = isHome ? match.homeScore : match.awayScore;
    final opponentScore = isHome ? match.awayScore : match.homeScore;
    final result = teamScore > opponentScore ? 'W' : (teamScore < opponentScore ? 'L' : 'D');
    final resultColor = result == 'W' ? Colors.green : (result == 'L' ? Colors.red : Colors.grey);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: resultColor, shape: BoxShape.circle),
          child: Center(
            child: Text(
              result,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(
          isHome ? 'vs Away Team' : 'at Home Team', // Ideally fetch opponent name too
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(match.scheduledAt.split('T')[0]),
        trailing: Text(
          '$teamScore - $opponentScore',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
