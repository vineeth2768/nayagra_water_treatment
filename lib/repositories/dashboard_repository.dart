import '../models/customer_model.dart';
import '../models/service_model.dart';
import '../core/constants/app_constants.dart';
import 'customer_repository.dart';
import 'service_repository.dart';

class DashboardStats {
  final int totalCustomers;
  final int totalInstalledPlants;
  final int upcomingServices;
  final int overdueServices;
  final int completedServices;
  final int servicesDueThisMonth;

  final List<CustomerModel> recentCustomers;
  final List<ServiceModel> upcomingSchedule;
  final List<ServiceModel> recentCompletedServices;
  final List<ServiceModel> overdueAlerts;
  final Map<String, int> plantTypeDistribution;
  final Map<String, int> monthlyServiceActivity; // e.g. "Jul": 4, "Aug": 6...

  DashboardStats({
    required this.totalCustomers,
    required this.totalInstalledPlants,
    required this.upcomingServices,
    required this.overdueServices,
    required this.completedServices,
    required this.servicesDueThisMonth,
    required this.recentCustomers,
    required this.upcomingSchedule,
    required this.recentCompletedServices,
    required this.overdueAlerts,
    required this.plantTypeDistribution,
    required this.monthlyServiceActivity,
  });
}

class DashboardRepository {
  final CustomerRepository _customerRepository;
  final ServiceRepository _serviceRepository;

  DashboardRepository({
    required CustomerRepository customerRepository,
    required ServiceRepository serviceRepository,
  })  : _customerRepository = customerRepository,
        _serviceRepository = serviceRepository;

  Future<DashboardStats> getDashboardStats() async {
    final customers = await _customerRepository.getCustomers();
    final services = await _serviceRepository.getServices();

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    int overdueCount = 0;
    int upcomingCount = 0;
    int completedCount = 0;
    int dueThisMonthCount = 0;

    final List<ServiceModel> overdueList = [];
    final List<ServiceModel> upcomingList = [];
    final List<ServiceModel> completedList = [];

    for (final service in services) {
      if (service.status == AppConstants.statusCompleted) {
        completedCount++;
        completedList.add(service);
      } else {
        if (service.isOverdue) {
          overdueCount++;
          overdueList.add(service);
        } else {
          upcomingCount++;
          upcomingList.add(service);
        }

        if (service.serviceDate.month == currentMonth &&
            service.serviceDate.year == currentYear) {
          dueThisMonthCount++;
        }
      }
    }

    // Sort lists
    upcomingList.sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
    overdueList.sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
    completedList.sort((a, b) => (b.completedDate ?? b.updatedAt).compareTo(a.completedDate ?? a.updatedAt));

    // Plant distribution
    final Map<String, int> distribution = {};
    for (final c in customers) {
      distribution[c.plantType] = (distribution[c.plantType] ?? 0) + 1;
    }

    // Monthly service activity (last 6 months to current)
    final Map<String, int> monthlyActivity = {};
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final label = '${monthNames[date.month - 1]} ${date.year.toString().substring(2)}';
      monthlyActivity[label] = 0;
    }

    for (final service in services) {
      final date = service.isCompleted ? (service.completedDate ?? service.updatedAt) : service.serviceDate;
      final label = '${monthNames[date.month - 1]} ${date.year.toString().substring(2)}';
      if (monthlyActivity.containsKey(label)) {
        monthlyActivity[label] = (monthlyActivity[label] ?? 0) + 1;
      }
    }

    return DashboardStats(
      totalCustomers: customers.length,
      totalInstalledPlants: customers.where((c) => c.isActive).length,
      upcomingServices: upcomingCount,
      overdueServices: overdueCount,
      completedServices: completedCount,
      servicesDueThisMonth: dueThisMonthCount,
      recentCustomers: customers.take(5).toList(),
      upcomingSchedule: upcomingList.take(5).toList(),
      recentCompletedServices: completedList.take(5).toList(),
      overdueAlerts: overdueList,
      plantTypeDistribution: distribution,
      monthlyServiceActivity: monthlyActivity,
    );
  }
}

