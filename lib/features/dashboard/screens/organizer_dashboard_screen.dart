import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';

class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrimaryAction(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader("OPERATIONAL OVERVIEW"),
                  const SizedBox(height: 16),
                  _buildStatsGrid(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader("PENDING APPROVALS"),
                  const SizedBox(height: 12),
                  _buildApprovalList(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader("UPCOMING DEADLINES"),
                  const SizedBox(height: 12),
                  _buildDeadlinesTimeline(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: PremiumTheme.surfaceBase(context),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          "ORGANIZER HUB",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PremiumTheme.neonGreen.withValues(alpha: 0.05), Colors.transparent],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PremiumTheme.neonGreen, Color(0xFFADFF2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Launch Tournament",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  "Start your next big event",
                  style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 14),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 2),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        _statCard(context, "ACTIVE", "3", "TOURNAMENTS", Icons.emoji_events_rounded, PremiumTheme.electricBlue),
        const SizedBox(width: 12),
        _statCard(context, "TOTAL", "48", "TEAMS", Icons.group_rounded, Colors.purpleAccent),
      ],
    );
  }

  Widget _statCard(BuildContext context, String tag, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(tag, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalList(BuildContext context) {
    return Column(
      children: [
        _approvalItem(context, "FC Barcelona U-17", "Spring Cup 2024", "2h ago"),
        _approvalItem(context, "Almaty Lions", "Weekend League", "5h ago"),
      ],
    );
  }

  Widget _approvalItem(BuildContext context, String team, String tournament, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.assignment_ind_rounded, color: Colors.white38, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(tournament, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.neonGreen,
              foregroundColor: Colors.black,
              minimumSize: const Size(60, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("VIEW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesTimeline(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
      child: Column(
        children: [
          _deadlineRow("Registration Close", "Winter League", "Today, 23:59", Colors.redAccent),
          const Divider(color: Colors.white10, height: 32),
          _deadlineRow("Final Payment", "Summer Open", "In 2 days", Colors.amberAccent),
        ],
      ),
    );
  }

  Widget _deadlineRow(String title, String event, String time, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(event, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        Text(time, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
      ],
    );
  }
}
