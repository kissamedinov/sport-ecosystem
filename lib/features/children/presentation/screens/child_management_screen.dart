import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import '../../models/child.dart';
import '../../providers/child_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../notifications/data/models/notification.dart';

class ChildManagementScreen extends StatefulWidget {
  final Child child;

  const ChildManagementScreen({super.key, required this.child});

  @override
  State<ChildManagementScreen> createState() => _ChildManagementScreenState();
}

class _ChildManagementScreenState extends State<ChildManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _childNotifications = [];
  bool _isLoadingNotifications = true;
  late Child _currentChild;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentChild = widget.child;
    _fetchChildData();
  }

  Future<void> _fetchChildData() async {
    setState(() => _isLoadingNotifications = true);
    try {
      final notifications = await context.read<NotificationProvider>().fetchNotificationsForUser(_currentChild.id);
      
      // Filter for invitations or relevant management notifications
      setState(() {
        _childNotifications = notifications.where((n) => 
          (n.type == 'TEAM_INVITE' || n.type == 'CLUB_INVITATION' || n.type == 'ACADEMY_REQUEST' || n.type == 'PARENT_LINK_REQUEST' || n.type == 'CLUB_APPROVED') && !n.isRead
        ).toList();
        _isLoadingNotifications = false;
      });

      // Also fetch activities and awards for the second tab
      context.read<ChildProvider>().fetchActivities(_currentChild.id);
      context.read<ChildProvider>().fetchAwards(_currentChild.id);
    } catch (e) {
      if (mounted) setState(() => _isLoadingNotifications = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentChild.name.toUpperCase(), style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.neonGreen,
          labelColor: PremiumTheme.neonGreen,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'MANAGEMENT'),
            Tab(text: 'ACTIVITY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManagementTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          const Text('PERSONAL SETTINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
          const SizedBox(height: 12),
          _buildBirthdayPicker(),
          const SizedBox(height: 32),
          const Text('PENDING INVITATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
          const SizedBox(height: 12),
          _buildInvitationsList(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return PremiumCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: PremiumTheme.electricBlue.withOpacity(0.1),
            child: const Icon(Icons.face, size: 40, color: PremiumTheme.electricBlue),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentChild.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Age ${_currentChild.age} • ${_currentChild.teamName}', style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(_currentChild.email, style: const TextStyle(color: Colors.white30, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayPicker() {
    return PremiumCard(
      onTap: () => _selectBirthday(context),
      child: Row(
        children: [
          const Icon(Icons.cake_rounded, color: PremiumTheme.neonGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date of Birth', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  _currentChild.dateOfBirth != null 
                    ? _currentChild.dateOfBirth!.toLocal().toString().split(' ')[0]
                    : 'Not Set',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_calendar_rounded, color: Colors.white24, size: 20),
        ],
      ),
    );
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentChild.dateOfBirth ?? DateTime(2010),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: PremiumTheme.neonGreen,
            onPrimary: Colors.black,
            surface: PremiumTheme.surfaceCard(context),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final success = await context.read<AuthProvider>().updateUserProfile(_currentChild.id, {
        'date_of_birth': picked.toIso8601String().split('T')[0],
      });

      if (success && mounted) {
        setState(() {
          // Re-calculate age locally or re-fetch
          _currentChild = Child(
            id: _currentChild.id,
            name: _currentChild.name,
            age: _calculateAge(picked),
            dateOfBirth: picked,
            email: _currentChild.email,
            teamName: _currentChild.teamName,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Birthday updated!')));
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildInvitationsList() {
    if (_isLoadingNotifications) return const Center(child: CircularProgressIndicator());
    if (_childNotifications.isEmpty) {
      return const PremiumCard(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No pending invitations for this child.', style: TextStyle(color: Colors.white38, fontSize: 13))),
        ),
      );
    }

    return Column(
      children: _childNotifications.map((notif) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, color: PremiumTheme.neonGreen, size: 18),
                  const SizedBox(width: 12),
                  Text(notif.type.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: PremiumTheme.neonGreen)),
                ],
              ),
              const SizedBox(height: 12),
              Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(notif.message, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
                      onPressed: () => _handleInvitation(notif, false),
                      child: const Text('DECLINE', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen),
                      onPressed: () => _handleInvitation(notif, true),
                      child: const Text('ACCEPT', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Future<void> _handleInvitation(NotificationModel notif, bool accept) async {
    if (notif.entityId == null) return;
    
    try {
      await context.read<NotificationProvider>().handleInvitation(notif.entityId!, accept);
      if (mounted) {
        if (accept) {
          // Refresh child list to get new team/club status
          await context.read<ChildProvider>().fetchChildren();
          // Update local status if child is found
          final updatedChildList = context.read<ChildProvider>().children;
          final updatedChild = updatedChildList.where((c) => c.id == _currentChild.id).toList();
          if (updatedChild.isNotEmpty) {
             setState(() {
               _currentChild = updatedChild.first;
             });
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Invitation accepted!' : 'Invitation declined.'))
        );
        _fetchChildData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  Widget _buildActivityTab() {
    final provider = context.watch<ChildProvider>();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('MATCH HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
        const SizedBox(height: 12),
        if (provider.activities.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No matches found.', style: TextStyle(color: Colors.white38))))
        else
          ...provider.activities.map((a) => _buildActivityItem(a)),
        const SizedBox(height: 32),
        const Text('AWARDS & ACHIEVEMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
        const SizedBox(height: 12),
        if (provider.awards.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No awards yet.', style: TextStyle(color: Colors.white38))))
        else
          ...provider.awards.map((aw) => _buildAwardItem(aw)),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Card(
      color: PremiumTheme.surfaceCard(context),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.sports_soccer, color: Colors.white70)),
        title: const Text('Match History', style: TextStyle(fontWeight: FontWeight.bold)), 
        subtitle: Text('Score: ${activity['home_score']} - ${activity['away_score']}'),
        trailing: Text(activity['created_at']?.split('T')?.first ?? '', style: const TextStyle(fontSize: 11, color: Colors.white38)),
      ),
    );
  }

  Widget _buildAwardItem(Map<String, dynamic> award) {
    return Card(
      color: PremiumTheme.surfaceCard(context),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.orange, size: 30),
        title: Text(award['award_type'] ?? 'Achievement', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(award['tournament_name'] ?? 'Tournament'),
        trailing: Text(award['awarded_at']?.split('T')?.first ?? '', style: const TextStyle(fontSize: 11, color: Colors.white38)),
      ),
    );
  }
}
