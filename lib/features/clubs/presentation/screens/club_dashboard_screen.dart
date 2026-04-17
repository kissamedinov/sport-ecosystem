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
                          child: Icon(Icons.business_rounded, size: 180, color: Colors.white.withValues(alpha: 0.05)),
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
                                icon: Icons.account_balance_rounded,
                                color: PremiumTheme.electricBlue,
                              ),
                              PremiumStatCard(
                                title: 'Teams',
                                value: dashboard.teams.length.toString(),
                                icon: Icons.shield_rounded,
                                color: PremiumTheme.electricBlue,
                              ),
                              PremiumStatCard(
                                title: 'Players',
                                value: (dashboard.playersCount + dashboard.childProfiles.length).toString(),
                                icon: Icons.sports_soccer_rounded,
                                color: PremiumTheme.neonGreen,
                              ),
                              PremiumStatCard(
                                title: 'Coaches',
                                value: dashboard.coachesCount.toString(),
                                icon: Icons.sports_rounded,
                                color: PremiumTheme.neonGreen,
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

  // ───── Unified accent: electricBlue for all entity icons ─────

  Widget _buildAcademiesList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CLUB BRANCHES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
              IconButton(onPressed: () => _showCreateAcademyDialog(context), icon: const Icon(Icons.add_circle_outline, color: PremiumTheme.neonGreen)),
            ],
          ),
        ),
        Expanded(
          child: dashboard.academies.isEmpty
              ? _buildEmptyState(Icons.account_balance_rounded, 'NO ACADEMIES')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dashboard.academies.length,
                  itemBuilder: (context, index) {
                    final academy = dashboard.academies[index];
                    return PremiumCard(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AcademyManagementScreen(academy: academy, dashboard: dashboard),
                        ));
                      },
                      child: Row(
                        children: [
                          _buildEntityIcon(Icons.account_balance_rounded),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(academy.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                                    const SizedBox(width: 4),
                                    Text(academy.city, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
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
              IconButton(onPressed: () => _showCreateTeamDialog(context), icon: const Icon(Icons.add_circle_outline, color: PremiumTheme.neonGreen)),
            ],
          ),
        ),
        Expanded(
          child: dashboard.teams.isEmpty
              ? _buildEmptyState(Icons.shield_rounded, 'NO TEAMS')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dashboard.teams.length,
                  itemBuilder: (context, index) {
                    final team = dashboard.teams[index];
                    return PremiumCard(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => TeamManagementScreen(team: team, availableCoaches: dashboard.coaches),
                        ));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildEntityIcon(Icons.shield_rounded),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(team.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 3),
                                    Text('${team.academyName} • ${team.ageCategory}', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTeamStatCompact('RATING', team.rating.toString(), Colors.amber),
                                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.06)),
                                _buildTeamStatCompact('W', team.wins.toString(), PremiumTheme.neonGreen),
                                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.06)),
                                _buildTeamStatCompact('L', team.losses.toString(), Colors.redAccent),
                              ],
                            ),
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
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildPlayersList(dynamic dashboard) {
    final totalLinked = dashboard.players.length;
    final totalUnlinked = dashboard.childProfiles.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        // Stats summary
        Row(
          children: [
            Expanded(child: _buildMiniStatBox('TOTAL', '${totalLinked + totalUnlinked}', PremiumTheme.electricBlue)),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniStatBox('LINKED', '$totalLinked', PremiumTheme.neonGreen)),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniStatBox('UNLINKED', '$totalUnlinked', Colors.amber)),
          ],
        ),
        const SizedBox(height: 24),

        // Linked players
        _buildSectionHeader('LINKED PLAYERS', Icons.link_rounded),
        const SizedBox(height: 12),
        if (totalLinked == 0)
          _buildInlineEmpty('No linked players yet')
        else
          ...dashboard.players.map((player) => PremiumCard(
            child: Row(
              children: [
                _buildEntityIcon(Icons.sports_soccer_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (player.position != null) _buildInfoChip(player.position!),
                          if (player.jerseyNumber != null) ...[
                            const SizedBox(width: 6),
                            _buildInfoChip('#${player.jerseyNumber}'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
              ],
            ),
          )),

        const SizedBox(height: 24),
        _buildSectionHeader('UNLINKED PROFILES', Icons.link_off_rounded),
        const SizedBox(height: 12),
        if (totalUnlinked == 0)
          _buildInlineEmpty('No unlinked profiles')
        else
          ...dashboard.childProfiles.map((child) => PremiumCard(
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('OFFLINE', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('INVITE', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(child: _buildMiniStatBox('COACHES', '${dashboard.coaches.length}', PremiumTheme.electricBlue)),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStatBox('TEAMS', '${dashboard.teams.length}', PremiumTheme.neonGreen)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('COACHING STAFF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
              GestureDetector(
                onTap: () => _showInviteStaffDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, color: PremiumTheme.neonGreen, size: 14),
                      SizedBox(width: 6),
                      Text('ADD', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dashboard.coaches.isEmpty
              ? _buildEmptyState(Icons.sports_rounded, 'NO COACHES')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dashboard.coaches.length,
                  itemBuilder: (context, index) {
                    final coach = dashboard.coaches[index];
                    final coachTeams = dashboard.teams.where((t) => t.coachId == coach.userId).toList();
                    return PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildEntityIcon(Icons.sports_rounded),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(coach.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 3),
                                    Text('ID: ${coach.userId.substring(0, 8)}',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10, fontFamily: 'monospace')),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('COACH', style: TextStyle(
                                  color: PremiumTheme.electricBlue, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                                )),
                              ),
                            ],
                          ),
                          if (coachTeams.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      coachTeams.map((t) => t.name).join(', '),
                                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPendingInvitesList(dynamic dashboard) {
    if (dashboard.pendingInvitations.isEmpty) {
      return _buildEmptyState(Icons.hourglass_empty_rounded, 'NO PENDING INVITES');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: dashboard.pendingInvitations.length,
      itemBuilder: (context, index) {
        final invite = dashboard.pendingInvitations[index];
        return PremiumCard(
          child: Row(
            children: [
              _buildEntityIcon(Icons.send_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invite.role.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text('ID: ${invite.invitedUserId.substring(0, 8)}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
              ),
              if (!invite.isApproved)
                ElevatedButton(
                  onPressed: () => context.read<ClubProvider>().approveInvitation(invite.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: PremiumTheme.deepNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('APPROVE'),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: PremiumTheme.neonGreen, size: 14),
                      const SizedBox(width: 4),
                      const Text('DONE', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ───── Shared helper widgets ─────

  Widget _buildEntityIcon(IconData icon) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.15), width: 1),
      ),
      child: Icon(icon, color: PremiumTheme.electricBlue, size: 20),
    );
  }

  Widget _buildMiniStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: PremiumTheme.glassDecoration(radius: 12),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white24, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: PremiumTheme.electricBlue, size: 14),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PremiumTheme.electricBlue.withValues(alpha: 0.25), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PremiumTheme.electricBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: PremiumTheme.electricBlue, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildInlineEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 12)),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 14),
          Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.12),
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
          )),
        ],
      ),
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
