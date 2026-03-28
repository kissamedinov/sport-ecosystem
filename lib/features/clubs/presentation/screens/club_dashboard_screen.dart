import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../providers/club_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:mobile/features/admin/presentation/screens/admin_hub_screen.dart';
import 'create_child_profile_screen.dart';
import 'invite_member_screen.dart';
import 'invitations_screen.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';
import '../../../media/presentation/screens/media_gallery_screen.dart';
import 'academy_management_screen.dart';
import 'team_management_screen.dart';

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
      backgroundColor: PremiumTheme.deepNavy,
      body: Consumer<ClubProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.dashboard == null) {
            return Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.error != null && provider.dashboard == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business_center, size: 80, color: Colors.white10),
                    const SizedBox(height: 24),
                    const Text('You don\'t have a club registered yet.', 
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    PremiumCard(
                      onTap: () => _showRequestClubDialog(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: PremiumTheme.neonGreen),
                          SizedBox(width: 12),
                          Text('Request to Create a Club', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHubScreen())),
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.white54),
                        label: const Text('Admin: Moderation Panel', style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return DefaultTabController(
            length: 6,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: widget.isHome ? 130.0 : 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: PremiumTheme.deepNavy,
                  elevation: 0,
                  actions: [
                    if (context.read<AuthProvider>().user?.roles?.contains('ADMIN') ?? false)
                      IconButton(
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.white70),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHubScreen())),
                      ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white70),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateChildProfileScreen(clubId: dashboard.club.id))),
                    ),
                    Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, _) {
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: Colors.white70),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                              },
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
                                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                  child: Text('${notificationProvider.unreadCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 8),
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
                    centerTitle: false,
                    titlePadding: EdgeInsets.only(left: 20, bottom: widget.isHome ? 16 : 60),
                    title: Text(dashboard.club.name.toUpperCase(), 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1, color: Colors.white)),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [PremiumTheme.electricBlue, PremiumTheme.deepNavy],
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(Icons.business_rounded, size: 180, color: Colors.white.withOpacity(0.05)),
                        ),
                        // Club ID Badge
                        Positioned(
                          left: 20,
                          bottom: widget.isHome ? 45 : 95,
                          child: InkWell(
                            onTap: () => _copyToClipboard(dashboard.club.id, 'Club ID'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ID: ${dashboard.club.id.substring(0, 8)}...',
                                style: const TextStyle(fontSize: 9, color: Colors.white54, fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottom: widget.isHome ? null : TabBar(
                    isScrollable: true,
                    indicatorColor: PremiumTheme.neonGreen,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'ACADEMIES'),
                      Tab(text: 'TEAMS'),
                      Tab(text: 'PLAYERS'),
                      Tab(text: 'COACHES'),
                      Tab(text: 'MEDIA'),
                      Tab(text: 'PENDING'),
                    ],
                  ),
                ),
                if (widget.isHome) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('OVERVIEW', 
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ClubDashboardScreen(isHome: false)),
                                ),
                                child: Text('MANAGE HUB', style: TextStyle(fontSize: 10, color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 0, // PremiumStatCard handles margin
                            childAspectRatio: 1.3,
                            children: [
                              PremiumStatCard(
                                title: 'Academies',
                                value: dashboard.academies.length.toString(),
                                icon: Icons.location_city_rounded,
                                color: Colors.blue,
                              ),
                              PremiumStatCard(
                                title: 'Teams',
                                value: dashboard.teams.length.toString(),
                                icon: Icons.group_rounded,
                                color: Colors.green,
                              ),
                              PremiumStatCard(
                                title: 'Players',
                                value: (dashboard.playersCount + dashboard.childProfiles.length).toString(),
                                icon: Icons.person_rounded,
                                color: Colors.orange,
                              ),
                              PremiumStatCard(
                                title: 'Coaches',
                                value: dashboard.coachesCount.toString(),
                                icon: Icons.badge_rounded,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PremiumCard(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationsScreen())),
                            child: const Row(
                              children: [
                                Icon(Icons.mail_outline, color: Colors.redAccent),
                                SizedBox(width: 16),
                                Expanded(child: Text('CLUB INVITATIONS', style: TextStyle(fontWeight: FontWeight.bold))),
                                Icon(Icons.chevron_right, color: Colors.white24),
                              ],
                            ),
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
                        MediaGalleryScreen(clubId: dashboard.club.id),
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
    );
  }

  Widget _buildAcademiesList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CLUB BRANCHES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
              IconButton(onPressed: () => _showCreateAcademyDialog(context), icon: Icon(Icons.add_circle_outline, color: PremiumTheme.neonGreen)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dashboard.academies.length,
            itemBuilder: (context, index) {
              final academy = dashboard.academies[index];
              return PremiumCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AcademyManagementScreen(
                        academy: academy,
                        dashboard: dashboard,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_city, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(academy.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(academy.city, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white10),
                  ],
                ),
              );
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
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE TEAMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
              IconButton(onPressed: () => _showCreateTeamDialog(context), icon: Icon(Icons.add_circle_outline, color: PremiumTheme.neonGreen)),
            ],
          ),
        ),
        Expanded(
          child: dashboard.teams.isEmpty
              ? const Center(child: Text('No teams found', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dashboard.teams.length,
                  itemBuilder: (context, index) {
                    final team = dashboard.teams[index];
                    return PremiumCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamManagementScreen(
                              teamId: team.id,
                              clubId: dashboard.club.id,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.group, color: Colors.green, size: 20),
                              const SizedBox(width: 12),
                              Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('${team.academyName} | ${team.ageCategory}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTeamStatCompact('RATING', team.rating.toString(), Colors.amber),
                              _buildTeamStatCompact('WINS', team.wins.toString(), Colors.green),
                              _buildTeamStatCompact('LOSSES', team.losses.toString(), Colors.redAccent),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTeamStatCompact(String label, String value, Color color) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPlayersList(dynamic dashboard) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('LINKED PLAYERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
        ),
        ...dashboard.players.map((player) => PremiumCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: Colors.white10, child: const Icon(Icons.person, color: Colors.white70)),
            title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Pos: ${player.position ?? 'N/A'} | #: ${player.jerseyNumber ?? 'N/A'}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white10),
          ),
        )),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('UNLINKED PROFILES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
        ),
        ...dashboard.childProfiles.map((child) => PremiumCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: const Icon(Icons.person_outline, color: Colors.orange)),
            title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Status: Offline Profile', style: TextStyle(color: Colors.orange, fontSize: 10)),
            trailing: TextButton(onPressed: () {}, child: Text('Invite', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 12))),
          ),
        )),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCoachesList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('STAFF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
              IconButton(onPressed: () => _showInviteStaffDialog(context), icon: Icon(Icons.person_add_rounded, color: PremiumTheme.neonGreen)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dashboard.coaches.length,
            itemBuilder: (context, index) {
              final coach = dashboard.coaches[index];
              return PremiumCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.sports, color: Colors.white70)),
                  title: Text(coach.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Coach ID: ${coach.userId.substring(0, 8)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingInvitesList(dynamic dashboard) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: dashboard.pendingInvitations.length,
      itemBuilder: (context, index) {
        final invite = dashboard.pendingInvitations[index];
        return PremiumCard(
          child: Row(
            children: [
              const Icon(Icons.mail_outline_rounded, color: Colors.amber),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invite.role.toString().split('.').last.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('User ID: ${invite.invitedUserId.substring(0, 8)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              if (!invite.isApproved)
                TextButton(
                  onPressed: () => context.read<ClubProvider>().approveInvitation(invite.id),
                  child: Text('Approve', style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold)),
                )
              else
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        );
      },
    );
  }

  // Dialog methods preserved but could be styled later if needed
  void _showRequestClubDialog(BuildContext context) {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.cardNavy,
        title: const Text('Request Club Creation', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Club Name')),
              TextField(controller: cityController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: addressController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && cityController.text.isNotEmpty && addressController.text.isNotEmpty) {
                final success = await context.read<ClubProvider>().submitClubRequest({
                  'name': nameController.text, 'city': cityController.text, 'address': addressController.text,
                });
                if (success) Navigator.pop(context);
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
        backgroundColor: PremiumTheme.cardNavy,
        title: const Text('Add New Academy', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: cityController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'City')),
            TextField(controller: addressController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final clubId = context.read<ClubProvider>().dashboard?.club.id;
              if (clubId != null) {
                final success = await context.read<ClubProvider>().createAcademy(
                  clubId, nameController.text, cityController.text, addressController.text,
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
          backgroundColor: PremiumTheme.cardNavy,
          title: const Text('Create New Team', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: PremiumTheme.cardNavy,
                  initialValue: selectedAcademyId,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Academy'),
                  items: academies.map((a) => DropdownMenuItem(value: a.id.toString(), child: Text(a.name))).toList(),
                  onChanged: (val) => setDialogState(() => selectedAcademyId = val),
                ),
                TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Team Name')),
                TextField(controller: birthYearController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Birth Year'), keyboardType: TextInputType.number),
                TextField(controller: coachIdController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Coach User ID')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedAcademyId != null && nameController.text.isNotEmpty) {
                  final success = await context.read<ClubProvider>().createTeam(
                    selectedAcademyId!, nameController.text, int.parse(birthYearController.text), coachIdController.text,
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
