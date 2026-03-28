import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/academy_provider.dart';
import '../../data/models/academy_team.dart' as team_models;
import '../../data/models/academy.dart' as academy_models;

class AcademyTeamDetailsScreen extends StatefulWidget {
  final team_models.AcademyTeam team;

  const AcademyTeamDetailsScreen({super.key, required this.team});

  @override
  State<AcademyTeamDetailsScreen> createState() => _AcademyTeamDetailsScreenState();
}

class _AcademyTeamDetailsScreenState extends State<AcademyTeamDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildTeamHeader(),
            const TabBar(
              tabs: [
                Tab(text: 'Players'),
                Tab(text: 'Training'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlayersList(),
                  _buildTrainingSessions(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withOpacity(0.05),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: Text(widget.team.ageGroup, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Age Group: ${widget.team.ageGroup}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        final teamPlayers = provider.players.where((p) => true).toList(); // Simplified filter

        if (teamPlayers.isEmpty) {
          return const Center(child: Text('No players assigned to this team.'));
        }

        return ListView.builder(
          itemCount: teamPlayers.length,
          itemBuilder: (context, index) {
            final player = teamPlayers[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Player ID: ${player.playerProfileId?.substring(0, 8) ?? "N/A"}'),
              subtitle: Text('Status: ${player.status}'),
              trailing: IconButton(
                icon: const Icon(Icons.feedback_outlined),
                onPressed: () => _showFeedbackDialog(player),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrainingSessions() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        final sessions = provider.sessions.where((s) => s.teamId == widget.team.id).toList();

        if (sessions.isEmpty) {
          return const Center(child: Text('No training sessions scheduled.'));
        }

        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return ListTile(
              leading: const Icon(Icons.event),
              title: Text(session.topic ?? 'Training Session'),
              subtitle: Text(session.scheduledAt),
              trailing: ElevatedButton(
                onPressed: () => _showAttendanceDialog(session),
                child: const Text('Attendance'),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDialog() {
    // TODO: Implement Add Player/Session Dialog
  }

  void _showAttendanceDialog(academy_models.TrainingSession session) {
    // TODO: Implement Attendance Recording
  }

  void _showFeedbackDialog(academy_models.AcademyPlayer player) {
    // TODO: Implement Feedback Submission
  }
}
