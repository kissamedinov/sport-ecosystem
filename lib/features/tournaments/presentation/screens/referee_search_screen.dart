import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class RefereeSearchScreen extends StatefulWidget {
  const RefereeSearchScreen({super.key});

  @override
  State<RefereeSearchScreen> createState() => _RefereeSearchScreenState();
}

class _RefereeSearchScreenState extends State<RefereeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Mock data for referees
  final List<Map<String, dynamic>> _referees = [
    {
      "name": "Ivan Ivanov",
      "rating": 4.8,
      "matches": 156,
      "status": "Available",
      "specialty": "Main Referee",
      "phone": "+7 701 222 33 44",
      "unavailable_dates": ["2026-05-02", "2026-05-03"]
    },
    {
      "name": "Sergey Petrov",
      "rating": 4.5,
      "matches": 89,
      "status": "Busy",
      "specialty": "Linesman",
      "phone": "+7 701 333 44 55",
      "unavailable_dates": ["2026-05-01"]
    },
    {
      "name": "Dmitry Sidorov",
      "rating": 4.9,
      "matches": 210,
      "status": "Available",
      "specialty": "VAR / Main",
      "phone": "+7 701 444 55 66",
      "unavailable_dates": []
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SEARCH REFEREES', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: PremiumTextField(
              controller: _searchController,
              label: "SEARCH BY NAME OR SKILL",
              icon: Icons.search_rounded,
            ),
          ),
          _buildFilterChips(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _referees.length,
              itemBuilder: (context, index) {
                return _buildRefereeCard(_referees[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _filterChip("All", true),
          _filterChip("Available", false),
          _filterChip("Top Rated", false),
          _filterChip("Linesman", false),
          _filterChip("VAR", false),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white70)),
        selected: isSelected,
        onSelected: (_) {},
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: PremiumTheme.neonGreen,
        checkmarkColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildRefereeCard(Map<String, dynamic> ref) {
    final bool isAvailable = ref["status"] == "Available";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 28),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(ref["name"]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref["name"].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(ref["rating"].toString(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text("${ref["matches"]} matches", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isAvailable),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn("SPECIALTY", ref["specialty"]),
              _buildInfoColumn("NEXT FREE", isAvailable ? "TODAY" : "03 MAY"),
              ElevatedButton(
                onPressed: () => _showInviteSheet(ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.neonGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('INVITE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(color: PremiumTheme.electricBlue, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (available ? PremiumTheme.neonGreen : Colors.redAccent).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        available ? "AVAILABLE" : "BUSY",
        style: TextStyle(
          color: available ? PremiumTheme.neonGreen : Colors.redAccent,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _showInviteSheet(Map<String, dynamic> ref) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SEND INVITATION", style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text("Inviting ${ref["name"]} for a match assignment.", style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            _buildPickerRow("MATCH DATE", "Select Date", Icons.calendar_month_rounded),
            const SizedBox(height: 12),
            _buildPickerRow("LOCATION", "Central Arena", Icons.location_on_rounded),
            const SizedBox(height: 32),
            PremiumButton(
              text: "SEND INVITE",
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("INVITATION SENT"), backgroundColor: PremiumTheme.neonGreen),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: PremiumTheme.neonGreen, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down_rounded, color: Colors.white38),
        ],
      ),
    );
  }
}
