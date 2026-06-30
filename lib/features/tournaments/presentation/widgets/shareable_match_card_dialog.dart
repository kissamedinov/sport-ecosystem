import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class ShareableMatchCardDialog extends StatefulWidget {
  final Uint8List pngBytes;
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final String status;
  final DateTime? matchDate;

  const ShareableMatchCardDialog({
    Key? key,
    required this.pngBytes,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    this.matchDate,
  }) : super(key: key);

  @override
  State<ShareableMatchCardDialog> createState() => _ShareableMatchCardDialogState();
}

class _ShareableMatchCardDialogState extends State<ShareableMatchCardDialog> {
  bool _isSaving = false;

  Future<void> _saveToStorage() async {
    setState(() => _isSaving = true);
    try {
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
        final fileName = 'match_${widget.homeTeamName}_vs_${widget.awayTeamName}_${DateTime.now().millisecondsSinceEpoch}.png'
            .replaceAll(RegExp(r'[^\w\-_.]'), '_');
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(widget.pngBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('match.card_saved'.tr(namedArgs: {'path': filePath})),
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
            content: Text('match.save_failed'.tr(namedArgs: {'error': e.toString()})),
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

  void _copyTextReport() {
    final dateStr = widget.matchDate != null 
        ? DateFormat('dd.MM.yyyy HH:mm').format(widget.matchDate!.toLocal()) 
        : 'match.not_scheduled'.tr();
    
    final report = '''
${'match.share_match_result_header'.tr()}
⚔️ ${widget.homeTeamName} vs ${widget.awayTeamName}
${'match.share_score'.tr(namedArgs: {'score': '${widget.homeScore} - ${widget.awayScore}'})}
${'match.share_status'.tr(namedArgs: {'status': widget.status == 'FINISHED' ? 'match.status_finished'.tr() : 'match.status_in_progress'.tr()})}
${'match.share_date'.tr(namedArgs: {'date': dateStr})}
${'match.share_footer'.tr()}
''';

    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('match.report_copied'.tr()),
        backgroundColor: const Color(0xFF2979FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF161F37).withOpacity(0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'match.share_match'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Captured image preview in premium card frame
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    widget.pngBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveToStorage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving 
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        'match.download'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyTextReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2640),
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white10),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: Text(
                        'common.copy'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
