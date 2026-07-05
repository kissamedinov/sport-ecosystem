import os

def main():
    filepath = 'lib/features/tournaments/presentation/screens/tournament_details_page.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Declare static Map in State class members
    target_members = "class _TournamentDetailsPageState extends State<TournamentDetailsPage> with SingleTickerProviderStateMixin {"
    replacement_members = """class _TournamentDetailsPageState extends State<TournamentDetailsPage> with SingleTickerProviderStateMixin {
  static final Map<String, String> _groupLettersMap = {};"""

    if target_members in content and "_groupLettersMap" not in content:
        content = content.replace(target_members, replacement_members)
        print("Static map member declared!")

    # 2. Populate _groupLettersMap and render dynamically in standings tab
    target_standings = """          if (isGroupStage) {
            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              groupedStandings.putIfAbsent(s.groupId, () => []).add(s);
            }

            return Column(
              children: groupedStandings.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': entry.key?.toString().split("-").last.toUpperCase() ?? "A"}), Icons.grid_view),
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
            );
          }"""

    replacement_standings = """          if (isGroupStage) {
            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              final key = s.groupName ?? s.groupId;
              groupedStandings.putIfAbsent(key, () => []).add(s);
            }

            final sortedGroupKeys = groupedStandings.keys.toList()..sort((a, b) => (a ?? '').compareTo(b ?? ''));
            _groupLettersMap.clear();
            for (int i = 0; i < sortedGroupKeys.length; i++) {
              final key = sortedGroupKeys[i];
              if (key != null) {
                _groupLettersMap[key] = String.fromCharCode(65 + i);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sortedGroupKeys.asMap().entries.map((entry) {
                  final groupKey = entry.value;
                  final groupLetter = _groupLettersMap[groupKey] ?? 'A';
                  final standingsList = groupedStandings[groupKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': groupLetter}), Icons.grid_view),
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
                            ...standingsList.asMap().entries.map((item) {
                              return _buildStandingsRow(item.key + 1, item.value, canSwap: _isOrganizer && provider.matches.any((m) => m.status == 'DRAFT'));
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
              ],
            );
          }"""

    if target_standings in content:
        content = content.replace(target_standings, replacement_standings)
        print("Standings rendering updated with alphabet map!")
    else:
        print("Standings target not found!")

    # 3. Add _cleanGroupName helper and playoff placeholders helper at the bottom of the file
    # (these were lost when we reverted the file)
    target_helpers = """class _DirectAddTeamBottomSheetState extends State<_DirectAddTeamBottomSheet> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'tournament.add_team'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'tournament.team_name'.tr(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'tournament.coach_email'.tr(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_nameController.text.trim().isEmpty) return;
                      setState(() => _isLoading = true);
                      try {
                        final provider = context.read<TournamentProvider>();
                        final success = await provider.registerTeamDirectly(
                          widget.tournamentId,
                          _nameController.text.trim(),
                          _emailController.text.trim().isEmpty
                              ? null
                              : _emailController.text.trim(),
                        );
                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('tournament.team_added_success'.tr())),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('common.add'.tr()),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}"""

    replacement_helpers = """class _DirectAddTeamBottomSheetState extends State<_DirectAddTeamBottomSheet> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'tournament.add_team'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'tournament.team_name'.tr(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'tournament.coach_email'.tr(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_nameController.text.trim().isEmpty) return;
                      setState(() => _isLoading = true);
                      try {
                        final provider = context.read<TournamentProvider>();
                        final success = await provider.registerTeamDirectly(
                          widget.tournamentId,
                          _nameController.text.trim(),
                          _emailController.text.trim().isEmpty
                              ? null
                              : _emailController.text.trim(),
                        );
                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('tournament.team_added_success'.tr())),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('common.add'.tr()),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

String _cleanGroupName(String? groupName, String? groupId) {
  if (groupId != null && _TournamentDetailsPageState._groupLettersMap.containsKey(groupId)) {
    return _TournamentDetailsPageState._groupLettersMap[groupId]!;
  }
  if (groupName != null && _TournamentDetailsPageState._groupLettersMap.containsKey(groupName)) {
    return _TournamentDetailsPageState._groupLettersMap[groupName]!;
  }
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

    if target_helpers in content:
        content = content.replace(target_helpers, replacement_helpers)
        print("Helpers appended at bottom!")
    else:
        print("Helpers target not found!")

    # 4. Also swap hardcoded 'Home Team' with placeholders in matches tab
    content = content.replace("(match.homeTeamName ?? 'Home Team')", "(match.homeTeamName ?? _getPlayoffPlaceholderName(match, true))")
    content = content.replace("(match.awayTeamName ?? 'Away Team')", "(match.awayTeamName ?? _getPlayoffPlaceholderName(match, false))")
    content = content.replace("team.groupId?.toString().split(\"-\").last.toUpperCase() ?? \"A\"", "_cleanGroupName(team.groupName, team.groupId)")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done!")

if __name__ == '__main__':
    main()
