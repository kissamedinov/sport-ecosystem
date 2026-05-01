import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../../../core/api/profile_api_service.dart';

class RefereeSearchScreen extends StatefulWidget {
  const RefereeSearchScreen({super.key});

  @override
  State<RefereeSearchScreen> createState() => _RefereeSearchScreenState();
}

class _RefereeSearchScreenState extends State<RefereeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProfileApiService _apiService = ProfileApiService();
  
  List<Map<String, dynamic>> _allReferees = [];
  List<Map<String, dynamic>> _filteredReferees = [];
  bool _isLoading = true;
  String _error = '';
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchReferees();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReferees() async {
    try {
      final refs = await _apiService.getReferees();
      setState(() {
        _allReferees = refs.map((ref) => {
          ...ref,
          "rating": ref["rating"] ?? (4.0 + (refs.indexOf(ref) % 10) / 10),
          "matches": ref["matches"] ?? (50 + refs.indexOf(ref) * 12),
          "specialty": ref["bio"] ?? "Certified Referee",
          "status": refs.indexOf(ref) % 3 == 0 ? "Busy" : "Available",
          "experience": "8+ Years",
        }).toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredReferees = _allReferees.where((ref) {
        final matchesSearch = ref["name"].toString().toLowerCase().contains(query);
        
        bool matchesFilter = true;
        if (_activeFilter == 'Available') {
          matchesFilter = ref["status"] == 'Available';
        } else if (_activeFilter == 'Top Rated') {
          matchesFilter = (ref["rating"] as num) >= 4.7;
        } else if (_activeFilter == 'VAR') {
          matchesFilter = ref["specialty"].toString().contains('VAR');
        } else if (_activeFilter == 'Main') {
          matchesFilter = ref["specialty"].toString().contains('Main') || ref["specialty"].toString().contains('Certified');
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _updateFilter(String filter) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeFilter = filter;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
    }

    return Column(
      children: [
        _buildSearchRow(),
        _buildFilterChips(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchReferees,
            color: PremiumTheme.neonGreen,
            backgroundColor: const Color(0xFF1A1A1A),
            child: _filteredReferees.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _filteredReferees.length,
                  itemBuilder: (context, index) {
                    return _buildRefereeCard(_filteredReferees[index]);
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView( // Needs to be scrollable for RefreshIndicator
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, color: Colors.white10, size: 64),
              const SizedBox(height: 16),
              Text("No referees found for \"$_activeFilter\"", style: const TextStyle(color: Colors.white24, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _searchController.text.isNotEmpty ? PremiumTheme.neonGreen.withValues(alpha: 0.3) : Colors.white10),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search by name...",
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchController.clear())
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(Icons.tune_rounded, () {
            HapticFeedback.mediumImpact();
          }),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: PremiumTheme.neonGreen, size: 20),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _filterChip("All"),
          _filterChip("Available"),
          _filterChip("Top Rated"),
          _filterChip("VAR"),
          _filterChip("Main"),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final bool isSelected = _activeFilter == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white70)),
        selected: isSelected,
        onSelected: (_) => _updateFilter(label),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: PremiumTheme.neonGreen,
        checkmarkColor: Colors.black,
        showCheckmark: isSelected,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRefereeCard(Map<String, dynamic> ref) {
    final bool isAvailable = ref["status"] == "Available";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInviteSheet(ref),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildAvatar(ref["name"]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ref["name"], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(ref["specialty"].toString().toUpperCase(), style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    _buildStatusPill(isAvailable),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol("RATING", "⭐ ${ref["rating"]}"),
                    _buildStatCol("MATCHES", ref["matches"].toString()),
                    _buildStatCol("EXP", ref["experience"]),
                    _buildQuickActions(ref["phone"].toString()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
    );
  }

  Widget _buildStatusPill(bool available) {
    final color = available ? PremiumTheme.neonGreen : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        available ? "READY" : "BUSY",
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildQuickActions(String phone) {
    return Row(
      children: [
        _circleIcon(Icons.phone_rounded, () => launchUrl(Uri.parse("tel:$phone"))),
        const SizedBox(width: 8),
        _circleIcon(Icons.chat_bubble_rounded, () => launchUrl(Uri.parse("sms:$phone"))),
      ],
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: Colors.white70),
      ),
    );
  }

  void _showInviteSheet(Map<String, dynamic> ref) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildAvatar(ref["name"]),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SEND ASSIGNMENT", style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                    Text(ref["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildActionInput("SELECT MATCH", "Champions League Final", Icons.sports_soccer_rounded),
            const SizedBox(height: 12),
            _buildActionInput("DATE & TIME", "Tomorrow, 18:00", Icons.access_time_filled_rounded),
            const SizedBox(height: 40),
            PremiumButton(
              text: "SEND OFFICIAL INVITE",
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("INVITATION DISPATCHED"), backgroundColor: PremiumTheme.neonGreen),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionInput(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: PremiumTheme.neonGreen, size: 18),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }
}
