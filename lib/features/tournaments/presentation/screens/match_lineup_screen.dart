import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_squad_provider.dart';
import '../../data/models/tournament_squad_member.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../lineups/models/lineup.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class MatchLineupScreen extends StatefulWidget {
  final String matchId;
  final String tournamentTeamId;
  final String teamId;
  final bool isHomeTeam;

  const MatchLineupScreen({
    super.key,
    required this.matchId,
    required this.tournamentTeamId,
    required this.teamId,
    this.isHomeTeam = true,
  });

  @override
  State<MatchLineupScreen> createState() => _MatchLineupScreenState();
}

class _MatchLineupScreenState extends State<MatchLineupScreen> {
  final Map<String, bool> _starters = {};
  final Map<String, String> _positions = {};
  final List<String> _positionOptions = ['GK', 'DF', 'MF', 'FW'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentSquadProvider>().fetchSquad(widget.tournamentTeamId);
    });
  }

  int get _startingCount => _starters.values.where((v) => v).length;

  void _toggleSelection(TournamentSquadMember member) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_starters.containsKey(member.childProfileId)) {
        _starters.remove(member.childProfileId);
        _positions.remove(member.childProfileId);
      } else {
        _starters[member.childProfileId] = _startingCount < 11;
        _positions[member.childProfileId] = member.position ?? 'MF';
      }
    });
  }

  void _toggleStarting(String childProfileId) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_starters.containsKey(childProfileId)) {
        final currentlyStarting = _starters[childProfileId]!;
        if (!currentlyStarting && _startingCount >= 11) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MAX 11 STARTING PLAYERS ALLOWED'),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        _starters[childProfileId] = !currentlyStarting;
      }
    });
  }

  Future<void> _submit() async {
    HapticFeedback.heavyImpact();
    if (_starters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one player.')),
      );
      return;
    }

    final lineupPlayers = _starters.keys.map((pid) => LineupPlayer(
      childProfileId: pid,
      isStarting: _starters[pid]!,
      position: _positions[pid],
    )).toList();

    final lineupRequest = MatchLineup(
      id: '',
      matchId: widget.matchId,
      teamId: widget.teamId,
      status: LineupStatus.SUBMITTED,
      createdAt: DateTime.now(),
      players: lineupPlayers,
    );

    try {
      await context.read<LineupProvider>().submitLineup(
            widget.matchId,
            lineupRequest,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('LINEUP SUBMITTED SUCCESSFULLY'),
            backgroundColor: PremiumTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: PremiumTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineupProvider = context.watch<LineupProvider>();
    
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MATCH LINEUP', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _startingCount == 11 ? PremiumTheme.neonGreen.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _startingCount == 11 ? PremiumTheme.neonGreen.withValues(alpha: 0.3) : Colors.white10),
            ),
            child: Center(
              child: Text(
                '$_startingCount / 11 STARTING',
                style: TextStyle(
                  color: _startingCount == 11 ? PremiumTheme.neonGreen : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<TournamentSquadProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || lineupProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.white70)));
          }

          if (provider.squad.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    const Text(
                      'NO SQUAD MEMBERS FOUND\nPlease add players to the tournament squad first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildPitchView(provider.squad),
              _buildSelectionSummary(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.squad.length,
                  itemBuilder: (context, index) {
                    final member = provider.squad[index];
                    final isSelected = _starters.containsKey(member.childProfileId);
                    final isStarting = isSelected && _starters[member.childProfileId]!;
                    final name = member.playerName ?? 'Unknown Player';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _toggleSelection(member),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: PremiumTheme.glassDecorationOf(context, radius: 16).copyWith(
                            border: Border.all(
                              color: isStarting 
                                ? PremiumTheme.neonGreen.withValues(alpha: 0.3)
                                : isSelected 
                                  ? Colors.orange.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isStarting ? PremiumTheme.neonGreen : isSelected ? Colors.orange : Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    member.jerseyNumber?.toString() ?? '?',
                                    style: TextStyle(
                                      color: (isStarting || isSelected) ? Colors.black : Colors.white70,
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
                                        color: isSelected ? Colors.white : Colors.white54,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isStarting ? 'STARTING XI' : isSelected ? 'SUBSTITUTE' : 'NOT SELECTED',
                                      style: TextStyle(
                                        color: isStarting ? PremiumTheme.neonGreen : isSelected ? Colors.orange : Colors.white24,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected) ...[
                                GestureDetector(
                                  onTap: () => _toggleStarting(member.childProfileId),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isStarting ? PremiumTheme.neonGreen.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isStarting ? Icons.sports_soccer : Icons.airline_seat_recline_normal,
                                      color: isStarting ? PremiumTheme.neonGreen : Colors.orange,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _positions[member.childProfileId],
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white24, size: 16),
                                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                    dropdownColor: PremiumTheme.surfaceCard(context),
                                    items: _positionOptions.map((pos) => DropdownMenuItem(
                                      value: pos,
                                      child: Text(pos),
                                    )).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _positions[member.childProfileId] = val!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: isSelected ? PremiumTheme.neonGreen : Colors.white12,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildSubmitSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPitchView(List<TournamentSquadMember> squad) {
    final startingPlayers = squad.where((m) => _starters[m.childProfileId] == true).toList();
    
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332), 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 220),
            painter: PitchPainter(),
          ),
          if (startingPlayers.isEmpty)
            const Center(
              child: Text(
                'TAP PLAYERS TO ADD TO STARTING XI',
                style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildFormationLayout(startingPlayers),
            ),
        ],
      ),
    );
  }

  Widget _buildFormationLayout(List<TournamentSquadMember> players) {
    final gk = players.where((p) => _positions[p.childProfileId] == 'GK').toList();
    final df = players.where((p) => _positions[p.childProfileId] == 'DF').toList();
    final mf = players.where((p) => _positions[p.childProfileId] == 'MF').toList();
    final fw = players.where((p) => _positions[p.childProfileId] == 'FW').toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _playerRow(fw),
        _playerRow(mf),
        _playerRow(df),
        _playerRow(gk),
      ],
    );
  }

  Widget _playerRow(List<TournamentSquadMember> players) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: players.map((p) => _pitchPlayerIcon(p)).toList(),
    );
  }

  Widget _pitchPlayerIcon(TournamentSquadMember p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.4), blurRadius: 8),
            ],
          ),
          child: Center(
            child: Text(
              p.jerseyNumber?.toString() ?? '?',
              style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          (p.playerName ?? 'P').split(' ').first.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSelectionSummary() {
    final subCount = _starters.values.where((v) => !v).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _summaryChip('$_startingCount STARTING', PremiumTheme.neonGreen),
          const SizedBox(width: 12),
          _summaryChip('$subCount SUBSTITUTES', Colors.orange),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _starters.clear();
                _positions.clear();
              });
            },
            child: const Text('RESET', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSubmitSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendItem(PremiumTheme.neonGreen, 'STARTING'),
                _legendItem(Colors.orange, 'SUBSTITUTE'),
                _legendItem(Colors.white24, 'OFF'),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _submit,
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
                    'SUBMIT LINEUP',
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
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(Offset.zero & size, paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 30, paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, 40), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.2, size.height - 40, size.width * 0.6, 40), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
