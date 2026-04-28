import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/child_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/features/academies/providers/academy_provider.dart';
import 'package:mobile/features/children/presentation/widgets/activity_calendar_widget.dart';

class ChildrenActivityScreen extends StatefulWidget {
  final String? childId;
  final String? childName;

  const ChildrenActivityScreen({
    super.key, 
    this.childId, 
    this.childName
  });

  @override
  State<ChildrenActivityScreen> createState() => _ChildrenActivityScreenState();
}

class _ChildrenActivityScreenState extends State<ChildrenActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childProvider = context.read<ChildProvider>();
      final academyProvider = context.read<AcademyProvider>();
      
      if (widget.childId != null) {
        childProvider.fetchActivities(widget.childId!);
        childProvider.fetchAwards(widget.childId!);
        academyProvider.fetchActivitiesForParent([widget.childId!]);
      } else {
        childProvider.fetchChildren().then((_) {
          if (childProvider.children.isNotEmpty) {
            final firstChildId = childProvider.children.first.id;
            childProvider.fetchActivities(firstChildId);
            childProvider.fetchAwards(firstChildId);
            academyProvider.fetchActivitiesForParent([firstChildId]);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();
    final academyProvider = context.watch<AcademyProvider>();
    final displayName = widget.childName ?? (childProvider.children.isNotEmpty ? childProvider.children.first.name : 'CHILD');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '${displayName.toUpperCase()}\'S HUB',
            style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          bottom: const TabBar(
            indicatorColor: PremiumTheme.neonGreen,
            labelColor: PremiumTheme.neonGreen,
            unselectedLabelColor: Colors.white38,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 10),
            tabs: [
              Tab(text: 'CALENDAR'),
              Tab(text: 'PERFORMANCE'),
              Tab(text: 'AWARDS'),
            ],
          ),
        ),
        body: childProvider.isLoading || academyProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen))
            : TabBarView(
                children: [
                  _buildCalendarTab(academyProvider, childProvider),
                  _buildPerformanceTab(academyProvider, widget.childId),
                  _buildAwardsList(childProvider.awards),
                ],
              ),
      ),
    );
  }

  Widget _buildCalendarTab(AcademyProvider academyProvider, ChildProvider childProvider) {
    // Combine academy sessions and matches
    final allActivities = [
      ...academyProvider.sessions,
      // Convert matches to a similar structure if needed, or update widget to handle both
    ];

    return ActivityCalendarWidget(
      activities: allActivities,
      onDateSelected: (date) {
        // Handle date selection if needed
      },
    );
  }

  Widget _buildPerformanceTab(AcademyProvider academyProvider, String? childId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ATTENDANCE RATE',
            style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceCard(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('85%', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 32, fontWeight: FontWeight.w900)),
                    Text('PRESENT', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    value: 0.85,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: PremiumTheme.neonGreen,
                    strokeWidth: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'BILLING SUMMARY',
            style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PremiumTheme.surfaceCard(context), Colors.blue.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Owed (April)', style: TextStyle(color: Colors.white70)),
                    Text('45,000 KZT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Placeholder for payment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment gateway coming soon')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsList(List<Map<String, dynamic>> awards) {
    if (awards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: Colors.white10, size: 64),
            const SizedBox(height: 16),
            const Text('No awards yet', style: TextStyle(color: Colors.white24)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: awards.length,
      itemBuilder: (context, index) {
        final award = awards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceCard(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      award['award_type'] ?? 'Achievement',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      award['tournament_name'] ?? 'Regional Cup',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                award['awarded_at']?.split('T')?.first ?? '2024',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}
