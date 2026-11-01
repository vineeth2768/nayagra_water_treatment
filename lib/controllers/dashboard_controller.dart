import '../repositories/dashboard_repository.dart';

class DashboardController {
  final DashboardRepository _repository;

  DashboardController({required DashboardRepository repository})
      : _repository = repository;

  Future<DashboardStats> loadDashboardStats() async {
    return await _repository.getDashboardStats();
  }
}

