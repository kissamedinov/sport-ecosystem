import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/club_stat_card.dart';
import '../widgets/academy_list_item.dart';
import 'package:mobile/features/admin/presentation/screens/admin_hub_screen.dart';
import 'create_child_profile_screen.dart';
import 'invite_member_screen.dart';
import 'invitations_screen.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';

class ClubDashboardScreen extends StatefulWidget {
  final bool isHome;
  final String? clubId;
  const ClubDashboardScreen({super.key, this.isHome = false, this.clubId});

  @override
  State<ClubDashboardScreen> createState() => _ClubDashboardScreenState();
}

class _ClubDashboardScreenState extends State<ClubDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ClubProvider>().fetchClubDashboard(widget.isHome ? null : widget.clubId);
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Consumer<ClubProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.dashboard == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.dashboard == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.error}'),
                    ElevatedButton(
                      onPressed: () => provider.fetchClubDashboard(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final dashboard = provider.dashboard;
            if (dashboard == null) {
              final user = context.read<AuthProvider>().user;
              final isAdmin = user?.roles?.contains('ADMIN') ?? false;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business_center, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('You don\'t have a club registered yet.', 
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showRequestClubDialog(context),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Request to Create a Club'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHubScreen())),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Admin: Moderation Panel'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return DefaultTabController(
              length: 5,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: widget.isHome ? 120.0 : 180.0,
                    floating: false,
                    pinned: true,
                    actions: [
                      if (context.read<AuthProvider>().user?.roles?.contains('ADMIN') ?? false)
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHubScreen())),
                          tooltip: 'Moderation Hub',
                        ),
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateChildProfileScreen(clubId: dashboard.club.id))),
                        tooltip: 'New Child Profile',
                      ),
                      IconButton(
                        icon: const Icon(Icons.mail_outline),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationsScreen())),
                        tooltip: 'My Invitations',
                      ),
                      Consumer<NotificationProvider>(
                        builder: (context, notificationProvider, _) {
                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                                },
                                tooltip: 'Notifications',
                              ),
                              if (notificationProvider.unreadCount > 0)
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
                                      '${notificationProvider.unreadCount}',
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
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(dashboard.club.name, 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      centerTitle: false,
                      titlePadding: EdgeInsets.only(
                        left: 16, 
                        bottom: widget.isHome ? 16 : 64, // Push title up when tabs are present
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Icon(Icons.business, size: 150, color: Colors.white.withOpacity(0.1)),
                            ),
                            Positioned(
                              left: 16,
                              bottom: widget.isHome ? 40 : 88,
                              child: InkWell(
                                onTap: () => _copyToClipboard(dashboard.club.id, 'Club ID'),
                                child: Text(
                                  'Club ID: ${dashboard.club.id.substring(0, 8)}...',
                                  style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    bottom: widget.isHome ? null : TabBar(
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Academies', icon: Icon(Icons.location_city, size: 20)),
                        Tab(text: 'Teams', icon: Icon(Icons.group, size: 20)),
                        Tab(text: 'Players', icon: Icon(Icons.person, size: 20)),
                        Tab(text: 'Coaches', icon: Icon(Icons.badge, size: 20)),
                        Tab(text: 'Pending', icon: Icon(Icons.hourglass_empty, size: 20)),
                      ],
                    ),
                  ),
                  if (widget.isHome) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Overview',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ClubDashboardScreen(isHome: false)),
                                  ),
                                  child: const Text('Manage Club'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.5,
                              children: [
                                ClubStatCard(
                                  title: 'Academies',
                                  value: dashboard.academies.length.toString(),
                                  icon: Icons.location_city,
                                  color: Colors.blue,
                                ),
                                ClubStatCard(
                                  title: 'Teams',
                                  value: dashboard.teams.length.toString(),
                                  icon: Icons.group,
                                  color: Colors.green,
                                ),
                                ClubStatCard(
                                  title: 'Players',
                                  value: (dashboard.playersCount + dashboard.childProfiles.length).toString(),
                                  icon: Icons.person,
                                  color: Colors.orange,
                                ),
                                ClubStatCard(
                                  title: 'Coaches',
                                  value: dashboard.coachesCount.toString(),
                                  icon: Icons.badge,
                                  color: Colors.purple,
                                ),
                                ClubStatCard(
                                  title: 'Invitations',
                                  value: 'View',
                                  icon: Icons.mail_outline,
                                  color: Colors.redAccent,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationsScreen())),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (!widget.isHome)
                    SliverFillRemaining(
                      child: TabBarView(
                        children: [
                          _buildAcademiesList(dashboard),
                          _buildTeamsList(dashboard),
                          _buildPlayersList(dashboard),
                          _buildCoachesList(dashboard),
                          _buildPendingInvitesList(dashboard),
                        ],
                      ),
                    ),
                  if (widget.isHome)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: SizedBox(height: 100),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAcademiesList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Club Branches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showCreateAcademyDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Academy'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dashboard.academies.length,
            itemBuilder: (context, index) {
              return AcademyListItem(academy: dashboard.academies[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Club Teams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showCreateTeamDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Team'),
              ),
            ],
          ),
        ),
        Expanded(
          child: dashboard.teams.isEmpty
              ? const Center(child: Text('No teams found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dashboard.teams.length,
                  itemBuilder: (context, index) {
                    final team = dashboard.teams[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.group, color: Colors.green),
                        title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${team.academyName ?? 'N/A'} | Category: ${team.ageCategory ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildTeamStat(context, 'Rating', team.rating.toString(), Colors.amber),
                                const SizedBox(width: 8),
                                _buildTeamStat(context, 'W', team.wins.toString(), Colors.green),
                                const SizedBox(width: 4),
                                _buildTeamStat(context, 'D', team.draws.toString(), Colors.grey),
                                const SizedBox(width: 4),
                                _buildTeamStat(context, 'L', team.losses.toString(), Colors.red),
                              ],
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _copyToClipboard(team.coachId, 'Coach ID'),
                              child: Text('Coach ID: ${team.coachId.substring(0, 8)}...', 
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTeamStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPlayersList(dynamic dashboard) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Active Players (Linked)', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (dashboard.players.isEmpty)
          const Card(child: ListTile(title: Text('No linked players yet'))),
        ...dashboard.players.map((player) => Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(player.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pos: ${player.position ?? 'N/A'} | #: ${player.jerseyNumber ?? 'N/A'}'),
                InkWell(
                  onTap: () => _copyToClipboard('${player.userId} | ${player.profileId}', 'IDs'),
                  child: Text('User: ${player.userId.substring(0, 8)} | Prof: ${player.profileId.substring(0, 8)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        )),
        
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Unlinked Player Profiles', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (dashboard.childProfiles.isEmpty)
          const Card(child: ListTile(title: Text('No placeholder profiles created'))),
        ...dashboard.childProfiles.map((child) => Card(
          color: Colors.orange.withOpacity(0.05),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: const Icon(Icons.person_outline, color: Colors.orange),
            ),
            title: Text(child.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pos: ${child.position ?? 'N/A'} (Placeholder)'),
                InkWell(
                  onTap: () => _copyToClipboard(child.id, 'Profile ID'),
                  child: Text('Profile ID: ${child.id.substring(0, 8)}...',
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                ),
              ],
            ),
            trailing: TextButton(
              onPressed: () {
                // Future: Action to link/invite
              },
              child: const Text('Invite User'),
            ),
          ),
        )),
        const SizedBox(height: 100), // Space for bottom padding
      ],
    );
  }

  Widget _buildCoachesList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Coaching Staff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showInviteStaffDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Invite Coach'),
              ),
            ],
          ),
        ),
        Expanded(
          child: dashboard.coaches.isEmpty
              ? const Center(child: Text('No coaches found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dashboard.coaches.length,
                  itemBuilder: (context, index) {
                    final coach = dashboard.coaches[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.sports)),
                        title: Text(coach.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _copyToClipboard(coach.userId, 'User ID'),
                              child: Text('User ID: ${coach.userId.substring(0, 8)}...'),
                            ),
                            InkWell(
                              onTap: () => _copyToClipboard(coach.profileId, 'Profile ID'),
                              child: Text('Profile: ${coach.profileId.substring(0, 8)}...',
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPendingInvitesList(dynamic dashboard) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Sent Invitations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: dashboard.pendingInvitations.isEmpty
              ? const Center(child: Text('No pending invitations'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dashboard.pendingInvitations.length,
                  itemBuilder: (context, index) {
                    final invite = dashboard.pendingInvitations[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline, color: Colors.orange),
                        title: Text('Role: ${invite.role.toString().split('.').last.toUpperCase()}'),
                        subtitle: Text('To: ${invite.invitedUserId.substring(0, 8)} | Approved: ${invite.isApproved}'),
                        trailing: invite.isApproved 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : TextButton(
                              onPressed: () => context.read<ClubProvider>().approveInvitation(invite.id),
                              child: const Text('Approve'),
                            ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showRequestClubDialog(BuildContext context) {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Club Creation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Club Name')),
              TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 8),
              const Text('Note: Your request will be reviewed by an administrator.', 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && cityController.text.isNotEmpty && addressController.text.isNotEmpty) {
                final success = await context.read<ClubProvider>().submitClubRequest({
                  'name': nameController.text,
                  'city': cityController.text,
                  'address': addressController.text,
                });
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Club request submitted successfully!')),
                  );
                }
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showCreateAcademyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Academy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final clubId = context.read<ClubProvider>().dashboard?.club.id;
              if (clubId != null) {
                final success = await context.read<ClubProvider>().createAcademy(
                  clubId,
                  nameController.text,
                  cityController.text,
                  addressController.text,
                );
                if (success) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final birthYearController = TextEditingController();
    final coachIdController = TextEditingController();
    String? selectedAcademyId;

    final academies = context.read<ClubProvider>().dashboard?.academies ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedAcademyId,
                  decoration: const InputDecoration(labelText: 'Academy'),
                  items: academies
                      .map((a) => DropdownMenuItem(value: a.id.toString(), child: Text(a.name)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedAcademyId = val),
                ),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Team Name')),
                TextField(
                    controller: birthYearController,
                    decoration: const InputDecoration(labelText: 'Birth Year'),
                    keyboardType: TextInputType.number),
                TextField(controller: coachIdController, decoration: const InputDecoration(labelText: 'Coach User ID')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedAcademyId != null &&
                    nameController.text.isNotEmpty &&
                    birthYearController.text.isNotEmpty &&
                    coachIdController.text.isNotEmpty) {
                  final success = await context.read<ClubProvider>().createTeam(
                        selectedAcademyId!,
                        nameController.text,
                        int.parse(birthYearController.text),
                        coachIdController.text,
                      );
                  if (success) Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteStaffDialog(BuildContext context) {
    final clubId = context.read<ClubProvider>().dashboard?.club.id;
    if (clubId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => InviteMemberScreen(clubId: clubId)));
    }
  }
}
