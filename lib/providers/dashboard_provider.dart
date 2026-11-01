import 'package:flutter/material.dart';
import '../repositories/dashboard_repository.dart';
import '../controllers/dashboard_controller.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardController _controller;

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardProvider({required DashboardController controller})
      : _controller = controller {
    loadStats();
  }

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _controller.loadDashboardStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}

