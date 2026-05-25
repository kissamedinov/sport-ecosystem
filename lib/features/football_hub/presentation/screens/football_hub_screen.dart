import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/features/quiz/presentation/screens/daily_quiz_screen.dart';
import '../../../teams/presentation/screens/team_leaderboard_screen.dart';

class FootballHubScreen extends StatefulWidget {
  const FootballHubScreen({super.key});

  @override
  State<FootballHubScreen> createState() => _FootballHubScreenState();
}

class _FootballHubScreenState extends State<FootballHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'FOOTBALL HUB',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 108, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDailyChallengeCard(context),
              const SizedBox(height: 14),
              _buildStreakRow(context),
              const SizedBox(height: 28),
              _buildSectionLabel(context, 'SKILLS ARENA'),
              const SizedBox(height: 12),
              _buildSkillsGrid(context),
              const SizedBox(height: 28),
              _buildSectionLabel(context, 'GLOBAL RANKINGS'),
              const SizedBox(height: 12),
              _buildLeaderboardCard(context),
              const SizedBox(height: 28),
              _buildSectionLabel(context, 'TOP ACADEMIES'),
              const SizedBox(height: 12),
              _buildAcademiesList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
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

  Widget _buildDailyChallengeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glow = 0.05 * _pulseCtrl.value;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyQuizScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00E676).withValues(alpha: 0.16 + glow),
                        const Color(0xFF082210),
                        const Color(0xFF004020).withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00E676).withValues(alpha: 0.18 + glow),
                        const Color(0xFF00E676).withValues(alpha: 0.08),
                      ],
                    ),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.3 + glow),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.08 + glow),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF00E676), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAILY CHALLENGE',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Football Kick-Off',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '+7 PTS',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Answer 5 questions, beat your streak and\nclimb the global leaderboard today!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                SizedBox(width: 6),
                Text(
                  "START TODAY'S CHALLENGE",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStreakChip(
          icon: Icons.local_fire_department_rounded,
          value: '7',
          label: 'DAY STREAK',
          color: Colors.deepOrange,
        )),
        const SizedBox(width: 10),
        Expanded(child: _buildStreakChip(
          icon: Icons.stars_rounded,
          value: '142',
          label: 'TOTAL PTS',
          color: const Color(0xFF00E676),
        )),
        const SizedBox(width: 10),
        Expanded(child: _buildStreakChip(
          icon: Icons.emoji_events_rounded,
          value: '#24',
          label: 'WORLD RANK',
          color: Colors.amber,
        )),
      ],
    );
  }

  Widget _buildStreakChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsGrid(BuildContext context) {
    final skills = [
      _SkillItem('SHOOTING', Icons.sports_soccer_rounded,
          const Color(0xFF42A5F5), const Color(0xFF0D1B2A), 'POWER', 0.72),
      _SkillItem('DRIBBLING', Icons.directions_run_rounded,
          const Color(0xFF00E676), const Color(0xFF0A1F0A), 'AGILITY', 0.58),
      _SkillItem('PASSING', Icons.swap_horiz_rounded,
          const Color(0xFFFFA726), const Color(0xFF1A1200), 'VISION', 0.85),
      _SkillItem('DEFENDING', Icons.shield_rounded,
          const Color(0xFFCE93D8), const Color(0xFF1A001A), 'STRENGTH', 0.44),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: skills.map((s) => _SkillCard(skill: s)).toList(),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context) {
    final teams = [
      {'name': 'FC Barcelona Youth', 'pts': '87', 'rank': '1'},
      {'name': 'Real Madrid Academy', 'pts': '84', 'rank': '2'},
      {'name': 'Ajax Youth Squad', 'pts': '79', 'rank': '3'},
    ];
    final medalColors = [Colors.amber, Colors.grey.shade400, const Color(0xFFCD7F32)];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeamLeaderboardScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ...teams.asMap().entries.map((e) {
              final i = e.key;
              final t = e.value;
              final medal = medalColors[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: medal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: medal.withValues(alpha: 0.35)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t['rank']!,
                        style: TextStyle(
                          color: medal,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t['name']!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: medal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${t['pts']} PTS',
                        style: TextStyle(
                          color: medal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SEE FULL LEADERBOARD',
                  style: TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, color: PremiumTheme.neonGreen, size: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademiesList(BuildContext context) {
    final academies = [
      {'name': 'Real Madrid Academy', 'rating': '4.9', 'flag': '🇪🇸', 'players': '320'},
      {'name': 'Ajax Youth School', 'rating': '4.8', 'flag': '🇳🇱', 'players': '240'},
      {'name': 'Man City Academy', 'rating': '4.7', 'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'players': '280'},
    ];

    return Column(
      children: academies.asMap().entries.map((e) {
        final i = e.key;
        final a = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceCard(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: PremiumTheme.neonGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['name']!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${a['flag']} · ${a['players']} players',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      a['rating']!,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SkillItem {
  final String name;
  final IconData icon;
  final Color accent;
  final Color bg;
  final String badge;
  final double progress;

  const _SkillItem(this.name, this.icon, this.accent, this.bg, this.badge, this.progress);
}

class _SkillCard extends StatefulWidget {
  final _SkillItem skill;
  const _SkillCard({required this.skill});

  @override
  State<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<_SkillCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.skill;
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [s.bg, Colors.black.withValues(alpha: 0.25)]
                  : [s.accent.withValues(alpha: 0.14), s.accent.withValues(alpha: 0.05)],
            ),
            border: Border.all(
              color: s.accent.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: s.accent.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: s.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.icon, color: s.accent, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: s.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.badge,
                      style: TextStyle(
                        color: s.accent,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                s.name,
                style: TextStyle(
                  color: s.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.progress,
                  backgroundColor: s.accent.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(s.accent),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(s.progress * 100).toInt()}%',
                style: TextStyle(
                  color: s.accent.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
          },
        ),
      ),
    );
  }
}
