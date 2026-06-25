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
              content: Text('Расписание успешно сохранено в: $filePath'),
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
            content: Text('Не удалось экспортировать расписание: $e'),
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
        title: const Text('Экспорт расписания', style: TextStyle(color: Colors.white)),
        content: const Text('Нет доступных дат с запланированными матчами.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть', style: TextStyle(color: PremiumTheme.neonGreen)),
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
      final fName = m.fieldName ?? 'Поле 1';
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
          color: const Color(0xFF122229),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Поделиться расписанием',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date picker dropdown
            Row(
              children: [
                const Text('Выберите день: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1519),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DateTime>(
                        value: _selectedDate,
                        dropdownColor: const Color(0xFF122229),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                      color: const Color(0xFF0B1519),
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
                          widget.tournament.format == 'KNOCKOUT' ? 'ПЛЕЙ-ОФФ СЕТКА' : 'ЧЕМПИОНАТ / ГРУППОВОЙ ЭТАП',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('dd MMMM yyyy', 'ru').format(_selectedDate!).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 20),

                        // Fields display
                        if (sortedFields.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Нет запланированных матчей на этот день', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 10, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(width: 6),
                            Text(
                              'SPORT ECOSYSTEM PLATFORM',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
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
                    label: const Text(
                      'Скачать расписание (PNG)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withOpacity(0.1),
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
                Row(
                  children: [
                    Icon(Icons.shield, size: 12, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.homeTeamName ?? 'Ожидается победитель',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: match.homeTeamName == null ? Colors.white24 : Colors.white70,
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
                    Icon(Icons.shield_outlined, size: 12, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.awayTeamName ?? 'Ожидается победитель',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: match.awayTeamName == null ? Colors.white24 : Colors.white70,
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
        ],
      ),
    );
  }

  // Multi-Field Layout Card
  Widget _buildCompactMatchCard(TournamentMatch match) {
    final timeStr = match.matchDate != null ? DateFormat('HH:mm').format(match.matchDate!.toLocal()) : 'TBD';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time
          Text(
            timeStr,
            style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          const SizedBox(height: 6),
          // Home
          Text(
            match.homeTeamName ?? 'TBD',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: match.homeTeamName == null ? Colors.white24 : Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'vs',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 7, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 2),
          // Away
          Text(
            match.awayTeamName ?? 'TBD',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: match.awayTeamName == null ? Colors.white24 : Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
