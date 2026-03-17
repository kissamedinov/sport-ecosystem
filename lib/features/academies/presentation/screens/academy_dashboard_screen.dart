import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/academy_provider.dart';
import 'academy_team_details_screen.dart';

class AcademyDashboardScreen extends StatefulWidget {
  const AcademyDashboardScreen({super.key});

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademyProvider>().fetchMyAcademy();
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
        title: const Text('Academy Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Teams'),
            Tab(text: 'Players'),
          ],
        ),
      ),
      body: Consumer<AcademyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.myAcademy == null) {
            return _buildNoAcademyView();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(provider),
              _buildTeamsTab(provider),
              _buildPlayersTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildNoAcademyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('You don\'t have an academy registered yet.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to Create Academy Screen
            },
            child: const Text('Register Academy'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AcademyProvider provider) {
    final academy = provider.myAcademy!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('Academy Info', [
          ListTile(
            leading: const Icon(Icons.business),
            title: Text(academy.name),
            subtitle: Text('${academy.city}, ${academy.address}'),
          ),
        ]),
        const SizedBox(height: 16),
        _buildStatGrid(provider),
        const SizedBox(height: 16),
        _buildRecentActivity(provider),
      ],
    );
  }

  Widget _buildStatGrid(AcademyProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildCounterCard('Teams', provider.teams.length.toString(), Icons.group),
        _buildCounterCard('Players', provider.players.length.toString(), Icons.person),
        _buildCounterCard('Sessions', provider.sessions.length.toString(), Icons.event),
        _buildCounterCard('Ranking', '#5', Icons.emoji_events),
      ],
    );
  }

  Widget _buildCounterCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsTab(AcademyProvider provider) {
    if (provider.teams.isEmpty) {
      return const Center(child: Text('No teams added yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: provider.teams.length,
      itemBuilder: (context, index) {
        final team = provider.teams[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(team.ageGroup)),
            title: Text(team.name),
            subtitle: const Text('Next Session: Tomorrow 4:00 PM'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AcademyTeamDetailsScreen(team: team),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlayersTab(AcademyProvider provider) {
    if (provider.players.isEmpty) {
      return const Center(child: Text('No players added yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: provider.players.length,
      itemBuilder: (context, index) {
        final player = provider.players[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Player Profile ID: ${player.playerProfileId.substring(0, 8)}'),
            subtitle: Text('Status: ${player.status}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AcademyProvider provider) {
    return _buildStatCard('Recent Sessions', [
      if (provider.sessions.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No recent training sessions.'),
        )
      else
        ...provider.sessions.take(3).map((s) => ListTile(
          leading: const Icon(Icons.event),
          title: Text(s.date),
          subtitle: Text('${s.startTime} - ${s.endTime}'),
        )),
    ]);
  }

  Widget? _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 1) {
          _showAddTeamDialog();
        } else if (_tabController.index == 2) {
          _showAddPlayerDialog();
        }
      },
      child: const Icon(Icons.add),
    );
  }

  void _showAddTeamDialog() {
    final nameController = TextEditingController();
    String ageGroup = 'U15';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Team Name')),
            DropdownButtonFormField<String>(
              value: ageGroup,
              items: ['U7', 'U9', 'U11', 'U13', 'U15', 'U17'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => ageGroup = v!,
              decoration: const InputDecoration(labelText: 'Age Group'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<AcademyProvider>();
              provider.createTeam(provider.myAcademy!.id, nameController.text, ageGroup, provider.myAcademy!.ownerId);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog() {
    // TODO: Implement Add Player Dialog
  }
}
