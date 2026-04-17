import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/academy_provider.dart';
import '../../data/models/academy_team.dart';
import '../../data/models/academy.dart' as academy_models;

class AcademyTeamDetailsScreen extends StatefulWidget {
  final AcademyTeam team;

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

        return ListView.builder(
          itemCount: teamPlayers.length,
          itemBuilder: (context, index) {
            final player = teamPlayers[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Player Profile ID: ${(player.playerProfileId ?? "Unknown").substring(0, 8)}'),
              subtitle: Text('Status: ${player.status}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                    onPressed: () => _showReassignSheet(player),
                    tooltip: 'Move to Team',
                  ),
                  IconButton(
                    icon: const Icon(Icons.feedback_outlined),
                    onPressed: () => _showFeedbackDialog(player),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReassignSheet(AcademyPlayer player) {
    final provider = context.read<AcademyProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Move Player to Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Select target team:'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: provider.teams.length,
                itemBuilder: (context, index) {
                  final team = provider.teams[index];
                  if (team.id == widget.team.id) return const SizedBox.shrink();

                  return ListTile(
                    leading: CircleAvatar(child: Text(team.ageGroup)),
                    title: Text(team.name),
                    onTap: () async {
                      final success = await provider.reassignPlayer(player.playerProfileId, team.id);
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Player moved to ${team.name}')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingSessions() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        final teamSessions = provider.sessions.where((s) => s.teamIds.contains(widget.team.id)).toList();
        final teamSchedules = provider.schedules.where((s) => s.teamIds.contains(widget.team.id)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (teamSchedules.isNotEmpty) ...[
              const Text('Recurring Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...teamSchedules.map((s) => Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text('${s.dayOfWeek.toShortString()} | ${s.startTime} - ${s.endTime}'),
                  subtitle: Text(s.location ?? 'Main Field'),
                ),
              )),
              const Divider(height: 32),
            ],
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent & Upcoming Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (teamSessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No actual sessions generated yet.\nUse "Generate Sessions" in Dashboard.', 
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...teamSessions.map((session) => Card(
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.green),
                  title: Text(session.description ?? 'Training Session'),
                  subtitle: Text('${session.date} | ${session.startTime} - ${session.endTime}'),
                  trailing: ElevatedButton(
                    onPressed: () => _showAttendanceDialog(session),
                    child: const Text('Attendance'),
                  ),
                ),
              )).toList(),
          ],
        );
      },
    );
  }

  void _showAddDialog() {
    // TODO: Implement Add Player/Session Dialog
  }

  void _showAttendanceDialog(TrainingSession session) {
    // TODO: Implement Attendance Recording
  }

  void _showFeedbackDialog(AcademyPlayer player) {
    // TODO: Implement Feedback Submission
  }
}
