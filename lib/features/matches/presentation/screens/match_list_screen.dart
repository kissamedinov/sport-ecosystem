import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../tournaments/data/models/tournament_match.dart';
import 'match_details_screen.dart';

class LobbyMatch {
  final String id;
  final String organizerName;
  final String organizerAvatar;
  final String location;
  final String time;
  final String date;
  final double price;
  final String format;
  final int maxPlayers;
  final List<String> joinedPlayers;
  final bool isPlus;

  LobbyMatch({
    required this.id,
    required this.organizerName,
    required this.organizerAvatar,
    required this.location,
    required this.time,
    required this.date,
    required this.price,
    required this.format,
    required this.maxPlayers,
    required this.joinedPlayers,
    this.isPlus = false,
  });

  LobbyMatch copyWith({
    List<String>? joinedPlayers,
  }) {
    return LobbyMatch(
      id: id,
      organizerName: organizerName,
      organizerAvatar: organizerAvatar,
      location: location,
      time: time,
      date: date,
      price: price,
      format: format,
      maxPlayers: maxPlayers,
      joinedPlayers: joinedPlayers ?? this.joinedPlayers,
      isPlus: isPlus,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizerName': organizerName,
    'organizerAvatar': organizerAvatar,
    'location': location,
    'time': time,
    'date': date,
    'price': price,
    'format': format,
    'maxPlayers': maxPlayers,
    'joinedPlayers': joinedPlayers,
    'isPlus': isPlus,
  };

  factory LobbyMatch.fromJson(Map<String, dynamic> json) => LobbyMatch(
    id: json['id'] as String,
    organizerName: json['organizerName'] as String,
    organizerAvatar: json['organizerAvatar'] as String,
    location: json['location'] as String,
    time: json['time'] as String,
    date: json['date'] as String,
    price: (json['price'] as num).toDouble(),
    format: json['format'] as String,
    maxPlayers: json['maxPlayers'] as int,
    joinedPlayers: List<String>.from(json['joinedPlayers'] as List),
    isPlus: json['isPlus'] as bool? ?? false,
  );
}

class PlayerMiniStats {
  final String name;
  final String avatar;
  final String position;
  final int rating;
  final int matchesPlayed;
  final int goals;
  final int assists;
  final int mvpCount;
  final double winRate;
  final String preferredFoot;
  final double form;
  final int age;

  PlayerMiniStats({
    required this.name,
    required this.avatar,
    required this.position,
    required this.rating,
    required this.matchesPlayed,
    required this.goals,
    required this.assists,
    required this.mvpCount,
    required this.winRate,
    required this.preferredFoot,
    required this.form,
    required this.age,
  });
}

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  late List<LobbyMatch> _lobbies;

  // Pre-configured mock stats for specific players
  final Map<String, PlayerMiniStats> _playerStatsMock = {
    'Maksat K.': PlayerMiniStats(
      name: 'Maksat K.',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop',
      position: 'FORWARD',
      rating: 85,
      matchesPlayed: 42,
      goals: 28,
      assists: 14,
      mvpCount: 8,
      winRate: 66.7,
      preferredFoot: 'Right',
      form: 92,
      age: 24,
    ),
    'Yernar S.': PlayerMiniStats(
      name: 'Yernar S.',
      avatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&auto=format&fit=crop',
      position: 'MIDFIELDER',
      rating: 81,
      matchesPlayed: 35,
      goals: 10,
      assists: 22,
      mvpCount: 4,
      winRate: 58.3,
      preferredFoot: 'Left',
      form: 88,
      age: 22,
    ),
    'Daulet A.': PlayerMiniStats(
      name: 'Daulet A.',
      avatar: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100&auto=format&fit=crop',
      position: 'DEFENDER',
      rating: 88,
      matchesPlayed: 50,
      goals: 2,
      assists: 6,
      mvpCount: 6,
      winRate: 72.0,
      preferredFoot: 'Right',
      form: 95,
      age: 26,
    ),
    'Arman T.': PlayerMiniStats(
      name: 'Arman T.',
      avatar: 'https://images.unsplash.com/photo-1489980508314-941910ded1f4?w=100&auto=format&fit=crop',
      position: 'GOALKEEPER',
      rating: 83,
      matchesPlayed: 28,
      goals: 0,
      assists: 1,
      mvpCount: 3,
      winRate: 54.5,
      preferredFoot: 'Right',
      form: 85,
      age: 25,
    ),
    'Kairat B.': PlayerMiniStats(
      name: 'Kairat B.',
      avatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&auto=format&fit=crop',
      position: 'MIDFIELDER',
      rating: 79,
      matchesPlayed: 20,
      goals: 4,
      assists: 8,
      mvpCount: 1,
      winRate: 50.0,
      preferredFoot: 'Right',
      form: 80,
      age: 23,
    ),
    'Alibek Z.': PlayerMiniStats(
      name: 'Alibek Z.',
      avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&auto=format&fit=crop',
      position: 'FORWARD',
      rating: 82,
      matchesPlayed: 30,
      goals: 18,
      assists: 9,
      mvpCount: 5,
      winRate: 60.0,
      preferredFoot: 'Left',
      form: 90,
      age: 21,
    ),
    'Sanzhar M.': PlayerMiniStats(
      name: 'Sanzhar M.',
      avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&auto=format&fit=crop',
      position: 'DEFENDER',
      rating: 78,
      matchesPlayed: 18,
      goals: 1,
      assists: 2,
      mvpCount: 0,
      winRate: 44.4,
      preferredFoot: 'Right',
      form: 75,
      age: 19,
    ),
    'Baurzhan K.': PlayerMiniStats(
      name: 'Baurzhan K.',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop',
      position: 'MIDFIELDER',
      rating: 84,
      matchesPlayed: 40,
      goals: 12,
      assists: 18,
      mvpCount: 5,
      winRate: 65.0,
      preferredFoot: 'Right',
      form: 91,
      age: 27,
    ),
  };

  PlayerMiniStats _getOrCreateStats(String name) {
    if (_playerStatsMock.containsKey(name)) {
      return _playerStatsMock[name]!;
    }
    
    // Hash the name to create consistent random mock stats
    final int hash = name.hashCode;
    final int rating = 70 + (hash.abs() % 20); // 70 to 89
    final int matches = 10 + (hash.abs() % 40); // 10 to 49
    final List<String> positions = ['FORWARD', 'MIDFIELDER', 'DEFENDER', 'GOALKEEPER'];
    final String pos = positions[hash.abs() % positions.length];
    
    int goals = 0;
    int assists = 0;
    if (pos == 'FORWARD') {
      goals = (matches * 0.4 + (hash.abs() % 10)).toInt();
      assists = (matches * 0.2 + (hash.abs() % 5)).toInt();
    } else if (pos == 'MIDFIELDER') {
      goals = (matches * 0.15 + (hash.abs() % 5)).toInt();
      assists = (matches * 0.35 + (hash.abs() % 10)).toInt();
    } else if (pos == 'DEFENDER') {
      goals = (hash.abs() % 3);
      assists = (matches * 0.1 + (hash.abs() % 4)).toInt();
    }
    
    final int mvp = (matches * 0.12).toInt();
    final double winRate = 45.0 + (hash.abs() % 25); // 45% to 70%
    final String foot = (hash % 3 == 0) ? 'Left' : 'Right';
    final double form = 80.0 + (hash.abs() % 18); // 80% to 98%
    final int age = 18 + (hash.abs() % 15); // 18 to 32
    
    final List<String> avatars = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&auto=format&fit=crop',
    ];
    final String avatarUrl = avatars[hash.abs() % avatars.length];

    return PlayerMiniStats(
      name: name,
      avatar: avatarUrl,
      position: pos,
      rating: rating,
      matchesPlayed: matches,
      goals: goals,
      assists: assists,
      mvpCount: mvp,
      winRate: double.parse(winRate.toStringAsFixed(1)),
      preferredFoot: foot,
      form: form,
      age: age,
    );
  }

  @override
  void initState() {
    super.initState();
    _lobbies = [];
    _loadLobbies();
  }

  List<LobbyMatch> _getDefaultLobbies() {
    return [
      LobbyMatch(
        id: 'lobby_1',
        organizerName: 'Medina Club',
        organizerAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&auto=format&fit=crop',
        location: 'Medina Pitch 1 - Almaty, Kazakhstan',
        time: '19:00 - 21:00',
        date: 'Wed, Jun 3',
        price: 2000,
        format: '5 vs 5',
        maxPlayers: 15,
        joinedPlayers: ['Maksat K.', 'Yernar S.', 'Daulet A.', 'Arman T.', 'Kairat B.'],
      ),
      LobbyMatch(
        id: 'lobby_2',
        organizerName: 'Gagarina Arena',
        organizerAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop',
        location: 'Gagarina 135a - Almaty, Kazakhstan',
        time: '19:45 - 22:00',
        date: 'Wed, Jun 3',
        price: 2800,
        format: '6 vs 6',
        maxPlayers: 18,
        joinedPlayers: List.generate(18, (i) => 'Player $i'),
        isPlus: true,
      ),
      LobbyMatch(
        id: 'lobby_3',
        organizerName: 'Jarys Arena',
        organizerAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop',
        location: 'Jarys Arena Pitch 1 - Almaty, Kazakhstan',
        time: '21:00 - 23:00',
        date: 'Wed, Jun 3',
        price: 3500,
        format: '6 vs 6',
        maxPlayers: 18,
        joinedPlayers: List.generate(17, (i) => 'Player $i'),
        isPlus: true,
      ),
      LobbyMatch(
        id: 'lobby_4',
        organizerName: 'Jarys Arena',
        organizerAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop',
        location: 'Jarys Arena Pitch 2 - Almaty, Kazakhstan',
        time: '21:00 - 23:00',
        date: 'Wed, Jun 3',
        price: 3500,
        format: '6 vs 6',
        maxPlayers: 18,
        joinedPlayers: ['Alibek Z.', 'Sanzhar M.', 'Baurzhan K.'],
      ),
      LobbyMatch(
        id: 'lobby_5',
        organizerName: 'Almaty Arena',
        organizerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop',
        location: 'Almaty Arena Stadium - Almaty, Kazakhstan',
        time: '21:30 - 23:30',
        date: 'Wed, Jun 3',
        price: 2300,
        format: '11 vs 11',
        maxPlayers: 22,
        joinedPlayers: List.generate(17, (i) => 'Player $i'),
        isPlus: true,
      ),
      LobbyMatch(
        id: 'lobby_6',
        organizerName: 'Heylebery Pitch',
        organizerAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&auto=format&fit=crop',
        location: 'Heylebery School Field - Almaty, Kazakhstan',
        time: '21:45 - 23:45',
        date: 'Wed, Jun 3',
        price: 3000,
        format: '7 vs 7',
        maxPlayers: 21,
        joinedPlayers: List.generate(14, (i) => 'Player $i'),
        isPlus: true,
      ),
    ];
  }

  Future<void> _loadLobbies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? saved = prefs.getStringList('lobby_matches');
      if (saved != null && saved.isNotEmpty) {
        setState(() {
          _lobbies = saved.map((s) => LobbyMatch.fromJson(jsonDecode(s))).toList();
        });
      } else {
        setState(() {
          _lobbies = _getDefaultLobbies();
        });
        await _saveLobbies();
      }
    } catch (e) {
      debugPrint("Error loading lobbies: $e");
      setState(() {
        _lobbies = _getDefaultLobbies();
      });
    }
  }

  Future<void> _saveLobbies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> encoded = _lobbies.map((l) => jsonEncode(l.toJson())).toList();
      await prefs.setStringList('lobby_matches', encoded);
    } catch (e) {
      debugPrint("Error saving lobbies: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.roles?.first.toUpperCase() ?? 'PLAYER_ADULT';
    final isAdultPlayer = role == 'PLAYER_ADULT' || role == 'USER' || (!['PARENT', 'COACH', 'FIELD_OWNER'].contains(role));

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getTitleForRole(role),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: isAdultPlayer 
          ? ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              itemCount: _lobbies.length,
              itemBuilder: (context, index) {
                return _buildLobbyCard(context, _lobbies[index]);
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              itemCount: 8,
              itemBuilder: (context, index) {
                final isLive = index < 3;
                final isMyTeam = index % 3 == 0;
                
                return _buildMatchCard(context, index, isLive, isMyTeam);
              },
            ),
      floatingActionButton: isAdultPlayer
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: PremiumTheme.neonShadow(color: PremiumTheme.neonGreen, opacity: 0.4),
                ),
                child: FloatingActionButton(
                  backgroundColor: PremiumTheme.neonGreen,
                  foregroundColor: Colors.black,
                  shape: const CircleBorder(),
                  onPressed: () => _showCreateLobbySheet(context),
                  child: const Icon(Icons.add_rounded, size: 28),
                ),
              ),
            )
          : null,
    );
  }

  String _getSurfaceForLocation(String location) {
    final loc = location.toUpperCase();
    if (loc.contains('DUMAN')) {
      return 'Futsal (Rubber)';
    } else if (loc.contains('SAIRAN')) {
      return 'Artificial Turf';
    } else if (loc.contains('SPORT CITY')) {
      return 'Artificial Turf';
    } else if (loc.contains('ASTANA')) {
      return 'Hybrid Pro';
    } else if (loc.contains('QAZAQSTAN')) {
      return 'Natural Grass';
    } else if (loc.contains('MEDINA')) {
      return 'Artificial Turf';
    } else if (loc.contains('GAGARINA')) {
      return 'Artificial Turf';
    } else if (loc.contains('JARYS')) {
      return 'Artificial Turf';
    } else if (loc.contains('ALMATY')) {
      return 'Hybrid Pro';
    } else if (loc.contains('HEYLEBERY')) {
      return 'Natural Grass';
    }
    return 'Artificial Turf'; // Default
  }

  Widget _buildLobbyCard(BuildContext context, LobbyMatch lobby) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final int spotsLeft = lobby.maxPlayers - lobby.joinedPlayers.length;
    final bool isFull = spotsLeft <= 0;
    
    final currentUser = context.read<AuthProvider>().user;
    final String currentUserName = currentUser?.name ?? 'Me';
    final bool isJoined = lobby.joinedPlayers.contains(currentUserName);

    final Color accentColor = isJoined 
        ? PremiumTheme.electricBlue 
        : (isFull ? cs.onSurfaceVariant.withValues(alpha: 0.4) : PremiumTheme.neonGreen);
        
    final Color bg = isDark ? const Color(0xFF161B22) : Colors.white;
    final Color borderCol = isDark ? const Color(0xFF30363D) : const Color(0xFFE0E0E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: PremiumTheme.softShadowOf(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLobbyDetails(context, lobby),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
                        image: DecorationImage(
                          image: NetworkImage(lobby.organizerAvatar),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (lobby.isPlus)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PLUS',
                            style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${lobby.time}  •  ${lobby.date}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            '${lobby.price.toInt()} KZT',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lobby.location,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cs.onSurface.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lobby.format,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getSurfaceForLocation(lobby.location).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: PremiumTheme.electricBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.person_rounded, size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                              const SizedBox(width: 3),
                              Text(
                                '${lobby.joinedPlayers.length} / ${lobby.maxPlayers}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isJoined 
                                  ? PremiumTheme.electricBlue.withValues(alpha: 0.15)
                                  : (isFull ? cs.onSurface.withValues(alpha: 0.05) : PremiumTheme.neonGreen.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isJoined
                                    ? PremiumTheme.electricBlue.withValues(alpha: 0.3)
                                    : (isFull ? Colors.transparent : PremiumTheme.neonGreen.withValues(alpha: 0.3)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isJoined
                                      ? 'BOOKED'
                                      : (isFull ? 'FULL' : '$spotsLeft SPOTS'),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isJoined 
                                      ? Icons.check_circle_rounded 
                                      : (isFull ? Icons.lock_rounded : Icons.chevron_right_rounded),
                                  size: 11,
                                  color: accentColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLobbyDetails(BuildContext context, LobbyMatch lobby) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final currentUser = context.read<AuthProvider>().user;
    final String currentUserName = currentUser?.name ?? 'Me';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final int spotsLeft = lobby.maxPlayers - lobby.joinedPlayers.length;
            final bool isFull = spotsLeft <= 0;
            final bool isJoined = lobby.joinedPlayers.contains(currentUserName);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(lobby.organizerAvatar),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lobby.organizerName.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                              ),
                              const Text(
                                'ORGANIZER',
                                style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161B22) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE0E0E0)),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(Icons.calendar_today_rounded, 'Date', lobby.date),
                              const Divider(height: 20, color: Colors.white10),
                              _buildDetailRow(Icons.access_time_rounded, 'Time', lobby.time),
                              const Divider(height: 20, color: Colors.white10),
                              _buildDetailRow(Icons.location_on_rounded, 'Location', lobby.location),
                              const Divider(height: 20, color: Colors.white10),
                              _buildDetailRow(Icons.grass_rounded, 'Surface', _getSurfaceForLocation(lobby.location)),
                              const Divider(height: 20, color: Colors.white10),
                              _buildDetailRow(Icons.sports_soccer_rounded, 'Format', lobby.format),
                              const Divider(height: 20, color: Colors.white10),
                              _buildDetailRow(Icons.payments_rounded, 'Price', '${lobby.price.toInt()} KZT'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'JOINED PLAYERS (${lobby.joinedPlayers.length}/${lobby.maxPlayers})',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 1.0,
                              ),
                            ),
                            if (isFull)
                              const Text(
                                'LOBBY FULL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 3.5,
                          ),
                          itemCount: lobby.maxPlayers,
                          itemBuilder: (context, index) {
                            final bool slotFilled = index < lobby.joinedPlayers.length;
                            final String name = slotFilled ? lobby.joinedPlayers[index] : 'Empty Slot';
                            final bool isMe = slotFilled && name == currentUserName;
                            
                            return GestureDetector(
                              onTap: !slotFilled ? null : () {
                                _showPlayerMiniProfile(context, name);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: slotFilled 
                                      ? (isMe ? PremiumTheme.electricBlue.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.04))
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: slotFilled
                                        ? (isMe ? PremiumTheme.electricBlue.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08))
                                        : cs.onSurface.withValues(alpha: 0.05),
                                    style: slotFilled ? BorderStyle.solid : BorderStyle.none,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: slotFilled 
                                          ? (isMe ? PremiumTheme.electricBlue : PremiumTheme.neonGreen.withValues(alpha: 0.3))
                                          : cs.onSurface.withValues(alpha: 0.1),
                                      child: Text(
                                        slotFilled ? name[0].toUpperCase() : '${index + 1}',
                                        style: TextStyle(
                                          color: slotFilled ? (isMe ? Colors.white : cs.onSurface) : cs.onSurfaceVariant,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isMe ? 'YOU' : name,
                                        style: TextStyle(
                                          color: slotFilled 
                                              ? (isMe ? PremiumTheme.electricBlue : cs.onSurface)
                                              : cs.onSurfaceVariant.withValues(alpha: 0.5),
                                          fontSize: 11,
                                          fontWeight: slotFilled ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B22) : Colors.white,
                      border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE0E0E0)),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PremiumButton(
                            text: isJoined 
                                ? 'LEAVE LOBBY' 
                                : (isFull ? 'NO SLOTS AVAILABLE' : 'BOOK SLOT'),
                            color: isJoined ? PremiumTheme.danger : PremiumTheme.neonGreen,
                            onPressed: isFull && !isJoined ? () {} : () {
                              setState(() {
                                if (isJoined) {
                                  lobby.joinedPlayers.remove(currentUserName);
                                } else {
                                  lobby.joinedPlayers.add(currentUserName);
                                }
                              });
                              _saveLobbies();
                              setModalState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateLobbySheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.read<AuthProvider>().user;
    final String currentUserName = currentUser?.name ?? 'Me';
    final String currentUserAvatar = currentUser?.fullAvatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop';

    final arenas = [
      'SAIRAN ARENA',
      'SPORT CITY PITCHES',
      'ASTANA ARENA',
      'DUMAN SPORT COMPLEX',
      'QAZAQSTAN ATHLETIC COMPLEX',
    ];

    final formats = [
      '5 vs 5',
      '6 vs 6',
      '7 vs 7',
      '11 vs 11',
    ];

    // Generate next 7 days list
    final today = DateTime.now().toLocal();
    final dates = List.generate(7, (i) {
      final date = today.add(Duration(days: i));
      return DateFormat('E, MMM d').format(date);
    });

    final timeSlots = [
      '08:00 - 09:30',
      '09:30 - 11:00',
      '11:00 - 12:30',
      '12:30 - 14:00',
      '14:00 - 15:30',
      '15:30 - 17:00',
      '17:00 - 18:30',
      '18:00 - 20:00',
      '19:00 - 20:30',
      '19:00 - 21:00',
      '19:45 - 22:00',
      '20:00 - 21:30',
      '20:00 - 22:00',
      '21:00 - 22:30',
      '21:00 - 23:00',
      '21:30 - 23:00',
      '21:30 - 23:30',
      '21:45 - 23:45',
      '22:00 - 23:30',
      '22:00 - 00:00',
    ];

    String selectedArena = arenas[0];
    String selectedFormat = formats[0];
    String selectedDate = dates[0];
    String selectedTimeSlot = timeSlots[9]; // default to 19:00 - 21:00
    final priceController = TextEditingController(text: '2000');
    int maxPlayers = 15; // default for 5 vs 5
    bool isPlus = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CREATE PICKUP LOBBY'.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.5,
                                color: cs.onSurface,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Arena selection
                        _buildSectionLabel('Location', cs),
                        const SizedBox(height: 8),
                        _buildModalDropdown(
                          value: selectedArena,
                          items: arenas,
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedArena = val;
                              });
                            }
                          },
                          context: context,
                        ),
                        const SizedBox(height: 16),

                        // Format & Date Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel('Format', cs),
                                  const SizedBox(height: 8),
                                  _buildModalDropdown(
                                    value: selectedFormat,
                                    items: formats,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedFormat = val;
                                          // Update default max players based on format
                                          if (val == '5 vs 5') {
                                            maxPlayers = 15;
                                          } else if (val == '6 vs 6') {
                                            maxPlayers = 18;
                                          } else if (val == '7 vs 7') {
                                            maxPlayers = 21;
                                          } else if (val == '11 vs 11') {
                                            maxPlayers = 22;
                                          }
                                        });
                                      }
                                    },
                                    context: context,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel('Date', cs),
                                  const SizedBox(height: 8),
                                  _buildModalDropdown(
                                    value: selectedDate,
                                    items: dates,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedDate = val;
                                        });
                                      }
                                    },
                                    context: context,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Time Slot & Price
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel('Time Slot', cs),
                                  const SizedBox(height: 8),
                                  _buildModalDropdown(
                                    value: selectedTimeSlot,
                                    items: timeSlots,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedTimeSlot = val;
                                        });
                                      }
                                    },
                                    context: context,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel('Price (KZT)', cs),
                                  const SizedBox(height: 8),
                                  PremiumTextField(
                                    controller: priceController,
                                    label: 'Price per spot',
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final price = double.tryParse(val);
                                      if (price == null || price <= 0) {
                                        return 'Invalid price';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Max Players & Is Plus
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Max Players', cs),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: cs.onSurface.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, color: PremiumTheme.neonGreen),
                                        onPressed: () {
                                          if (maxPlayers > 2) {
                                            setModalState(() {
                                              maxPlayers--;
                                            });
                                          }
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          '$maxPlayers',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline_rounded, color: PremiumTheme.neonGreen),
                                        onPressed: () {
                                          if (maxPlayers < 100) {
                                            setModalState(() {
                                              maxPlayers++;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildSectionLabel('Plus Match', cs),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Text(
                                      'PLUS ONLY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.purpleAccent,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: isPlus,
                                      activeThumbColor: PremiumTheme.neonGreen,
                                      activeTrackColor: PremiumTheme.neonGreen.withValues(alpha: 0.3),
                                      inactiveThumbColor: Colors.grey,
                                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                                      onChanged: (val) {
                                        setModalState(() {
                                          isPlus = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Create Button
                        PremiumButton(
                          text: 'CREATE LOBBY',
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final newLobby = LobbyMatch(
                                id: 'lobby_${DateTime.now().millisecondsSinceEpoch}',
                                organizerName: currentUserName,
                                organizerAvatar: currentUserAvatar,
                                location: selectedArena,
                                time: selectedTimeSlot,
                                date: selectedDate,
                                price: double.parse(priceController.text),
                                format: selectedFormat,
                                maxPlayers: maxPlayers,
                                joinedPlayers: [currentUserName], // Creator is automatically added
                                isPlus: isPlus,
                              );
                              setState(() {
                                _lobbies.add(newLobby);
                              });
                              _saveLobbies();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lobby created successfully!'),
                                  backgroundColor: PremiumTheme.neonGreen,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required BuildContext context,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: PremiumTheme.accent(context), width: 1.5),
        ),
      ),
      items: items.map((s) {
        return DropdownMenuItem<String>(
          value: s,
          child: Text(s),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme cs) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        letterSpacing: 1.0,
      ),
    );
  }

  void _showPlayerMiniProfile(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final stats = _getOrCreateStats(name);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2), width: 1.5),
              boxShadow: PremiumTheme.neonShadow(color: PremiumTheme.neonGreen, opacity: 0.15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PremiumTheme.neonGreen.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(stats.avatar),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                stats.position,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: PremiumTheme.neonGreen,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: PremiumTheme.neonGreen, width: 2),
                          boxShadow: PremiumTheme.neonShadow(opacity: 0.2),
                        ),
                        child: Center(
                          child: Text(
                            '${stats.rating}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: PremiumTheme.neonGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildMiniStatCard('Matches', '${stats.matchesPlayed}', cs)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStatCard('Win Rate', '${stats.winRate}%', cs)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildMiniStatCard('Goals', '${stats.goals}', cs)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStatCard('Assists', '${stats.assists}', cs)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildMiniStatCard('Preferred Foot', stats.preferredFoot, cs)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStatCard('Physical Form', '${stats.form.toInt()}%', cs)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildMiniStatCard('Age', '${stats.age} y.o.', cs)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMiniStatCard('MVP Awards', '${stats.mvpCount}', cs)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PremiumButton(
                        text: 'CLOSE PROFILE',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStatCard(String label, String value, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: PremiumTheme.neonGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, int index, bool isLive, bool isMyTeam) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          PremiumCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailsScreen(
                    match: TournamentMatch(
                      id: 'match_$index',
                      tournamentId: 'tournament_1',
                      homeTeamId: 'team_red',
                      awayTeamId: 'team_blue',
                      status: isLive ? 'LIVE' : 'SCHEDULED',
                      homeScore: isLive ? 2 : 0,
                      awayScore: isLive ? 1 : 0,
                      matchDate: DateTime.now().add(Duration(hours: index)),
                    ),
                    homeTeamName: 'RED DRAGONS',
                    awayTeamName: 'BLUE WOLVES',
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTeamSide('RED DRAGONS', Colors.redAccent, true)),
                    _buildScoreSection(context, isLive),
                    Expanded(child: _buildTeamSide('BLUE WOLVES', Colors.blueAccent, false)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 12, color: onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 6),
                    Text(
                      'PREMIER LEAGUE • WEEK 12',
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w800, 
                        color: onSurface.withValues(alpha: 0.4),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isMyTeam)
            Positioned(
              top: 0,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: PremiumTheme.neonGreen,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Text(
                  'match.my_team'.tr(),
                  style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (isLive)
            Positioned(
              top: 12,
              right: 12,
              child: _LiveIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamSide(String name, Color color, bool isHome) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Icon(Icons.shield_rounded, color: color, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildScoreSection(BuildContext context, bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            isLive ? '2 - 1' : 'VS',
            style: TextStyle(
              fontSize: isLive ? 24 : 18,
              fontWeight: FontWeight.w900,
              color: isLive ? Colors.white : Colors.white38,
            ),
          ),
          if (isLive)
            Text(
              "65'",
              style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.bold),
            )
          else
            const Text(
              "18:00",
              style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  String _getTitleForRole(String role) {
    switch (role) {
      case 'PARENT':
        return 'match.children_matches'.tr();
      case 'COACH':
        return 'match.team_fixtures'.tr();
      case 'FIELD_OWNER':
        return 'match.field_schedule'.tr();
      default:
        return 'match.live_matches'.tr();
    }
  }
}

class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 2, backgroundColor: Colors.redAccent),
            SizedBox(width: 4),
            Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
