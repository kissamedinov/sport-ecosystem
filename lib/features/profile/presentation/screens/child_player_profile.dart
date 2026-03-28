import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/models/user.dart';
import '../../../player_stats/providers/player_stats_provider.dart';
import '../../../teams/providers/team_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';

class ChildPlayerProfile extends StatefulWidget {
  final User user;
  const ChildPlayerProfile({super.key, required this.user});

  @override
  State<ChildPlayerProfile> createState() => _ChildPlayerProfileState();
}

class _ChildPlayerProfileState extends State<ChildPlayerProfile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchMyParents();
      context.read<TeamProvider>().fetchMyTeams();
    });
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.user.dateOfBirth ?? DateTime(2010),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PremiumTheme.electricBlue,
              onPrimary: Colors.white,
              surface: PremiumTheme.cardNavy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final authProvider = context.read<AuthProvider>();
      final isSelf = authProvider.user?.id == widget.user.id;
      
      bool success;
      if (isSelf) {
        success = await authProvider.updateProfile({
          'date_of_birth': picked.toIso8601String().split('T')[0],
        });
      } else {
        success = await authProvider.updateUserProfile(widget.user.id, {
          'date_of_birth': picked.toIso8601String().split('T')[0],
        });
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          // If we are viewing self, AuthProvider already updated _user
          // If we are viewing a child as parent, we might want to refresh.
          if (!isSelf) {
            // Re-fetch parent data or child data if needed
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${authProvider.error}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50, 
            backgroundColor: PremiumTheme.electricBlue,
            child: Icon(Icons.face, size: 50, color: Colors.white)
          ),
          const SizedBox(height: 16),
          Text(widget.user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('YOUTH PLAYER', style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildIdBadge(context, 'USER ID', widget.user.id),
          if (widget.user.playerProfileId != null) ...[
            const SizedBox(height: 8),
            _buildIdBadge(context, 'PROFILE ID', widget.user.playerProfileId!),
          ],
          const SizedBox(height: 32),
          _buildStatsRow(context),
          const SizedBox(height: 32),
          _buildMyTeamsSection(context),
          const SizedBox(height: 24),
          _buildMyFamilySection(context),
          const SizedBox(height: 32),
          _buildLogoutCard(context),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onTap: () async {
          await context.read<AuthProvider>().logout();
        },
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final stats = context.watch<PlayerStatsProvider>().getCareerStats(widget.user.id);
    final user = widget.user.id == context.watch<AuthProvider>().user?.id 
        ? context.watch<AuthProvider>().user! 
        : widget.user;

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () => _selectBirthday(context),
              child: _buildStatItem('Age', _calculateAge(user.dateOfBirth).toString()),
            ),
            _buildStatItem('Matches', stats.matchesPlayed.toString()),
            _buildStatItem('Goals', stats.totalGoals.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMyTeamsSection(BuildContext context) {
    final teams = context.watch<TeamProvider>().myTeams;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text('MY TEAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 2)),
        ),
        if (teams.isEmpty)
          const PremiumCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Not assigned to a team yet', style: TextStyle(color: Colors.white54)),
              ),
            ),
          )
        else
          ...teams.map((team) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: PremiumCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PremiumTheme.electricBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, color: PremiumTheme.electricBlue, size: 20),
                ),
                title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Active Roster', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 12)),
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildMyFamilySection(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final parents = authProvider.myParents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text('MY FAMILY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 2)),
        ),
        if (authProvider.isLoading && parents.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (parents.isEmpty)
          const PremiumCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No parents linked yet', style: TextStyle(color: Colors.white54)),
              ),
            ),
          )
        else
          ...parents.map((parent) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: PremiumCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.family_restroom, color: Colors.orange, size: 20),
                ),
                title: Text(parent['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Parent / Guardian', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildIdBadge(BuildContext context, String label, String id) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
          SelectableText(
            id,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.blueGrey[900],
                ),
              );
            },
            child: const Icon(Icons.copy, size: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
