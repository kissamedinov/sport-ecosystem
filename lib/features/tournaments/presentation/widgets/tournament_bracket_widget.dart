import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/tournament_match.dart';
import '../screens/match_center_screen.dart';

class TournamentBracketWidget extends StatelessWidget {
  final List<TournamentMatch> matches;
  final String tournamentId;

  const TournamentBracketWidget({
    Key? key,
    required this.matches,
    required this.tournamentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined, size: 48, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                'Сетка плей-офф пока не создана',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Group matches by round_number
    final Map<int, List<TournamentMatch>> roundMatches = {};
    for (var match in matches) {
      final r = match.roundNumber ?? 1;
      roundMatches.putIfAbsent(r, () => []).add(match);
    }

    // Sort rounds ascending
    final sortedRounds = roundMatches.keys.toList()..sort();
    final maxRound = sortedRounds.isNotEmpty ? sortedRounds.last : 1;

    // Calculate dimensions
    const double cardHeight = 110.0;
    const double cardWidth = 240.0;
    const double gap = 30.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BracketConnectorsPainter(
                  roundMatches: roundMatches,
                  sortedRounds: sortedRounds,
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  gap: gap,
                  headerOffset: 60.0,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedRounds.map((roundNum) {
                final roundList = roundMatches[roundNum]!;
                // Sort matches in round by bracketPosition to display them in correct order
                roundList.sort((a, b) => (a.bracketPosition ?? 0).compareTo(b.bracketPosition ?? 0));

                // Round name in Russian
                String roundTitle;
                if (roundNum == maxRound) {
                  roundTitle = 'Финал';
                } else if (roundNum == maxRound - 1) {
                  roundTitle = 'Полуфинал';
                } else if (roundNum == maxRound - 2) {
                  roundTitle = 'Четвертьфинал';
                } else if (roundNum == maxRound - 3) {
                  roundTitle = '1/8 финала';
                } else {
                  roundTitle = 'Раунд $roundNum';
                }

                // Math to calculate padding & gaps to align tree branches
                final int rIndex = roundNum - 1; // 0-based index for math
                final double scale = rIndex >= 0 ? (1 << rIndex).toDouble() : 1.0;
                final double topPadding = (scale - 1) * (cardHeight + gap) / 2;
                final double cardGap = (scale - 1) * cardHeight + scale * gap;

                return Container(
                  width: cardWidth + 32, // Width of column with margin
                  margin: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Round Header with fixed height for deterministic coordinate math
                      SizedBox(
                        height: 36,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              roundTitle,
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Matches list
                      Padding(
                        padding: EdgeInsets.only(top: topPadding),
                        child: Column(
                          children: List.generate(roundList.length, (index) {
                            final match = roundList[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: cardGap),
                              child: _buildMatchCard(context, match, cardWidth, cardHeight),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, TournamentMatch match, double width, double height) {
    final bool isFinished = match.status == 'FINISHED';
    final bool isLive = match.status == 'LIVE';
    
    final bool hasHomeWon = isFinished && match.homeScore > match.awayScore;
    final bool hasAwayWon = isFinished && match.awayScore > match.homeScore;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchCenterScreen(
              matchId: match.id,
              tournamentId: tournamentId,
            ),
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2640).withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive 
                ? const Color(0xFF00E676) // Neon Green
                : Colors.white.withOpacity(0.1),
            width: isLive ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isLive)
              BoxShadow(
                color: const Color(0xFF00E676).withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Home Team Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield,
                        size: 16,
                        color: hasHomeWon ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.homeTeamName ?? 'Ожидается победитель',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: match.homeTeamName == null 
                                ? Colors.white.withOpacity(0.3)
                                : (hasHomeWon ? Colors.white : Colors.white.withOpacity(0.7)),
                            fontWeight: hasHomeWon ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (match.homeTeamName != null)
                  Text(
                    isFinished ? '${match.homeScore}' : '-',
                    style: TextStyle(
                      color: hasHomeWon ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Away Team Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield,
                        size: 16,
                        color: hasAwayWon ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.awayTeamName ?? 'Ожидается победитель',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: match.awayTeamName == null 
                                ? Colors.white.withOpacity(0.3)
                                : (hasAwayWon ? Colors.white : Colors.white.withOpacity(0.7)),
                            fontWeight: hasAwayWon ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (match.awayTeamName != null)
                  Text(
                    isFinished ? '${match.awayScore}' : '-',
                    style: TextStyle(
                      color: hasAwayWon ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const Divider(color: Colors.white10, height: 12),
            // Status or Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    isFinished ? 'Завершен' : (match.matchDate != null ? DateFormat('dd.MM HH:mm').format(match.matchDate!.toLocal()) : 'Не запланирован'),
                    style: TextStyle(
                      color: isFinished ? Colors.white54 : Colors.blueAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (match.fieldName != null)
                  Expanded(
                    child: Text(
                      match.fieldName!,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BracketConnectorsPainter extends CustomPainter {
  final Map<int, List<TournamentMatch>> roundMatches;
  final List<int> sortedRounds;
  final double cardWidth;
  final double cardHeight;
  final double gap;
  final double headerOffset;

  BracketConnectorsPainter({
    required this.roundMatches,
    required this.sortedRounds,
    this.cardWidth = 240.0,
    this.cardHeight = 110.0,
    this.gap = 30.0,
    this.headerOffset = 60.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final highlightPaint = Paint()
      ..color = const Color(0xFF00E676) // Neon Green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final highlightGlowPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    for (int r = 0; r < sortedRounds.length - 1; r++) {
      final int roundNum = sortedRounds[r];
      final int nextRoundNum = sortedRounds[r + 1];

      final List<TournamentMatch> currentRoundMatches = List.from(roundMatches[roundNum]!);
      currentRoundMatches.sort((a, b) => (a.bracketPosition ?? 0).compareTo(b.bracketPosition ?? 0));

      final List<TournamentMatch> nextRoundMatches = List.from(roundMatches[nextRoundNum]!);
      nextRoundMatches.sort((a, b) => (a.bracketPosition ?? 0).compareTo(b.bracketPosition ?? 0));

      // Math for current round
      final int rIndex = roundNum - 1;
      final double scale = rIndex >= 0 ? (1 << rIndex).toDouble() : 1.0;
      final double topPadding = (scale - 1) * (cardHeight + gap) / 2;
      final double cardGap = (scale - 1) * cardHeight + scale * gap;

      // Math for next round
      final int nextRIndex = nextRoundNum - 1;
      final double nextScale = nextRIndex >= 0 ? (1 << nextRIndex).toDouble() : 1.0;
      final double nextTopPadding = (nextScale - 1) * (cardHeight + gap) / 2;
      final double nextCardGap = (nextScale - 1) * cardHeight + nextScale * gap;

      for (int i = 0; i < currentRoundMatches.length; i++) {
        final matchA = currentRoundMatches[i];
        if (matchA.nextMatchId == null) continue;

        // Find matchB index in next round
        final int j = nextRoundMatches.indexWhere((m) => m.id == matchA.nextMatchId);
        if (j == -1) {
          continue;
        }

        // Calculate coordinates
        final double x1 = r * 288.0 + 256.0;
        final double y1 = headerOffset + topPadding + i * (cardHeight + cardGap) + cardHeight / 2;

        final double x2 = (r + 1) * 288.0 + 16.0;
        final double y2 = headerOffset + nextTopPadding + j * (cardHeight + nextCardGap) + cardHeight / 2;

        final double xMid = x1 + 24.0;

        final Path path = Path();
        path.moveTo(x1, y1);
        path.lineTo(xMid, y1);
        path.lineTo(xMid, y2);
        path.lineTo(x2, y2);

        final bool isFinished = matchA.status == 'FINISHED';
        final bool hasWinner = isFinished && (matchA.homeScore != matchA.awayScore);

        if (hasWinner) {
          canvas.drawPath(path, highlightGlowPaint);
          canvas.drawPath(path, highlightPaint);
        } else {
          canvas.drawPath(path, dimPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectorsPainter oldDelegate) {
    return oldDelegate.roundMatches != roundMatches || oldDelegate.sortedRounds != sortedRounds;
  }
}
