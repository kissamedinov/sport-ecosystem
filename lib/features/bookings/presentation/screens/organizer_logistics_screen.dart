import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/tournaments/presentation/screens/referee_search_screen.dart';

class OrganizerLogisticsScreen extends StatefulWidget {
  const OrganizerLogisticsScreen({super.key});

  @override
  State<OrganizerLogisticsScreen> createState() => _OrganizerLogisticsScreenState();
}

class _OrganizerLogisticsScreenState extends State<OrganizerLogisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: PremiumTheme.surfaceBase(context),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeaderBackground(),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: innerBoxIsScrolled 
                  ? const Text("LOGISTICS HUB", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2))
                  : null,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildLogisticsStats(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: _buildTabBar(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            const RefereeSearchScreen(),
            _buildVenuesTab(),
            _buildEquipmentTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "ORGANIZER TOOLS",
              style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Tournament\nLogistics Hub",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.1, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          _miniStat("12", "REFS", Icons.gavel_rounded, PremiumTheme.neonGreen),
          const SizedBox(width: 12),
          _miniStat("4", "VENUES", Icons.stadium_rounded, PremiumTheme.electricBlue),
          const SizedBox(width: 12),
          _miniStat("85%", "STAFF", Icons.verified_user_rounded, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white24, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: PremiumTheme.surfaceBase(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "REFEREES"),
            Tab(text: "VENUES"),
            Tab(text: "GEAR"),
          ],
        ),
      ),
    );
  }

  Widget _buildVenuesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildVenueCard("Central Olympic Stadium", "6 Full-size Fields", "PRIMARY"),
        _buildVenueCard("Downtown Soccer Park", "4 Mini Fields", "SECONDARY"),
        _buildVenueCard("Eastside Arena", "2 Indoor Fields", "BACKUP"),
      ],
    );
  }

  Widget _buildVenueCard(String name, String info, String tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.location_on_rounded, color: PremiumTheme.electricBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(info, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          _buildTag(tag),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildEquipmentTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, color: Colors.white.withValues(alpha: 0.05), size: 80),
          const SizedBox(height: 20),
          const Text("GEAR MANAGEMENT", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white12, letterSpacing: 2)),
          const Text("Coming in next update", style: TextStyle(color: Colors.white10, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
