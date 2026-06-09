import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class CoachAttendanceScreen extends StatefulWidget {
  final List teams;
  const CoachAttendanceScreen({super.key, this.teams = const []});

  @override
  State<CoachAttendanceScreen> createState() => _CoachAttendanceScreenState();
}

class _CoachAttendanceScreenState extends State<CoachAttendanceScreen> {
  String? _selectedTeamId;
  final Map<String, bool> _attendance = {};

  @override
  void initState() {
    super.initState();
    if (widget.teams.isNotEmpty) {
      _selectedTeamId = widget.teams.first['id']?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeam = widget.teams.firstWhere(
      (t) => t['id']?.toString() == _selectedTeamId,
      orElse: () => {},
    );
    final players = (selectedTeam['players'] as List?) ?? [];

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildTeamSelector()),
          if (players.isEmpty)
            _buildEmptyState()
          else
            _buildPlayerList(players),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSubmitBtn(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: PremiumTheme.surfaceBase(context),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'ATTENDANCE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        background: Builder(
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? [const Color(0xFF0D2A1A), PremiumTheme.surfaceBase(ctx)]
                      : [const Color(0xFFE8F5E9), PremiumTheme.surfaceBase(ctx)],
                ),
              ),
            );
          },
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTeamSelector() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.teams.length,
        itemBuilder: (context, index) {
          final team = widget.teams[index];
          final id = team['id']?.toString();
          final isSelected = id == _selectedTeamId;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTeamId = id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    team['name']?.toString().toUpperCase() ?? 'TEAM',
                    style: TextStyle(
                      color: isSelected ? Colors.black : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'NO PLAYERS IN THIS TEAM',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList(List players) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final player = players[index];
            final name = player['name']?.toString() ?? 'Player';
            final id = player['id']?.toString() ?? index.toString();
            final isPresent = _attendance[id] ?? false;
            final cs = Theme.of(context).colorScheme;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _attendance[id] = !isPresent);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: PremiumTheme.glassDecorationOf(context, radius: 16).copyWith(
                    border: Border.all(
                      color: isPresent ? PremiumTheme.neonGreen.withValues(alpha: 0.4) : cs.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPresent ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: TextStyle(
                              color: isPresent ? Colors.black : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPresent ? 'PRESENT' : 'ABSENT',
                              style: TextStyle(
                                color: isPresent ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isPresent ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: isPresent ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.08),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: players.length,
        ),
      ),
    );
  }

  Widget _buildSubmitBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ATTENDANCE SAVED SUCCESSFULLY'),
              backgroundColor: PremiumTheme.neonGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'SAVE ATTENDANCE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
