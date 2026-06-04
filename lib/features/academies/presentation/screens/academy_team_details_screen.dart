import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
            TabBar(
              tabs: [
                Tab(text: 'academy.players'.tr()),
                Tab(text: 'academy.training'.tr()),
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
              Text('academy.age_group_header'.tr(namedArgs: {'age': widget.team.ageGroup}), style: const TextStyle(color: Colors.grey)),
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
            Text('academy.move_player_to_team'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('academy.select_target_team'.tr()),
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
              Text('academy.recurring_schedule'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...teamSchedules.map((s) => Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text('${s.dayOfWeek.toShortString()} | ${s.startTime} - ${s.endTime}'),
                  subtitle: Text(s.location ?? 'academy.main_field'.tr()),
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('academy.no_sessions_generated'.tr(),
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
                    child: Text('academy.attendance_section'.tr()),
                  ),
                ),
              )),
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
