import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/player_profile.dart';
import '../../data/repositories/player_repository.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String userId;
  final String? displayName;

  const PlayerProfileScreen({
    super.key,
    required this.userId,
    this.displayName,
  });

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlayerProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = context.read<PlayerRepository>();
      final profile = await repo.getPlayerProfile(widget.userId);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final profile = _profile!;
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 220,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(profile),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.orangeAccent,
            tabs: const [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'CAREER STATS'),
              Tab(text: 'AWARDS'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(profile),
          _buildCareerStatsTab(profile),
          _buildAwardsTab(profile),
        ],
      ),
    );
  }

  Widget _buildHeader(PlayerProfile profile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.shade900,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 64),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.orangeAccent,
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (profile.preferredPosition != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        profile.preferredPosition!,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      final ids = '${profile.userId ?? 'N/A'} | ${profile.id}';
                      Clipboard.setData(ClipboardData(text: ids));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('IDs copied to clipboard'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: Text(
                      'User: ${profile.userId?.substring(0, 8) ?? 'N/A'}... | Prof: ${profile.id.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _headerStat('${profile.careerGoals}', '⚽ Goals'),
                      const SizedBox(width: 20),
                      _headerStat('${profile.careerAssists}', '🅰️ Assists'),
                      const SizedBox(width: 20),
                      _headerStat('${profile.awards.length}', '🏆 Awards'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildOverviewTab(PlayerProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Personal Info'),
        _infoCard([
          _infoRow(Icons.person, 'Name', profile.name),
          if (profile.dateOfBirth != null)
            _infoRow(Icons.cake, 'Date of Birth', profile.dateOfBirth!),
          if (profile.preferredPosition != null)
            _infoRow(
                Icons.sports_soccer, 'Position', profile.preferredPosition!),
          if (profile.dominantFoot != null)
            _infoRow(Icons.directions_run, 'Dominant Foot',
                profile.dominantFoot!.toUpperCase()),
          if (profile.height != null)
            _infoRow(Icons.height, 'Height', profile.height!),
          if (profile.weight != null)
            _infoRow(Icons.monitor_weight, 'Weight', profile.weight!),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('Career Summary'),
        _statsGridCard(profile),
      ],
    );
  }

  Widget _buildCareerStatsTab(PlayerProfile profile) {
    if (profile.tournamentStats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No tournament stats yet', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Overall totals row
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Career Totals'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBadge('${profile.careerMatchesPlayed}', 'Matches'),
                _statBadge('${profile.careerGoals}', '⚽ Goals'),
                _statBadge('${profile.careerAssists}', '🅰️ Assists'),
                _statBadge('${profile.careerYellowCards}', '🟨 Yellow'),
                _statBadge('${profile.careerRedCards}', '🟥 Red'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('By Tournament'),
        ...profile.tournamentStats.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final s = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.2),
                child: Text('T$i',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent)),
              ),
              title: Text(
                  'Division ${s.divisionId.substring(0, 8).toUpperCase()}'),
              subtitle: Wrap(
                spacing: 12,
                children: [
                  _miniStat('${s.matchesPlayed}', 'MP'),
                  _miniStat('${s.goals}', '⚽'),
                  _miniStat('${s.assists}', '🅰️'),
                  _miniStat('${s.yellowCards}', '🟨'),
                  _miniStat('${s.redCards}', '🟥'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAwardsTab(PlayerProfile profile) {
    if (profile.awards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text('No awards yet', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),
              Text(
                'Keep playing to earn tournament medals and titles!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('${profile.awards.length} Award${profile.awards.length > 1 ? 's' : ''} Earned'),
        ...profile.awards.map((award) => _buildAwardCard(award)),
      ],
    );
  }

  Widget _buildAwardCard(PlayerAward award) {
    final icon = award.title.toLowerCase().contains('golden')
        ? '🥇'
        : award.title.toLowerCase().contains('silver')
            ? '🥈'
            : award.title.toLowerCase().contains('mvp')
                ? '⭐'
                : '🏆';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 32)),
        title: Text(
          award.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (award.description != null && award.description!.isNotEmpty)
              Text(award.description!),
            if (award.createdAt != null)
              Text(
                award.createdAt!.year.toString(),
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        isThreeLine: award.description != null,
      ),
    );
  }

  Widget _statsGridCard(PlayerProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _statBox('${profile.careerMatchesPlayed}', 'Matches Played',
                        Icons.sports_soccer)),
                const SizedBox(width: 8),
                Expanded(
                    child: _statBox(
                        '${profile.careerGoals}', 'Goals', Icons.sports_soccer)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _statBox(
                        '${profile.careerAssists}', 'Assists', Icons.assist_walker)),
                const SizedBox(width: 8),
                Expanded(
                    child: _statBox('${profile.awards.length}', 'Awards', Icons.emoji_events)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2)),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold,
                color: Colors.orangeAccent)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _miniStat(String value, String label) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        children: [
          TextSpan(
              text: value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          TextSpan(text: ' $label'),
        ],
      ),
    );
  }
}
