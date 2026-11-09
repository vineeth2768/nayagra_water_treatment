import 'dart:async';
import 'package:flutter/material.dart';
import '../models/technician_model.dart';
import '../controllers/technician_controller.dart';

class TechnicianProvider extends ChangeNotifier {
  final TechnicianController _controller;
  StreamSubscription<List<TechnicianModel>>? _subscription;

  List<TechnicianModel> _allTechnicians = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  TechnicianProvider({required TechnicianController controller})
      : _controller = controller {
    _initStream();
  }

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _subscription = _controller.getTechniciansStream().listen(
      (technicians) {
        _allTechnicians = technicians;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<TechnicianModel> get allTechnicians => _allTechnicians;
  List<TechnicianModel> get activeTechnicians =>
      _allTechnicians.where((t) => t.isActive).toList();

  List<TechnicianModel> get filteredTechnicians {
    if (_searchQuery.trim().isEmpty) return _allTechnicians;
    final q = _searchQuery.trim().toLowerCase();
    return _allTechnicians.where((t) {
      final nameMatch = t.name.toLowerCase().contains(q);
      final phoneMatch = t.phoneNumber.contains(q);
      final roleMatch = t.role.toLowerCase().contains(q);
      return nameMatch || phoneMatch || roleMatch;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> refreshTechnicians() async {
    try {
      final list = await _controller.getAllTechnicians();
      if (list.isNotEmpty) {
        _allTechnicians = list;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing technicians: $e');
    }
  }

  Future<bool> addTechnician(TechnicianModel technician) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final id = await _controller.addTechnician(technician);
      final saved = technician.copyWith(id: id);
      _allTechnicians.removeWhere((t) => t.id == id);
      _allTechnicians.insert(0, saved);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTechnician(TechnicianModel technician) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _controller.updateTechnician(technician);
      final index = _allTechnicians.indexWhere((t) => t.id == technician.id);
      if (index != -1) {
        _allTechnicians[index] = technician;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTechnician(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _controller.deleteTechnician(id);
      _allTechnicians.removeWhere((t) => t.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

