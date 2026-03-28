import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import '../../clubs/presentation/screens/invitations_screen.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/core/theme/premium_theme.dart';

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
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('COACH HUB', style: TextStyle(letterSpacing: 2)),
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
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text('${provider.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 8),
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
          ? const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumHeader(
                    title: 'Welcome back, Coach ${(user?.name ?? '').split(' ').first}!',
                    subtitle: 'CERTIFIED COACH',
                    trailing: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: const Icon(Icons.sports, color: Colors.blue),
                    ),
                  ),
                  
                  InkWell(
                    onTap: () => _copyToClipboard(user?.id ?? '', 'User ID'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        'COACH ID: ${user?.id.substring(0, 8).toUpperCase()}...',
                        style: const TextStyle(fontSize: 9, color: Colors.white38, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('MATCH & PERFORMANCE', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: PremiumStatCard(
                          title: 'Active Teams',
                          value: (clubProvider.coachDashboard?['teams'] as List?)?.length.toString() ?? '0',
                          icon: Icons.groups_rounded,
                          color: PremiumTheme.electricBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PremiumStatCard(
                          title: 'Total Players',
                          value: _calculateTotalPlayers(clubProvider.coachDashboard),
                          icon: Icons.person_rounded,
                          color: PremiumTheme.neonGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('TEAM MANAGEMENT', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  
                  if (clubProvider.coachDashboard?['teams']?.isEmpty ?? true)
                    const PremiumCard(child: Center(child: Text('No teams assigned yet', style: TextStyle(color: Colors.white38))))
                  else
                    ...((clubProvider.coachDashboard?['teams'] as List).map((team) {
                      return PremiumCard(
                        padding: EdgeInsets.zero,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.groups, color: Colors.green, size: 20),
                            ),
                            title: Text(team['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text('Category: ${team['age_category'] ?? team['birth_year']} | Players: ${(team['players'] as List).length}', 
                              style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            children: [
                              const Divider(color: Colors.white10),
                              ...(team['players'] as List).map((player) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.person_outline, size: 18, color: Colors.white24),
                                  title: Text(player['name'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  subtitle: Text('Pos: ${player['position'] ?? 'N/A'} | #: ${player['jersey_number'] ?? 'N/A'}', 
                                    style: const TextStyle(color: Colors.white24, fontSize: 11)),
                                  trailing: const Icon(Icons.chevron_right, size: 14, color: Colors.white10),
                                );
                              }),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    })),

                  const SizedBox(height: 24),
                  const Text('COACHING TOOLS', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _buildCoachAction(context, 'Reports', Icons.assignment_rounded, Colors.blue, 'Match Reports'),
                      _buildCoachAction(context, 'Schedule', Icons.calendar_month_rounded, Colors.orange, 'Training Schedule'),
                      _buildCoachAction(context, 'Tactics', Icons.psychology_rounded, Colors.purple, 'Tactic Board'),
                      _buildCoachAction(context, 'Inbox', Icons.mail_outline_rounded, Colors.redAccent, 'Invitations', child: const InvitationsScreen()),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  String _calculateTotalPlayers(dynamic dashboard) {
    if (dashboard == null || dashboard['teams'] == null) return '0';
    int total = 0;
    for (var team in (dashboard['teams'] as List)) {
      total += (team['players'] as List).length;
    }
    return total.toString();
  }

  Widget _buildCoachAction(BuildContext context, String label, IconData icon, Color color, String title, {Widget? child}) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => child ?? TemporaryScreen(title: title))),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class TemporaryScreen extends StatelessWidget {
  final String title;
  const TemporaryScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Content for $title coming soon!')),
    );
  }
}
