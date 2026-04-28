import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/academies/providers/academy_provider.dart';
import 'package:mobile/features/academies/data/models/academy.dart';
import 'package:mobile/features/academies/data/models/academy_team.dart';
import 'package:intl/intl.dart';

class TrainingManagementScreen extends StatefulWidget {
  final String academyId;
  const TrainingManagementScreen({super.key, required this.academyId});

  @override
  State<TrainingManagementScreen> createState() => _TrainingManagementScreenState();
}

class _TrainingManagementScreenState extends State<TrainingManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AcademyProvider>().fetchSessions(widget.academyId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('TRAINING HUB', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: PremiumTheme.neonGreen),
            onPressed: () => _showGenerateSessionsDialog(context),
            tooltip: 'Bulk Generate from Schedules',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSessionDialog(context),
        backgroundColor: PremiumTheme.neonGreen,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Consumer<AcademyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.sessions.isEmpty) return const Center(child: CircularProgressIndicator());
          if (provider.error != null) return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));

          final sessions = provider.sessions;
          if (sessions.isEmpty) {
            return const Center(child: Text('No training sessions scheduled', style: TextStyle(color: Colors.white38)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return PremiumCard(
                onTap: () => _navigateToAttendance(context, session),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.fitness_center, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(session.scheduledAt, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          Text(session.topic ?? 'General Training', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToAttendance(BuildContext context, TrainingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AttendanceScreen(session: session)),
    );
  }

  void _showGenerateSessionsDialog(BuildContext context) async {
    final provider = context.read<AcademyProvider>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: PremiumTheme.neonGreen,
            onPrimary: Colors.black,
            surface: PremiumTheme.surfaceCard(context),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (range != null) {
      final success = await provider.triggerGenerateSessions(
        widget.academyId,
        range.start,
        range.end,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sessions generated from ${DateFormat('MMM dd').format(range.start)} to ${DateFormat('MMM dd').format(range.end)}'),
            backgroundColor: PremiumTheme.neonGreen,
          ),
        );
      }
    }
  }

  void _showCreateSessionDialog(BuildContext context) {
     // Dialog implementation for creating a session
  }
}

class AttendanceScreen extends StatefulWidget {
  final TrainingSession session;
  const AttendanceScreen({super.key, required this.session});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Map player_id -> { 'status': ..., 'note': ... }
  final Map<String, Map<String, String>> _attendance = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AcademyProvider>().fetchCompositePlayers(widget.session.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ATTENDANCE TRACKING', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 10, color: PremiumTheme.neonGreen)),
            Text(widget.session.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AcademyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.compositePlayers.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }
          
          final players = provider.compositePlayers;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final data = _attendance[player.id] ?? {
                      'status': 'PRESENT',
                      'note': '',
                    };
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: PremiumTheme.surfaceCard(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(player.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text("${player.birthYear ?? 'N/A'} • ${player.teamName}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: PremiumTheme.surfaceCard(context),
                                  value: data['status'],
                                  style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
                                  items: const [
                                    DropdownMenuItem(value: 'PRESENT', child: Text('PRESENT')),
                                    DropdownMenuItem(value: 'ABSENT', child: Text('ABSENT')),
                                    DropdownMenuItem(value: 'LATE', child: Text('LATE')),
                                    DropdownMenuItem(value: 'INJURED', child: Text('INJURED')),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _attendance[player.id] = {
                                        'status': val!,
                                        'note': data['note']!,
                                      };
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: TextField(
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Add performance note...',
                                hintStyle: const TextStyle(color: Colors.white12),
                                prefixIcon: const Icon(Icons.edit_note, color: Colors.white24, size: 20),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onChanged: (val) {
                                _attendance[player.id] = {
                                  'status': data['status']!,
                                  'note': val,
                                };
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 10),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    // Populate default values for players not interacted with
                    for (final p in players) {
                      if (!_attendance.containsKey(p.id)) {
                        _attendance[p.id] = {'status': 'PRESENT', 'note': ''};
                      }
                    }

                    final success = await provider.recordAttendance(widget.session.id, _attendance);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance recorded successfully!'), backgroundColor: PremiumTheme.neonGreen),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('SUBMIT ATTENDANCE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
