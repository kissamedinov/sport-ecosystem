import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import '../../data/models/tournament_match.dart';
import '../../data/models/tournament.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ShareableScheduleDialog extends StatefulWidget {
  final List<TournamentMatch> matches;
  final Tournament tournament;

  const ShareableScheduleDialog({
    Key? key,
    required this.matches,
    required this.tournament,
  }) : super(key: key);

  @override
  State<ShareableScheduleDialog> createState() => _ShareableScheduleDialogState();
}

class _ShareableScheduleDialogState extends State<ShareableScheduleDialog> {
  late List<DateTime> _availableDates;
  DateTime? _selectedDate;
  bool _isSaving = false;
  final GlobalKey _repaintKey = GlobalKey();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _containerBg => _isDark ? const Color(0xFF0B1519) : Colors.white;
  Color get _itemBg => _isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.025);
  Color get _itemBorderColor => _isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.06);
  Color get _mainTextColor => _isDark ? Colors.white : Colors.black;
  Color get _secondaryTextColor => _isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7);
  Color get _mutedTextColor => _isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.35);
  Color get _dividerColor => _isDark ? Colors.white10 : Colors.black12;
  Color get _shadowColor => _isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05);

  Color get _dialogBg => _isDark ? const Color(0xFF122229) : Colors.white;
  Color get _dialogTextColor => _isDark ? Colors.white : Colors.black87;
  Color get _dialogBorder => _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

  /// Build a UUID→letter map from sorted unique group IDs in the matches list.
  /// This exactly mirrors the logic in tournament_details_page.dart so letters are consistent.
  Map<String, String> get _groupLetterMap {
    final groupIds = widget.matches
        .where((m) => m.groupId != null)
        .map((m) => m.groupId!)
        .toSet()
        .toList()
      ..sort();
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final map = <String, String>{};
    for (int i = 0; i < groupIds.length; i++) {
      map[groupIds[i]] = letters[i < letters.length ? i : i % letters.length];
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _extractDates();
  }

  void _extractDates() {
    final List<DateTime> dates = [];
    for (var m in widget.matches) {
      if (m.matchDate != null) {
        final date = DateTime(
          m.matchDate!.toLocal().year,
          m.matchDate!.toLocal().month,
          m.matchDate!.toLocal().day,
        );
        if (!dates.contains(date)) {
          dates.add(date);
        }
      }
    }
    dates.sort();
    setState(() {
      _availableDates = dates;
      if (dates.isNotEmpty) {
        _selectedDate = dates.first;
      }
    });
  }

  Future<void> _saveToStorage() async {
    if (_selectedDate == null) return;
    setState(() => _isSaving = true);
    try {
      RenderRepaintBoundary? boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      Uint8List pngBytes = byteData.buffer.asUint8List();

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        final fileName = 'schedule_${widget.tournament.name}_${dateStr}_${DateTime.now().millisecondsSinceEpoch}.png'
            .replaceAll(RegExp(r'[^\w\-_.]'), '_');
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('tournament.schedule_saved'.tr(namedArgs: {'path': filePath})),
              backgroundColor: const Color(0xFF00E676),
            ),
          );
        }
      } else {
        throw Exception('Storage directory not available');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('tournament.schedule_export_failed'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDate == null) {
      return AlertDialog(
        backgroundColor: PremiumTheme.surfaceCard(context),
        title: Text('tournament.export_schedule_title'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text('tournament.no_dates_scheduled'.tr(), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.close'.tr(), style: const TextStyle(color: PremiumTheme.neonGreen)),
          ),
        ],
      );
    }

    final matchesOfDay = widget.matches.where((m) =>
        m.matchDate != null &&
        m.matchDate!.toLocal().year == _selectedDate!.year &&
        m.matchDate!.toLocal().month == _selectedDate!.month &&
        m.matchDate!.toLocal().day == _selectedDate!.day
    ).toList();

    // Sort matches by time
    matchesOfDay.sort((a, b) => (a.matchDate ?? DateTime.now()).compareTo(b.matchDate ?? DateTime.now()));

    // Group matches by fieldName
    final Map<String, List<TournamentMatch>> fieldGroups = {};
    for (var m in matchesOfDay) {
      final fName = m.fieldName ?? 'tournament.field_default'.tr(namedArgs: {'num': '1'});
      fieldGroups.putIfAbsent(fName, () => []).add(m);
    }
    
    final sortedFields = fieldGroups.keys.toList()..sort();

    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: _dialogBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _dialogBorder),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tournament.share_schedule'.tr(),
                  style: TextStyle(color: _dialogTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: _dialogTextColor.withValues(alpha: 0.7)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date picker dropdown
            Row(
              children: [
                Text(
                  'tournament.select_day'.tr(),
                  style: TextStyle(
                    color: _isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _containerBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _dialogBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DateTime>(
                        value: _selectedDate,
                        dropdownColor: _dialogBg,
                        style: TextStyle(color: _dialogTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                        items: _availableDates.map((date) {
                          return DropdownMenuItem<DateTime>(
                            value: date,
                            child: Text(DateFormat('dd.MM.yyyy (EEEE)', 'ru').format(date)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDate = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Preview area
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _containerBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PremiumTheme.neonGreen.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top banner
                        Text(
                          widget.tournament.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PremiumTheme.neonGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.tournament.format == 'KNOCKOUT' ? 'tournament.playoff_bracket_caps'.tr() : 'tournament.championship_group_stage_caps'.tr(),
                          style: TextStyle(
                            color: _secondaryTextColor.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _itemBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('dd MMMM yyyy', 'ru').format(_selectedDate!).toUpperCase(),
                            style: TextStyle(
                              color: _mainTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: _dividerColor, height: 1),
                        const SizedBox(height: 20),

                        // Fields display
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
                          ),
                        const SizedBox(height: 20),
                        Divider(color: _dividerColor, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 10, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(width: 6),
                            Text(
                              'SPORT ECOSYSTEM PLATFORM',
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Share / download buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveToStorage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      'tournament.download_schedule_png'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  // 1-Field Layout Row
  Widget _buildMatchRow(TournamentMatch match) {
    final timeStr = match.matchDate != null ? DateFormat('HH:mm').format(match.matchDate!.toLocal()) : 'TBD';
    final homePlaceholder = _getPlayoffPlaceholder(match, true);
    final awayPlaceholder = _getPlayoffPlaceholder(match, false);
    final homeName = (match.homeTeamName == null || match.homeTeamName == 'Home Team') ? homePlaceholder : match.homeTeamName!;
    final awayName = (match.awayTeamName == null || match.awayTeamName == 'Away Team') ? awayPlaceholder : match.awayTeamName!;
    final isFinished = match.status == 'FINISHED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _itemBorderColor),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
          const SizedBox(width: 14),
          // Teams
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMatchStageName(context, match).toUpperCase(),
                  style: const TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.shield, size: 12, color: _mutedTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        homeName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: match.homeTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: _mutedTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        awayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: match.awayTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Scores column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isFinished ? '${match.homeScore}' : '-',
                style: TextStyle(
                  color: isFinished ? PremiumTheme.neonGreen : _secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFinished ? '${match.awayScore}' : '-',
                style: TextStyle(
                  color: isFinished ? PremiumTheme.neonGreen : _secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Multi-Field Layout Card
  Widget _buildCompactMatchCard(TournamentMatch match) {
    final timeStr = match.matchDate != null ? DateFormat('HH:mm').format(match.matchDate!.toLocal()) : 'TBD';
    final homePlaceholder = _getPlayoffPlaceholder(match, true);
    final awayPlaceholder = _getPlayoffPlaceholder(match, false);
    final homeName = (match.homeTeamName == null || match.homeTeamName == 'Home Team') ? homePlaceholder : match.homeTeamName!;
    final awayName = (match.awayTeamName == null || match.awayTeamName == 'Away Team') ? awayPlaceholder : match.awayTeamName!;
    final isFinished = match.status == 'FINISHED';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _itemBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _itemBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time
          Text(
            timeStr,
            style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            _getMatchStageName(context, match).toUpperCase(),
            style: TextStyle(
              color: _mutedTextColor.withValues(alpha: 0.6),
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Home
          Text(
            homeName.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: match.homeTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isFinished ? '${match.homeScore} : ${match.awayScore}' : 'vs',
            style: TextStyle(
              color: isFinished ? PremiumTheme.neonGreen : _mutedTextColor,
              fontSize: isFinished ? 9 : 7,
              fontWeight: isFinished ? FontWeight.bold : FontWeight.normal,
              fontStyle: isFinished ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          // Away
          Text(
            awayName.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: match.awayTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
      // Use the precomputed UUID→letter map (A, B, C...) built from sorted group IDs
      final letter = _groupLetterMap[match.groupId] ?? 'A';
      return 'Группа $letter';
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
        return 'Финал 🏆';
      } else if (match.bracketPosition == 1) {
        return 'За 3 место 🥉';
      }
    }
    return 'Плей-офф';
  }
}
