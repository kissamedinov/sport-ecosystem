import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/academies/providers/academy_provider.dart';
import 'package:mobile/features/academies/data/models/academy_team.dart';

class TeamDetailsScreen extends StatefulWidget {
  final AcademyTeam team;

  const TeamDetailsScreen({super.key, required this.team});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AcademyProvider>().fetchTeamPlayers(widget.team.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
      ),
      body: Consumer<AcademyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          
          return Column(
            children: [
              _buildTeamHeader(),
              const Divider(),
              Expanded(
                child: provider.teamPlayers.isEmpty
                    ? const Center(child: Text('No players assigned to this team'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.teamPlayers.length,
                        itemBuilder: (context, index) {
                          final player = provider.teamPlayers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text('Player: ${player.fullName ?? "No Name"}'),
                              subtitle: Text(
                                player.position != null
                                    ? '${player.position} | #${player.jerseyNumber ?? '?'}'
                                    : 'No position assigned',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () {
                                  // Show player details
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlayerDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white10,
            child: Icon(Icons.group, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('Age Group: ${widget.team.ageGroup}'),
                Text('Coach ID: ${widget.team.coachId.isNotEmpty ? widget.team.coachId.substring(0, 8) : "N/A"}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog() {
    final profileIdController = TextEditingController();
    final positionController = TextEditingController();
    final jerseyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player to Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: profileIdController,
              decoration: const InputDecoration(labelText: 'Player Profile ID'),
            ),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(labelText: 'Position (e.g. ST, GK)'),
            ),
            TextField(
              controller: jerseyController,
              decoration: const InputDecoration(labelText: 'Jersey Number'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<AcademyProvider>().addPlayerToTeam(
                widget.team.id,
                profileIdController.text, // Profile ID
                positionController.text.isNotEmpty ? positionController.text : "N/A", // Position (playerName param in provider)
                jerseyController.text.isNotEmpty ? jerseyController.text : "0", // Jersey Number (position param in provider)
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
