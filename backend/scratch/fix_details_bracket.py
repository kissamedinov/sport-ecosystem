import os

def main():
    filepath = 'lib/features/tournaments/presentation/screens/tournament_details_page.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Replace ListView with Column in standings tab (under isGroupStage check)
    target_listview = """            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ...groupedStandings.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': _cleanGroupName(entry.key, entry.key)}), Icons.grid_view),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: PremiumTheme.surfaceCard(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildStandingsHeader(),
                            const Divider(height: 1, thickness: 1),
                            ...entry.value.asMap().entries.map((item) {
                              return _buildStandingsRow(item.key + 1, item.value, canSwap: _isOrganizer && provider.matches.any((m) => m.status == 'DRAFT'));
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 16),
                _buildSectionTitle('tournament.playoff_bracket'.tr(), Icons.account_tree_outlined),
                const SizedBox(height: 12),
                SizedBox(
                  height: 440,
                  child: TournamentBracketWidget(
                    matches: provider.matches.where((m) => m.groupId == null).toList(),
                    tournamentId: widget.tournamentId,
                  ),
                ),
              ],
            );"""

    replacement_column = """            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...groupedStandings.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': _cleanGroupName(entry.key, entry.key)}), Icons.grid_view),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: PremiumTheme.surfaceCard(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildStandingsHeader(),
                            const Divider(height: 1, thickness: 1),
                            ...entry.value.asMap().entries.map((item) {
                              return _buildStandingsRow(item.key + 1, item.value, canSwap: _isOrganizer && provider.matches.any((m) => m.status == 'DRAFT'));
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 16),
                _buildSectionTitle('tournament.playoff_bracket'.tr(), Icons.account_tree_outlined),
                const SizedBox(height: 12),
                SizedBox(
                  height: 440,
                  child: TournamentBracketWidget(
                    matches: provider.matches.where((m) => m.groupId == null).toList(),
                    tournamentId: widget.tournamentId,
                  ),
                ),
              ],
            );"""

    if target_listview in content:
        content = content.replace(target_listview, replacement_column)
        print("ListView successfully replaced with Column in standings tab!")
    else:
        print("ListView target not found in standings tab!")

    # 2. Append _getPlayoffPlaceholderName helper at bottom of the file
    target_clean = """String _cleanGroupName(String? groupName, String? groupId) {
  final name = groupName ?? groupId;
  if (name == null) return "A";
  final upper = name.toUpperCase();
  if (upper.startsWith("GROUP") || upper.startsWith("ГРУППА")) {
    final parts = name.split(" ");
    if (parts.length > 1) {
      final letter = parts.last.toUpperCase();
      if (letter == "A" || letter == "А") return "A";
      if (letter == "B" || letter == "Б") return "B";
      return letter;
    }
  }
  if (name.length > 8) {
    return name.split("-").last.toUpperCase();
  }
  return name.toUpperCase();
}"""

    replacement_helpers = """String _cleanGroupName(String? groupName, String? groupId) {
  final name = groupName ?? groupId;
  if (name == null) return "A";
  final upper = name.toUpperCase();
  if (upper.startsWith("GROUP") || upper.startsWith("ГРУППА")) {
    final parts = name.split(" ");
    if (parts.length > 1) {
      final letter = parts.last.toUpperCase();
      if (letter == "A" || letter == "А") return "A";
      if (letter == "B" || letter == "Б") return "B";
      return letter;
    }
  }
  if (name.length > 8) {
    return name.split("-").last.toUpperCase();
  }
  return name.toUpperCase();
}

String _getPlayoffPlaceholderName(TournamentMatch match, bool isHome) {
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
  return 'tournament.awaiting_winner'.tr();
}"""

    if target_clean in content and "_getPlayoffPlaceholderName" not in content:
        content = content.replace(target_clean, replacement_helpers)
        print("_getPlayoffPlaceholderName helper appended!")

    # 3. Replace homeTeamName and awayTeamName fallbacks in _buildMatchItem
    target_home_text = "Text(\n                              (match.homeTeamName ?? 'Home Team').toUpperCase(),"
    replacement_home_text = "Text(\n                              (match.homeTeamName ?? _getPlayoffPlaceholderName(match, true)).toUpperCase(),"
    
    # Let's use simple string replacements:
    content = content.replace("(match.homeTeamName ?? 'Home Team').toUpperCase()", "(match.homeTeamName ?? _getPlayoffPlaceholderName(match, true)).toUpperCase()")
    content = content.replace("(match.awayTeamName ?? 'Away Team').toUpperCase()", "(match.awayTeamName ?? _getPlayoffPlaceholderName(match, false)).toUpperCase()")
    print("Match item fallbacks replaced!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done editing details page!")

if __name__ == '__main__':
    main()
