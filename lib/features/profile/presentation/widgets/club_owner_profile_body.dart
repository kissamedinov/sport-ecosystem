import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/features/clubs/data/models/club_dashboard.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/clubs/presentation/screens/team_management_screen.dart';
import 'package:mobile/features/clubs/presentation/screens/invite_member_screen.dart';
import 'package:mobile/features/academies/presentation/screens/academy_dashboard_screen.dart';

class ClubOwnerProfileBody extends StatefulWidget {
  const ClubOwnerProfileBody({super.key});

  @override
  State<ClubOwnerProfileBody> createState() => _ClubOwnerProfileBodyState();
}

class _ClubOwnerProfileBodyState extends State<ClubOwnerProfileBody> {
  final ProfileApiService _profileApi = ProfileApiService();
  late Future<ClubDashboard> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _profileApi.getClubDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClubDashboard>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
                  const SizedBox(height: 16),
                  Text("Loading dashboard...", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, letterSpacing: 1)),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text("Error: ${snapshot.error}", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        final dashboard = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSectionLabel("OPERATIONAL STATS"),
              const SizedBox(height: 12),
              _buildClubStats(dashboard),
              const SizedBox(height: 28),
              _buildSectionLabel("MONTHLY GROWTH"),
              const SizedBox(height: 12),
              _buildGrowthStats(dashboard),
              const SizedBox(height: 28),
              _buildSectionLabel("MANAGEMENT TEAM  •  ${dashboard.managersCount}"),
              const SizedBox(height: 12),
              _buildManagersList(dashboard),
              const SizedBox(height: 28),
              _buildSectionLabel("CLUB ROSTER  •  ${dashboard.playersCount}"),
              const SizedBox(height: 12),
              _buildPlayersList(dashboard),
              if (dashboard.academies.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildSectionLabel("ACADEMIES & BRANCHES"),
                const SizedBox(height: 12),
                _buildAcademiesList(dashboard),
              ],
              const SizedBox(height: 28),
              _buildSectionLabel("QUICK ACTIONS"),
              const SizedBox(height: 12),
              _buildActions(dashboard),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildClubStats(ClubDashboard dashboard) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard("Teams", "${dashboard.teams.length}", Icons.shield_rounded, PremiumTheme.electricBlue, subtitle: "ACTIVE"),
        _buildStatCard("Players", "${dashboard.playersCount}", Icons.sports_soccer_rounded, PremiumTheme.neonGreen, subtitle: "REGISTERED"),
        _buildStatCard("Coaches", "${dashboard.coachesCount}", Icons.sports_rounded, Colors.amber, subtitle: "ON STAFF"),
        _buildStatCard("Academies", "${dashboard.academies.length}", Icons.account_balance_rounded, Colors.purpleAccent, subtitle: "BRANCHES"),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              if (subtitle != null)
                Text(subtitle, style: TextStyle(fontSize: 8, color: color.withOpacity(0.7), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildGrowthStats(ClubDashboard dashboard) {
    final newCoaches = dashboard.statistics['new_coaches_30d'] ?? 0;
    final newPlayers = dashboard.statistics['new_players_30d'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildGrowthCard("New Coaches", "+$newCoaches", Colors.orangeAccent, Icons.trending_up_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGrowthCard("New Players", "+$newPlayers", PremiumTheme.neonGreen, Icons.trending_up_rounded),
        ),
      ],
    );
  }

  Widget _buildGrowthCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text("30D", style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildManagersList(ClubDashboard dashboard) {
    if (dashboard.managers.isEmpty) {
      return _buildEmptyState("No managers assigned", Icons.person_off_rounded);
    }

    final roles = ["Operations Director", "Sporting Director", "Technical Director", "Academy Director"];

    return Column(
      children: dashboard.managers.asMap().entries.map((entry) {
        final index = entry.key;
        final manager = entry.value;
        final initials = _getInitials(manager.name);
        final role = roles[index % roles.length];

        final onSurface = Theme.of(context).colorScheme.onSurface;
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: onSurface.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager.name,
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        role,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: muted, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  Widget _buildPlayersList(ClubDashboard dashboard) {
    if (dashboard.players.isEmpty) {
      return _buildEmptyState("No players in the roster", Icons.sports_soccer_outlined);
    }
    final displayPlayers = dashboard.players.length > 5 ? dashboard.players.take(5).toList() : dashboard.players;

    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      children: displayPlayers.map((player) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: onSurface.withValues(alpha: 0.07)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [PremiumTheme.neonGreen.withOpacity(0.8), PremiumTheme.neonGreen.withOpacity(0.4)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  player.jerseyNumber?.toString() ?? "#",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
            title: Text(player.name, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(player.position ?? "Player", style: TextStyle(color: muted, fontSize: 11)),
            trailing: Icon(Icons.chevron_right_rounded, color: muted, size: 20),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildAcademiesList(ClubDashboard dashboard) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dashboard.academies.length,
        itemBuilder: (context, index) {
          final academy = dashboard.academies[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AcademyDashboardScreen()),
              );
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [PremiumTheme.electricBlue.withOpacity(0.1), PremiumTheme.electricBlue.withOpacity(0.03)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PremiumTheme.electricBlue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.school_rounded, color: PremiumTheme.electricBlue, size: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(academy.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(academy.city, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions(ClubDashboard dashboard) {
    return Column(
      children: [
        _buildActionButton("Manage All Teams", Icons.settings_applications_rounded, PremiumTheme.electricBlue, () {
          if (dashboard.teams.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamManagementScreen(
                  team: dashboard.teams.first,
                  availableCoaches: dashboard.coaches,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No teams available to manage.")),
            );
          }
        }),
        const SizedBox(height: 10),
        _buildActionButton("Invite Professionals", Icons.person_add_rounded, PremiumTheme.neonGreen, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InviteMemberScreen(clubId: dashboard.club.id.toString()),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onSurface.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 24),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(color: muted, fontSize: 13)),
        ],
      ),
    );
  }
}
