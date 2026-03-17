import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import '../../clubs/presentation/screens/invitations_screen.dart';
import '../widgets/dashboard_widgets.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ClubProvider>().fetchCoachDashboard();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final clubProvider = context.watch<ClubProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('COACH HUB'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                    },
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${provider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              clubProvider.fetchCoachDashboard();
              context.read<NotificationProvider>().fetchNotifications();
            },
          ),
        ],
      ),
      body: clubProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardHeader(
                    title: 'Welcome back, Coach ${user?.name ?? ''}!',
                    subtitle: 'Certified Coach',
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(user?.id ?? '', 'User ID'),
                    child: Text(
                      'User ID: ${user?.id.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('My Managed Teams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (clubProvider.coachDashboard?['teams']?.isEmpty ?? true)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No teams assigned yet')))
                  else
                    ...((clubProvider.coachDashboard?['teams'] as List).map((team) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          leading: const CircleAvatar(child: Icon(Icons.groups)),
                          title: Text(team['name']),
                          subtitle: Text('Birth Year: ${team['birth_year']} | Players: ${(team['players'] as List).length}'),
                          children: [
                            ...(team['players'] as List).map((player) {
                              return ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(player['name']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Position: ${player['position'] ?? 'N/A'} | #: ${player['jersey_number'] ?? 'N/A'}'),
                                    InkWell(
                                      onTap: () => _copyToClipboard('${player['user_id']} | ${player['profile_id']}', 'IDs'),
                                      child: Text(
                                        'User: ${player['user_id'].substring(0, 8)} | Prof: ${player['profile_id'].substring(0, 8)}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    })).toList(),
                  const SizedBox(height: 32),
                  const Text('Coach Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      DashboardGridAction(
                        label: 'Match Report',
                        icon: Icons.assignment,
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      DashboardGridAction(
                        label: 'Schedule',
                        icon: Icons.calendar_today,
                        color: Colors.orange,
                        onTap: () {},
                      ),
                      DashboardGridAction(
                        label: 'Player Stats',
                        icon: Icons.trending_up,
                        color: Colors.green,
                        onTap: () {},
                      ),
                      DashboardGridAction(
                        label: 'Tactics',
                        icon: Icons.bolt,
                        color: Colors.purple,
                        onTap: () {},
                      ),
                      DashboardGridAction(
                        label: 'Invitations',
                        icon: Icons.mail_outline,
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationsScreen()));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
