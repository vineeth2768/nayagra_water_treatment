import 'dart:async';
import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../controllers/customer_controller.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/csv_exporter.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerController _controller;
  StreamSubscription<List<CustomerModel>>? _subscription;

  List<CustomerModel> _allCustomers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search & Filter state
  String _searchQuery = '';
  String? _selectedPlantType;
  String? _selectedServiceStatus; // 'All', 'Upcoming', 'Overdue', 'Completed'
  String _sortBy = 'installationDate_desc';

  // Pagination state
  int _currentPage = 1;
  final int _pageSize = AppConstants.defaultPageSize;

  CustomerProvider({required CustomerController controller})
      : _controller = controller {
    _initStream();
  }

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _subscription = _controller.getCustomersStream().listen(
      (customers) {
        _allCustomers = customers;
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

  List<CustomerModel> get allCustomers => _allCustomers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String? get selectedPlantType => _selectedPlantType;
  String? get selectedServiceStatus => _selectedServiceStatus;
  String get sortBy => _sortBy;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  void setPlantTypeFilter(String? plantType) {
    _selectedPlantType = plantType;
    _currentPage = 1;
    notifyListeners();
  }

  void setServiceStatusFilter(String? status) {
    _selectedServiceStatus = status;
    _currentPage = 1;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    _currentPage = 1;
    notifyListeners();
  }

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedPlantType = null;
    _selectedServiceStatus = null;
    _sortBy = 'installationDate_desc';
    _currentPage = 1;
    notifyListeners();
  }

  List<CustomerModel> get filteredCustomers {
    var result = List<CustomerModel>.from(_allCustomers);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((c) {
        final nameMatch = c.name.toLowerCase().contains(q);
        final phoneMatch = c.phoneNumber.contains(q) || (c.alternatePhoneNumber?.contains(q) ?? false);
        final siteMatch = c.siteName.toLowerCase().contains(q);
        final cityMatch = c.city.toLowerCase().contains(q);
        final plantMatch = c.plantType.toLowerCase().contains(q);
        return nameMatch || phoneMatch || siteMatch || cityMatch || plantMatch;
      }).toList();
    }

    if (_selectedPlantType != null && _selectedPlantType!.isNotEmpty && _selectedPlantType != 'All') {
      result = result.where((c) => c.plantType == _selectedPlantType).toList();
    }

    if (_selectedServiceStatus != null && _selectedServiceStatus!.isNotEmpty && _selectedServiceStatus != 'All') {
      result = result.where((c) {
        if (_selectedServiceStatus == AppConstants.statusOverdue) {
          return c.nextServiceDate != null && DateFormatter.isOverdue(c.nextServiceDate!);
        } else if (_selectedServiceStatus == AppConstants.statusUpcoming) {
          return c.nextServiceDate != null && !DateFormatter.isOverdue(c.nextServiceDate!);
        } else if (_selectedServiceStatus == AppConstants.statusCompleted) {
          return c.totalServicesCompleted > 0;
        }
        return true;
      }).toList();
    }

    switch (_sortBy) {
      case 'name_asc':
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'installationDate_asc':
        result.sort((a, b) => a.installationDate.compareTo(b.installationDate));
        break;
      case 'installationDate_desc':
      default:
        result.sort((a, b) => b.installationDate.compareTo(a.installationDate));
        break;
    }

    return result;
  }

  List<CustomerModel> get paginatedCustomers {
    final filtered = filteredCustomers;
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= filtered.length) {
      return [];
    }
    final endIndex = (startIndex + _pageSize > filtered.length) ? filtered.length : startIndex + _pageSize;
    return filtered.sublist(startIndex, endIndex);
  }

  int get totalPages {
    final count = filteredCustomers.length;
    if (count == 0) return 1;
    return (count / _pageSize).ceil();
  }

  Future<String?> addCustomer(CustomerModel customer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final id = await _controller.createCustomer(customer);
      final newCustomer = customer.copyWith(
        id: id,
        nextServiceDate: DateFormatter.addMonths(customer.installationDate, 6),
      );
      if (!_allCustomers.any((c) => c.id == id)) {
        _allCustomers.insert(0, newCustomer);
      }
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _controller.updateCustomer(customer);
      final index = _allCustomers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _allCustomers[index] = customer;
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

  Future<bool> deleteCustomer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _controller.deleteCustomer(id);
      _allCustomers.removeWhere((c) => c.id == id);
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

  CustomerModel? getCustomerById(String id) {
    try {
      return _allCustomers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void exportCustomersToCsv() {
    final headers = [
      'Customer Name',
      'Contact Number',
      'Alternate Contact',
      'Site Name',
      'Plant Type',
      'Installation Date',
      'Next Service Date',
      'City',
      'State',
      'PIN Code',
      'Address',
      'Services Completed',
      'Notes'
    ];

    final rows = <List<dynamic>>[headers];

    for (final c in filteredCustomers) {
      rows.add([
        c.name,
        c.phoneNumber,
        c.alternatePhoneNumber ?? '',
        c.siteName,
        c.plantType,
        DateFormatter.formatShortDate(c.installationDate),
        DateFormatter.formatShortDate(c.nextServiceDate),
        c.city,
        c.state,
        c.pinCode,
        c.fullAddress,
        c.totalServicesCompleted,
        c.customerNotes,
      ]);
    }

    CsvExporter.exportToCsv(
      filename: 'nayagra_customers_${DateFormatter.formatShortDate(DateTime.now()).replaceAll('/', '-')}',
      rows: rows,
    );
  }
}
