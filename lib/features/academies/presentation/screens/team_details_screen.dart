import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
                    ? Center(child: Text('academy.no_players_yet'.tr()))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.teamPlayers.length,
                        itemBuilder: (context, index) {
                          final player = provider.teamPlayers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text('academy.player_name'.tr(namedArgs: {'name': player.fullName ?? 'common.unknown'.tr()})),
                              subtitle: Text(
                                player.position != null
                                    ? '${player.position} | #${player.jerseyNumber ?? '?'}'
                                    : 'academy.no_position'.tr(),
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
                Text('academy.age_group_header'.tr(namedArgs: {'age': widget.team.ageGroup})),
                Text('academy.coach_id_header'.tr(namedArgs: {'id': widget.team.coachId.isNotEmpty ? widget.team.coachId.substring(0, 8) : "N/A"})),
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
        title: Text('academy.add_player_to_team'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: profileIdController,
              decoration: InputDecoration(labelText: 'academy.player_profile_id'.tr()),
            ),
            TextField(
              controller: positionController,
              decoration: InputDecoration(labelText: 'academy.position_hint'.tr()),
            ),
            TextField(
              controller: jerseyController,
              decoration: InputDecoration(labelText: 'academy.jersey_number'.tr()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr())),
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
            child: Text('common.add'.tr()),
          ),
        ],
      ),
    );
  }
}
