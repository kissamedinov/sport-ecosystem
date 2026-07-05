import os

def main():
    filepath = 'lib/features/tournaments/presentation/widgets/shareable_schedule_dialog.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add missing imports at the top
    target_imports = "import '../../data/models/tournament_match.dart';"
    replacement_imports = """import '../../data/models/tournament_match.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../data/models/tournament_standing.dart';"""

    if target_imports in content and 'provider.dart' not in content:
        content = content.replace(target_imports, replacement_imports)
        print("Imports added successfully!")

    # 1. Replace the match list/grid with a beautiful table grouped by fields
    target_layout = """                        // Fields display
                        if (sortedFields.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('tournament.no_matches_scheduled_day'.tr(), style: TextStyle(color: _mutedTextColor, fontSize: 12)),
                          )
                        else if (sortedFields.length == 1)
                          // Single field vertical list
                          Column(
                            children: fieldGroups[sortedFields.first]!.map((match) {
                              return _buildMatchRow(match);
                            }).toList(),
                          )
                        else
                          // Multi field grid columns
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sortedFields.map((fName) {
                              final fMatches = fieldGroups[fName]!;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Field Column Header
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: PremiumTheme.neonGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: PremiumTheme.neonGreen.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          fName.toUpperCase(),
                                          style: const TextStyle(
                                            color: PremiumTheme.neonGreen,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 9,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Match items
                                      ...fMatches.map((match) => _buildCompactMatchCard(match)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),"""

    replacement_layout = """                        // Fields display
                        if (sortedFields.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('tournament.no_matches_scheduled_day'.tr(), style: TextStyle(color: _mutedTextColor, fontSize: 12)),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sortedFields.map((fName) {
                              final fMatches = fieldGroups[fName]!;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Field Section Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        fName.toUpperCase(),
                                        style: const TextStyle(
                                          color: PremiumTheme.neonGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Table Header
                                    _buildTableHeader(context),
                                    // Table Rows
                                    ...fMatches.asMap().entries.map((entry) {
                                      return _buildMatchTableRow(context, entry.value, entry.key, fMatches.length);
                                    }),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),"""

    if target_layout in content:
        content = content.replace(target_layout, replacement_layout)
        print("Schedule layout updated to table layout successfully!")
    else:
        print("Schedule layout target not found!")

    # 2. Replace _buildMatchRow and _buildCompactMatchCard with new helpers
    target_helpers_start = "  // 1-Field Layout Row"
    idx = content.find(target_helpers_start)
    if idx != -1:
        helpers_code = """  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: _itemBorderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              'ВРЕМЯ',
              style: TextStyle(color: _dialogTextColor.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'КОМАНДА "А"',
              style: TextStyle(color: _dialogTextColor.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'КОМАНДА "В"',
              style: TextStyle(color: _dialogTextColor.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 65,
            child: Text(
              'ВОЗРАСТ',
              style: TextStyle(color: _dialogTextColor.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'СТАДИЯ',
              style: TextStyle(color: _dialogTextColor.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              'СЧЁТ',
              style: TextStyle(color: _dialogTextColor.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTableRow(BuildContext context, TournamentMatch match, int index, int total) {
    final dateStr = match.matchDate != null ? DateFormat('HH:mm').format(match.matchDate!.toLocal()) : 'TBD';
    final isFinished = match.status == 'FINISHED';
    final scoreStr = isFinished ? '${match.homeScore}:${match.awayScore}' : '-';
    
    final String divName = _resolveDivisionName(context, match);
    final Color badgeColor = _getDivisionBadgeColor(divName);
    
    final bool isLast = index == total - 1;

    final homePlaceholder = _getPlayoffPlaceholder(match, true);
    final awayPlaceholder = _getPlayoffPlaceholder(match, false);
    final homeName = match.homeTeamName ?? homePlaceholder;
    final awayName = match.awayTeamName ?? awayPlaceholder;

    final stageName = _getMatchStageName(context, match);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.transparent : (_isDark ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.015)),
        border: Border(
          left: BorderSide(color: _itemBorderColor),
          right: BorderSide(color: _itemBorderColor),
          bottom: BorderSide(color: _itemBorderColor),
        ),
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(8)) : null,
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 45,
            child: Text(
              dateStr,
              style: TextStyle(color: _mainTextColor, fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Team A
          Expanded(
            flex: 3,
            child: Text(
              homeName.toUpperCase(),
              style: TextStyle(
                color: match.homeTeamName == null ? _mutedTextColor : _mainTextColor,
                fontSize: 9,
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Team B
          Expanded(
            flex: 3,
            child: Text(
              awayName.toUpperCase(),
              style: TextStyle(
                color: match.awayTeamName == null ? _mutedTextColor : _mainTextColor,
                fontSize: 9,
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Age / Division
          SizedBox(
            width: 65,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 0.5),
                ),
                child: Text(
                  divName.toUpperCase(),
                  style: TextStyle(
                    color: _isDark ? Colors.white : badgeColor.withValues(alpha: 0.95),
                    fontSize: 7,
                    fontWeight: FontWeight.w900
                  ),
                ),
              ),
            ),
          ),
          // Stage
          Expanded(
            flex: 2,
            child: Text(
              stageName.toUpperCase(),
              style: TextStyle(
                color: _isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
                fontSize: 7,
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score
          SizedBox(
            width: 45,
            child: Text(
              scoreStr,
              style: TextStyle(
                color: isFinished ? PremiumTheme.neonGreen : _mutedTextColor,
                fontSize: 10,
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDivisionBadgeColor(String name) {
    final int hash = name.hashCode.abs();
    final List<Color> colors = [
      const Color(0xFFEF5350), // Red
      const Color(0xFF26A69A), // Teal
      const Color(0xFF29B6F6), // Light Blue
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF9CCC65), // Light Green
    ];
    return colors[hash % colors.length];
  }

  String _resolveDivisionName(BuildContext context, TournamentMatch match) {
    final provider = context.read<TournamentProvider>();
    final div = provider.divisions.firstWhere(
      (d) => d['id'].toString() == match.divisionId,
      orElse: () => {},
    );
    if (div.isNotEmpty) {
      return div['name'] ?? '2011';
    }
    
    TournamentStanding? standing;
    for (var s in provider.standings) {
      if (s.divisionId == match.divisionId) {
        standing = s;
        break;
      }
    }
    if (standing != null && standing.divisionName != null) {
      return standing.divisionName!;
    }
    return '2011';
  }

  String _resolveGroupName(BuildContext context, TournamentMatch match) {
    if (match.groupId == null) return 'Плей-офф';
    final provider = context.read<TournamentProvider>();
    
    TournamentStanding? standing;
    for (var s in provider.standings) {
      if (s.groupId == match.groupId) {
        standing = s;
        break;
      }
    }
    if (standing != null && standing.groupName != null) {
      return standing.groupName!;
    }
    return 'Группа';
  }

  String _getPlayoffPlaceholder(TournamentMatch match, bool isHome) {
    if (match.groupId != null) return 'Awaiting';
    if (match.roundNumber == 1) {
      if (match.bracketPosition == 0) {
        return isHome ? "A1" : "B2";
      } else if (match.bracketPosition == 1) {
        return isHome ? "B1" : "A2";
      } else if (match.bracketPosition == 2) {
        return isHome ? "A3" : "B3";
      } else if (match.bracketPosition == 3) {
        return isHome ? "A4" : "B4";
      }
    } else if (match.roundNumber == 2) {
      if (match.bracketPosition == 0) {
        return isHome ? "Победитель ПФ1" : "Победитель ПФ2";
      } else if (match.bracketPosition == 1) {
        return isHome ? "Проигравший ПФ1" : "Проигравший ПФ2";
      }
    }
    return 'Awaiting';
  }

  String _getMatchStageName(BuildContext context, TournamentMatch match) {
    if (match.groupId != null) {
      final clean = _resolveGroupName(context, match);
      if (clean.length > 8) {
        return 'Группа ' + clean.split("-").last.toUpperCase();
      }
      return 'Группа ' + clean.toUpperCase();
    }
    if (match.roundNumber == 1) {
      if (match.bracketPosition == 0 || match.bracketPosition == 1) {
        return '1/2 финала';
      } else if (match.bracketPosition == 2) {
        return 'За 5-6 место';
      } else if (match.bracketPosition == 3) {
        return 'За 7-8 место';
      }
    } else if (match.roundNumber == 2) {
      if (match.bracketPosition == 0) {
        return 'Финал';
      } else if (match.bracketPosition == 1) {
        return 'За 3 место';
      }
    }
    return 'Плей-офф';
  }
}
"""
        content = content[:idx] + helpers_code
        print("Helpers updated!")
    else:
        print("Helpers target not found!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done!")

if __name__ == '__main__':
    main()
