import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/academies/providers/academy_provider.dart';
import 'package:mobile/features/academies/data/models/academy.dart';
import 'package:mobile/features/academies/presentation/screens/team_details_screen.dart';

class AcademyDetailsScreen extends StatefulWidget {
  final Academy academy;

  const AcademyDetailsScreen({super.key, required this.academy});

  @override
  State<AcademyDetailsScreen> createState() => _AcademyDetailsScreenState();
}

class _AcademyDetailsScreenState extends State<AcademyDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      context.read<AcademyProvider>().fetchAcademyTeams(widget.academy.id);
      context.read<AcademyProvider>().fetchAcademyPlayers(widget.academy.id);
      context.read<AcademyProvider>().fetchSessions(widget.academy.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.academy.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'academy.teams'.tr(), icon: const Icon(Icons.group)),
            Tab(text: 'academy.players'.tr(), icon: const Icon(Icons.person)),
            Tab(text: 'academy.sessions'.tr(), icon: const Icon(Icons.event)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamsTab(),
          _buildPlayersTab(),
          _buildSessionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleFabPress(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleFabPress() {
    if (_tabController.index == 0) {
      _showCreateTeamDialog();
    } else if (_tabController.index == 1) {
      // Add player to academy
    } else {
      // Create training session
    }
  }

  Widget _buildTeamsTab() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.teams.isEmpty) return Center(child: Text('academy.no_teams_added'.tr()));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.teams.length,
          itemBuilder: (context, index) {
            final team = provider.teams[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(team.name),
                subtitle: Text('academy.age_group_label'.tr(namedArgs: {'age': team.ageGroup})),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamDetailsScreen(team: team),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.players.isEmpty) return Center(child: Text('academy.no_players_yet'.tr()));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.players.length,
          itemBuilder: (context, index) {
            final player = provider.players[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Player ID: ${player.playerProfileId.substring(0, 8) ?? "N/A"}'),
              subtitle: Text('Status: ${player.status}'),
            );
          },
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.sessions.isEmpty) return Center(child: Text('academy.no_sessions_scheduled'.tr()));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.sessions.length,
          itemBuilder: (context, index) {
            final session = provider.sessions[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(session.topic ?? 'academy.training_session'.tr()),
                subtitle: Text(session.scheduledAt),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    final ageGroupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('academy.new_team'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Team Name')),
            TextField(controller: ageGroupController, decoration: const InputDecoration(labelText: 'Age Group')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr())),
          ElevatedButton(
            onPressed: () async {
              await context.read<AcademyProvider>().createTeam(
                widget.academy.id,
                nameController.text,
                ageGroupController.text,
                'Intermediate', // only 4 parameters expected by AcademyProvider.createTeam
              );
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
