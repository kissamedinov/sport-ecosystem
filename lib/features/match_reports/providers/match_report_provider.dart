import 'package:flutter/material.dart';
import '../models/match_report.dart';

class MatchReportProvider extends ChangeNotifier {
  final List<MatchReport> _reports = [];
  bool _isLoading = false;

  List<MatchReport> get reports => _reports;
  bool get isLoading => _isLoading;

  Future<void> submitReport(MatchReport report) async {
    _isLoading = true;
    notifyListeners();

    // Mock delay
    await Future.delayed(const Duration(seconds: 1));

    _reports.add(report);
    _isLoading = false;
    notifyListeners();
  }

  MatchReport? getReportForMatch(String matchId) {
    try {
      return _reports.firstWhere((r) => r.matchId == matchId);
    } catch (_) {
      return null;
    }
  }
}
