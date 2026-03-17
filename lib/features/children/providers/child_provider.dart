import 'package:flutter/material.dart';
import '../data/repositories/child_repository.dart';
import '../models/child.dart';

class ChildProvider extends ChangeNotifier {
  final ChildRepository _repository;
  List<Child> _children = [];
  bool _isLoading = false;
  String? _error;

  ChildProvider(this._repository);

  List<Child> get children => _children;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _awards = [];

  List<Map<String, dynamic>> get activities => _activities;
  List<Map<String, dynamic>> get awards => _awards;

  Future<void> fetchChildren() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _children = await _repository.getMyChildren();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActivities(String childId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _activities = await _repository.getChildActivities(childId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAwards(String childId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _awards = await _repository.getChildAwards(childId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
