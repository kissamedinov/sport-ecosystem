import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/academy_provider.dart';
import '../../data/models/crm_models.dart';
import 'academy_team_details_screen.dart';
import 'training_management_screen.dart';
import 'package:intl/intl.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Teams'),
            Tab(text: 'Schedules'),
            Tab(text: 'Billing'),
          ],
        ),
      ),
      body: Consumer<AcademyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.myAcademy == null) {
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
              _buildSchedulesTab(provider),
              _buildBillingTab(provider),
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
    return RefreshIndicator(
      onRefresh: () => provider.fetchMyAcademy(),
      child: provider.teams.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(child: Text('No teams added yet.')),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.teams.length,
              itemBuilder: (context, index) {
                final team = provider.teams[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          team.ageGroup,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
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
            ),
    );
  }

  Widget _buildSchedulesTab(AcademyProvider provider) {
    if (provider.schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No training schedules configured.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddScheduleDialog(),
              child: const Text('Add Schedule'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: provider.schedules.length,
      itemBuilder: (context, index) {
        final schedule = provider.schedules[index];
        final team = provider.teams.firstWhere((t) => t.id == schedule.teamId, orElse: () => provider.teams[0]);
        
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: Icon(Icons.timer, color: Colors.orange),
            ),
            title: Text('${schedule.dayOfWeek.toShortString()} | ${schedule.startTime} - ${schedule.endTime}'),
            subtitle: Text('Team: ${team.name} • ${schedule.location ?? "Main Field"}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                // TODO: Delete schedule
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillingTab(AcademyProvider provider) {
    if (provider.billingConfig == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Billing is not configured yet.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showBillingConfigDialog(),
              child: const Text('Configure Billing'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Pricing: ${provider.billingConfig!.monthlySubscriptionFee ?? 0} ${provider.billingConfig!.currency} / month',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => _showBillingConfigDialog(),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Player Billing Summaries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.players.length,
            itemBuilder: (context, index) {
              final player = provider.players[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Player ID: ${(player.playerProfileId ?? "Unknown").substring(0, 8)}'),
                  subtitle: const Text('Tap to view monthly report'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showPlayerBillingReport(player.playerProfileId ?? "");
                  },
                ),
              );
            },
          ),
        ),
      ],
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
          title: Text(s.scheduledAt),
          subtitle: Text(s.topic ?? 'Training Session'),
        )),
    ]);
  }

  Widget? _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 1) {
          _showAddTeamDialog();
        } else if (_tabController.index == 2) {
          _showAddScheduleDialog();
        } else if (_tabController.index == 3) {
          _showBillingConfigDialog();
        }
      },
      child: const Icon(Icons.add),
    );
  }

  void _showAddTeamDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Team Name')),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Age Groups / Years',
                hintText: 'e.g., 2013, 2014 or U15',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<AcademyProvider>();
              provider.createTeam(provider.myAcademy!.id, nameController.text, ageController.text, 'Intermediate');
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

  void _showAddScheduleDialog() {
    final provider = context.read<AcademyProvider>();
    if (provider.teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a team first')));
      return;
    }

    String selectedTeamId = provider.teams[0].id;
    DayOfWeek selectedDay = DayOfWeek.MONDAY;
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 30);
    final locationController = TextEditingController(text: 'Main Field');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Recurring Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: selectedTeamId,
                items: provider.teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => selectedTeamId = v!),
                decoration: const InputDecoration(labelText: 'Team'),
              ),
              DropdownButtonFormField<DayOfWeek>(
                value: selectedDay,
                items: DayOfWeek.values.map((d) => DropdownMenuItem(value: d, child: Text(d.toShortString()))).toList(),
                onChanged: (v) => setState(() => selectedDay = v!),
                decoration: const InputDecoration(labelText: 'Day of Week'),
              ),
              ListTile(
                title: const Text('Start Time'),
                trailing: Text(startTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: startTime);
                  if (picked != null) setState(() => startTime = picked);
                },
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: Text(endTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: endTime);
                  if (picked != null) setState(() => endTime = picked);
                },
              ),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await provider.createSchedule(provider.myAcademy!.id, {
                      'team_id': selectedTeamId,
                      'day_of_week': selectedDay.toShortString(),
                      'start_time': '${startTime.hour.toString().padLeft(2, "0")}:${startTime.minute.toString().padLeft(2, "0")}',
                      'end_time': '${endTime.hour.toString().padLeft(2, "0")}:${endTime.minute.toString().padLeft(2, "0")}',
                      'location': locationController.text,
                    });
                    if (success) Navigator.pop(context);
                  },
                  child: const Text('Save Schedule'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showBillingConfigDialog() {
    final provider = context.read<AcademyProvider>();
    final feeController = TextEditingController(text: provider.billingConfig?.monthlySubscriptionFee?.toString() ?? '0');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Billing Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: feeController,
              decoration: const InputDecoration(labelText: 'Monthly Subscription Fee', suffixText: 'KZT'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.saveBillingConfig(provider.myAcademy!.id, {
                'monthly_subscription_fee': double.tryParse(feeController.text) ?? 0,
                'currency': 'KZT',
              });
              if (success) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPlayerBillingReport(String playerId) {
    final provider = context.read<AcademyProvider>();
    final now = DateTime.now();
    provider.fetchBillingReport(provider.myAcademy!.id, playerId, now.month, now.year);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer<AcademyProvider>(
        builder: (context, p, _) => Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: p.isLoading
            ? const Center(child: CircularProgressIndicator())
            : p.currentBillingReport == null
              ? const Center(child: Text('No data found for this month'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billing Report: ${DateFormat('MMMM yyyy').format(now)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Player: ${p.currentBillingReport!.playerName}', style: const TextStyle(fontSize: 16, color: Colors.blue)),
                    const Divider(height: 32),
                    _buildBillingRow('Total Sessions', p.currentBillingReport!.attendance.totalSessions.toString()),
                    _buildBillingRow('Present', p.currentBillingReport!.attendance.present.toString(), color: Colors.green),
                    _buildBillingRow('Absent', p.currentBillingReport!.attendance.absent.toString(), color: Colors.red),
                    _buildBillingRow('Late', p.currentBillingReport!.attendance.late.toString(), color: Colors.orange),
                    const Divider(height: 32),
                    _buildBillingRow('Base Monthly Fee', '${p.currentBillingReport!.baseFee} ${p.currentBillingReport!.currency}'),
                    _buildBillingRow('Additional Fees', '${p.currentBillingReport!.additionalFees} ${p.currentBillingReport!.currency}'),
                    const Divider(height: 16),
                    _buildBillingRow('TOTAL OWED', '${p.currentBillingReport!.totalOwed} ${p.currentBillingReport!.currency}', isBold: true),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBillingRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
            fontSize: isBold ? 18 : 14,
          )),
        ],
      ),
    );
  }
}
