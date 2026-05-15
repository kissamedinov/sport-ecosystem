import 'package:flutter/material.dart';
import '../data/models/quiz_model.dart';
import '../data/repositories/quiz_repository.dart';

class QuizProvider with ChangeNotifier {
  final QuizRepository _repository;

  DailyQuiz? _currentQuiz;
  bool _isLoading = false;
  String? _error;

  QuizProvider(this._repository);

  DailyQuiz? get currentQuiz => _currentQuiz;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDailyQuiz() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentQuiz = await _repository.getDailyQuiz();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitScore(int score) async {
    try {
      await _repository.submitQuizAttempt(score);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
