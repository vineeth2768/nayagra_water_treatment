import 'dart:async';
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../controllers/service_controller.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/csv_exporter.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceController _controller;
  StreamSubscription<List<ServiceModel>>? _subscription;

  List<ServiceModel> _allServices = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Upcoming filters
  String _upcomingSearchQuery = '';
  String? _upcomingStatusFilter; // 'All', 'Overdue', 'DueSoon', 'Upcoming'
  String? _upcomingCityFilter;
  DateTimeRange? _upcomingDateRange;

  // Completed filters
  String _completedSearchQuery = '';
  DateTimeRange? _completedDateRange;

  ServiceProvider({required ServiceController controller})
      : _controller = controller {
    _initStream();
  }

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _subscription = _controller.getServicesStream().listen(
      (services) {
        _allServices = services;
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

  List<ServiceModel> get allServices => _allServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Upcoming Getters & Setters
  String get upcomingSearchQuery => _upcomingSearchQuery;
  String? get upcomingStatusFilter => _upcomingStatusFilter;
  String? get upcomingCityFilter => _upcomingCityFilter;
  DateTimeRange? get upcomingDateRange => _upcomingDateRange;

  void setUpcomingSearch(String query) {
    _upcomingSearchQuery = query;
    notifyListeners();
  }

  void setUpcomingStatusFilter(String? status) {
    _upcomingStatusFilter = status;
    notifyListeners();
  }

  void setUpcomingCityFilter(String? city) {
    _upcomingCityFilter = city;
    notifyListeners();
  }

  void setUpcomingDateRange(DateTimeRange? range) {
    _upcomingDateRange = range;
    notifyListeners();
  }

  void resetUpcomingFilters() {
    _upcomingSearchQuery = '';
    _upcomingStatusFilter = null;
    _upcomingCityFilter = null;
    _upcomingDateRange = null;
    notifyListeners();
  }

  // Completed Getters & Setters
  String get completedSearchQuery => _completedSearchQuery;
  DateTimeRange? get completedDateRange => _completedDateRange;

  void setCompletedSearch(String query) {
    _completedSearchQuery = query;
    notifyListeners();
  }

  void setCompletedDateRange(DateTimeRange? range) {
    _completedDateRange = range;
    notifyListeners();
  }

  void resetCompletedFilters() {
    _completedSearchQuery = '';
    _completedDateRange = null;
    notifyListeners();
  }

  /// All non-completed services filtered and sorted by nearest due date
  List<ServiceModel> get upcomingServices {
    var result = _allServices.where((s) => s.status != AppConstants.statusCompleted).toList();

    // 1. Search query
    if (_upcomingSearchQuery.trim().isNotEmpty) {
      final q = _upcomingSearchQuery.trim().toLowerCase();
      result = result.where((s) {
        return s.customerName.toLowerCase().contains(q) ||
            s.customerPhone.contains(q) ||
            s.siteName.toLowerCase().contains(q) ||
            s.city.toLowerCase().contains(q) ||
            s.plantType.toLowerCase().contains(q);
      }).toList();
    }

    // 2. City filter
    if (_upcomingCityFilter != null && _upcomingCityFilter!.isNotEmpty && _upcomingCityFilter != 'All') {
      result = result.where((s) => s.city.toLowerCase() == _upcomingCityFilter!.toLowerCase()).toList();
    }

    // 3. Status filter
    if (_upcomingStatusFilter != null && _upcomingStatusFilter!.isNotEmpty && _upcomingStatusFilter != 'All') {
      if (_upcomingStatusFilter == 'Overdue') {
        result = result.where((s) => s.isOverdue).toList();
      } else if (_upcomingStatusFilter == 'DueSoon') {
        result = result.where((s) => s.isDueSoon).toList();
      } else if (_upcomingStatusFilter == 'Upcoming') {
        result = result.where((s) => !s.isOverdue && !s.isDueSoon).toList();
      }
    }

    // 4. Date range filter
    if (_upcomingDateRange != null) {
      result = result.where((s) {
        final d = DateTime(s.serviceDate.year, s.serviceDate.month, s.serviceDate.day);
        final start = DateTime(_upcomingDateRange!.start.year, _upcomingDateRange!.start.month, _upcomingDateRange!.start.day);
        final end = DateTime(_upcomingDateRange!.end.year, _upcomingDateRange!.end.month, _upcomingDateRange!.end.day);
        return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
            (d.isAtSameMomentAs(end) || d.isBefore(end));
      }).toList();
    }

    // Sort by nearest service date
    result.sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
    return result;
  }

  /// All completed services filtered and sorted in reverse chronological order
  List<ServiceModel> get completedServices {
    var result = _allServices.where((s) => s.status == AppConstants.statusCompleted).toList();

    // 1. Search query
    if (_completedSearchQuery.trim().isNotEmpty) {
      final q = _completedSearchQuery.trim().toLowerCase();
      result = result.where((s) {
        return s.customerName.toLowerCase().contains(q) ||
            s.siteName.toLowerCase().contains(q) ||
            (s.technicianName?.toLowerCase().contains(q) ?? false) ||
            (s.serviceNotes?.toLowerCase().contains(q) ?? false) ||
            (s.changesMade?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 2. Date range filter
    if (_completedDateRange != null) {
      result = result.where((s) {
        final d = s.completedDate ?? s.updatedAt;
        final dDay = DateTime(d.year, d.month, d.day);
        final start = DateTime(_completedDateRange!.start.year, _completedDateRange!.start.month, _completedDateRange!.start.day);
        final end = DateTime(_completedDateRange!.end.year, _completedDateRange!.end.month, _completedDateRange!.end.day);
        return (dDay.isAtSameMomentAs(start) || dDay.isAfter(start)) &&
            (dDay.isAtSameMomentAs(end) || dDay.isBefore(end));
      }).toList();
    }

    result.sort((a, b) => (b.completedDate ?? b.updatedAt).compareTo(a.completedDate ?? a.updatedAt));
    return result;
  }

  /// Customer specific history in chronological order
  List<ServiceModel> getCustomerServiceHistory(String customerId) {
    final list = _allServices.where((s) => s.customerId == customerId).toList();
    list.sort((a, b) => a.serviceNumber.compareTo(b.serviceNumber));
    return list;
  }

  List<String> get availableCities {
    final set = <String>{};
    for (final s in _allServices) {
      if (s.city.trim().isNotEmpty) {
        set.add(s.city.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<bool> markServiceCompleted({
    required String serviceId,
    required DateTime completedDate,
    required String technicianName,
    required String serviceNotes,
    required String changesMade,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _controller.completeService(
        serviceId: serviceId,
        completedDate: completedDate,
        technicianName: technicianName,
        serviceNotes: serviceNotes,
        changesMade: changesMade,
      );
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

  Future<bool> rescheduleService({
    required String serviceId,
    required DateTime newDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _controller.rescheduleService(
        serviceId: serviceId,
        newDate: newDate,
      );
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

  Future<bool> addManualService(ServiceModel service) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _controller.addManualService(service);
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

  Future<bool> deleteService(String serviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _controller.deleteService(serviceId);
      _allServices.removeWhere((s) => s.id == serviceId);
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

  void exportUpcomingToCsv() {
    final headers = [
      'Customer Name',
      'Contact Number',
      'Site Name',
      'City',
      'Plant Type',
      'Service #',
      'Service Due Date',
      'Days Remaining',
      'Status'
    ];

    final rows = <List<dynamic>>[headers];

    for (final s in upcomingServices) {
      rows.add([
        s.customerName,
        s.customerPhone,
        s.siteName,
        s.city,
        s.plantType,
        'Service #${s.serviceNumber}',
        DateFormatter.formatShortDate(s.serviceDate),
        DateFormatter.formatRemainingDays(s.serviceDate),
        s.dynamicStatus,
      ]);
    }

    CsvExporter.exportToCsv(
      filename: 'nayagra_upcoming_services_${DateFormatter.formatShortDate(DateTime.now()).replaceAll('/', '-')}',
      rows: rows,
    );
  }

  void exportCompletedToCsv() {
    final headers = [
      'Customer Name',
      'Site Name',
      'Service #',
      'Completed Date',
      'Technician Name',
      'Service Notes',
      'Parts / Changes Made',
      'Next Scheduled Service'
    ];

    final rows = <List<dynamic>>[headers];

    for (final s in completedServices) {
      rows.add([
        s.customerName,
        s.siteName,
        'Service #${s.serviceNumber}',
        DateFormatter.formatShortDate(s.completedDate ?? s.updatedAt),
        s.technicianName ?? '',
        s.serviceNotes ?? '',
        s.changesMade ?? '',
        DateFormatter.formatShortDate(s.nextServiceDate),
      ]);
    }

    CsvExporter.exportToCsv(
      filename: 'nayagra_completed_services_${DateFormatter.formatShortDate(DateTime.now()).replaceAll('/', '-')}',
      rows: rows,
    );
  }
}

