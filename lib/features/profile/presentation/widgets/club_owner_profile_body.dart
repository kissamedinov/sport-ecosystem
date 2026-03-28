import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/features/clubs/data/models/club_dashboard.dart';

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
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final dashboard = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("CLUB OVERVIEW"),
            _buildClubStats(dashboard),
            const SizedBox(height: 24),
            _buildSectionTitle("ACADEMIES & BRANCHES"),
            _buildAcademiesList(dashboard),
            const SizedBox(height: 24),
            _buildSectionTitle("ADMIN ACTIONS"),
            _buildActionCard(context, "Manage All Teams", Icons.settings_applications, Colors.indigo, () {}),
            _buildActionCard(context, "Invite Professionals", Icons.person_add, Colors.green, () {}),
            _buildActionCard(context, "Financial Reports", Icons.payments, Colors.amber, () {}),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildClubStats(ClubDashboard dashboard) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[900]!.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("TEAMS", "${dashboard.teams.length}", Colors.blue),
          _buildStatItem("PLAYERS", "${dashboard.playersCount}", Colors.green),
          _buildStatItem("COACHES", "${dashboard.coachesCount}", Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAcademiesList(ClubDashboard dashboard) {
    if (dashboard.academies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text("No academies registered.", style: TextStyle(color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: dashboard.academies.length,
        itemBuilder: (context, index) {
          final academy = dashboard.academies[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, color: Colors.indigoAccent, size: 24),
                const SizedBox(height: 12),
                Text(academy.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                Text(academy.city, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
