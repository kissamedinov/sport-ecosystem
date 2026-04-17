import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/academy_provider.dart';
import '../../data/models/crm_models.dart';
import '../../data/models/academy_team.dart';
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
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        final hasAcademy = provider.myAcademy != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Academy Dashboard'),
            bottom: hasAcademy
                ? TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Teams'),
                      Tab(text: 'Schedules'),
                      Tab(text: 'Billing'),
                    ],
                  )
                : null,
          ),
          body: provider.isLoading && !hasAcademy
              ? const Center(child: CircularProgressIndicator())
              : hasAcademy
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(provider),
                        _buildTeamsTab(provider),
                        _buildSchedulesTab(provider),
                        _buildBillingTab(provider),
                      ],
                    )
                  : _buildNoAcademyView(),
          floatingActionButton: hasAcademy ? _buildFab() : null,
        );
      },
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
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
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

  DayOfWeek? _filterDay;
  String? _filterTeamId;

  Widget _buildSchedulesTab(AcademyProvider provider) {
    var filteredSchedules = provider.schedules;
    if (_filterDay != null) {
      filteredSchedules = filteredSchedules.where((s) => s.dayOfWeek == _filterDay).toList();
    }
    if (_filterTeamId != null) {
      filteredSchedules = filteredSchedules.where((s) => s.teamIds.contains(_filterTeamId)).toList();
    }

    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: Text(_filterDay?.toShortString() ?? 'All Days'),
                  avatar: const Icon(Icons.today, size: 16),
                  onPressed: () => _selectFilterDay(),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(_filterTeamId != null 
                    ? provider.teams.firstWhere((t) => t.id == _filterTeamId).name 
                    : 'All Teams'),
                  avatar: const Icon(Icons.group, size: 16),
                  onPressed: () => _selectFilterTeam(provider),
                ),
                if (_filterDay != null || _filterTeamId != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _filterDay = null;
                        _filterTeamId = null;
                      });
                    },
                  ),
                ],
                const SizedBox(width: 32),
                TextButton.icon(
                  onPressed: () => provider.generateSessions(provider.myAcademy!.id),
                  icon: const Icon(Icons.bolt, size: 16, color: Colors.amber),
                  label: const Text('Generate Sessions', style: TextStyle(color: Colors.amber)),
                ),
              ],
            ),
          ),
        ),
        
        Expanded(
          child: filteredSchedules.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(provider.schedules.isEmpty 
                      ? 'No training schedules configured.' 
                      : 'No schedules match your filters.'),
                    const SizedBox(height: 16),
                    if (provider.schedules.isEmpty)
                      ElevatedButton(
                        onPressed: () => _showAddScheduleDialog(),
                        child: const Text('Add Schedule'),
                      ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredSchedules.length,
                itemBuilder: (context, index) {
                  final schedule = filteredSchedules[index];
                  final scheduleTeams = provider.teams.where((t) => schedule.teamIds.contains(t.id)).toList();
                  final teamsLabel = scheduleTeams.isNotEmpty 
                      ? scheduleTeams.map((e) => e.name).join(', ')
                      : 'No teams assigned';
                  
                  final branch = schedule.branchId != null 
                      ? provider.branches.firstWhere((b) => b.id == schedule.branchId, orElse: () => AcademyBranch(id: '', academyId: '', name: 'Unknown', address: ''))
                      : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.timer, color: Colors.orange, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${schedule.dayOfWeek.toShortString()} | ${schedule.startTime} - ${schedule.endTime}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.group, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(teamsLabel, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                                  ],
                                ),
                                if (branch != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Colors.blueAccent),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text('${branch.name} (${branch.address})', 
                                        style: const TextStyle(color: Colors.blueAccent, fontSize: 13))),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.place, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(schedule.location ?? "Main Field", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              // TODO: Delete schedule
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  void _selectFilterDay() async {
    final result = await showDialog<DayOfWeek>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DayOfWeek.values.map((day) => ListTile(
            title: Text(day.toShortString()),
            onTap: () => Navigator.pop(context, day),
          )).toList(),
        ),
      ),
    );
    if (result != null) {
      setState(() => _filterDay = result);
    }
  }

  void _selectFilterTeam(AcademyProvider provider) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Team'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.teams.length,
            itemBuilder: (context, index) {
              final team = provider.teams[index];
              return ListTile(
                leading: CircleAvatar(child: Text(team.ageGroup)),
                title: Text(team.name),
                onTap: () => Navigator.pop(context, team.id),
              );
            },
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() => _filterTeamId = result);
    }
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
              final academyId = provider.myAcademy?.id;
              if (academyId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No academy loaded')));
                return;
              }
              provider.createTeam(academyId, nameController.text, ageController.text, 'Intermediate');
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
    final academyId = provider.myAcademy?.id;
    if (academyId == null) return;
    
    if (provider.teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a team first')));
      return;
    }

    // Fetch branches if not already loaded
    provider.fetchBranches(academyId);

    List<String> selectedTeamIds = [provider.teams[0].id];
    List<Map<String, dynamic>> scheduleItems = [
      {
        'day_of_week': DayOfWeek.MONDAY,
        'start_time': const TimeOfDay(hour: 18, minute: 0),
        'end_time': const TimeOfDay(hour: 19, minute: 30),
      }
    ];
    String? selectedBranchId;
    final locationController = TextEditingController(text: 'Main Field');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final branches = provider.branches;
          
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Add Schedule', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  
                  // Team Selection
                  const Text('Select Teams:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: provider.teams.map((t) {
                      final isSelected = selectedTeamIds.contains(t.id);
                      return FilterChip(
                        label: Text(t.name),
                        selected: isSelected,
                        selectedColor: Colors.blue.withOpacity(0.3),
                        checkmarkColor: Colors.blue,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              selectedTeamIds.add(t.id);
                            } else if (selectedTeamIds.length > 1) {
                              selectedTeamIds.remove(t.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 32, color: Colors.grey),

                  // Branch Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Location / Branch:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      TextButton.icon(
                        onPressed: () => _showAddBranchDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Branch'),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF2C2C2C),
                    value: selectedBranchId,
                    hint: const Text('Select Branch (Summer/Winter)', style: TextStyle(color: Colors.grey)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Branch (General)')),
                      ...branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                    ],
                    onChanged: (v) => setModalState(() => selectedBranchId = v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Specific Location (Field #, Room)',
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const Divider(height: 32, color: Colors.grey),

                  // Multi-day slots
                  const Text('Training Days & Times:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...scheduleItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Card(
                      color: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<DayOfWeek>(
                                    isExpanded: true,
                                    value: item['day_of_week'],
                                    underline: const SizedBox(),
                                    items: DayOfWeek.values.map((d) => DropdownMenuItem(value: d, child: Text(d.toShortString()))).toList(),
                                    onChanged: (v) => setModalState(() => item['day_of_week'] = v!),
                                  ),
                                ),
                                if (scheduleItems.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () => setModalState(() => scheduleItems.removeAt(idx)),
                                  ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(context: context, initialTime: item['start_time']);
                                      if (picked != null) setModalState(() => item['start_time'] = picked);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Start', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text((item['start_time'] as TimeOfDay).format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(context: context, initialTime: item['end_time']);
                                      if (picked != null) setModalState(() => item['end_time'] = picked);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('End', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text((item['end_time'] as TimeOfDay).format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setModalState(() => scheduleItems.add({
                      'day_of_week': DayOfWeek.MONDAY,
                      'start_time': const TimeOfDay(hour: 18, minute: 0),
                      'end_time': const TimeOfDay(hour: 19, minute: 30),
                    })),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Day'),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final List<Map<String, dynamic>> finalSchedules = scheduleItems.map((item) {
                          final start = item['start_time'] as TimeOfDay;
                          final end = item['end_time'] as TimeOfDay;
                          return {
                            'team_ids': selectedTeamIds,
                            'day_of_week': (item['day_of_week'] as DayOfWeek).toShortString(),
                            'start_time': '${start.hour.toString().padLeft(2, "0")}:${start.minute.toString().padLeft(2, "0")}',
                            'end_time': '${end.hour.toString().padLeft(2, "0")}:${end.minute.toString().padLeft(2, "0")}',
                            'location': locationController.text,
                            'branch_id': selectedBranchId,
                          };
                        }).toList();

                        final success = await provider.createSchedule(academyId, {
                          'schedules': finalSchedules,
                        });
                        if (success) Navigator.pop(context);
                      },
                      child: const Text('Save All Schedules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddBranchDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final provider = context.read<AcademyProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Academy Branch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Branch Name (e.g. Summer Venue)')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final academyId = provider.myAcademy?.id;
              if (academyId == null) return;
              await provider.createBranch(academyId, nameController.text, addressController.text, null);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
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
              final academyId = provider.myAcademy?.id;
              if (academyId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No academy loaded to save config')),
                );
                return;
              }
              final success = await provider.saveBillingConfig(academyId, {
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
    
    final academyId = provider.myAcademy?.id;
    if (academyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No academy loaded to fetch report')),
      );
      return;
    }
    
    provider.fetchBillingReport(academyId, playerId, now.month, now.year);
    
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
