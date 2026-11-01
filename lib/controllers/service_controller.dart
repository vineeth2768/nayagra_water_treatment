import '../models/service_model.dart';
import '../repositories/service_repository.dart';

class ServiceController {
  final ServiceRepository _serviceRepository;

  ServiceController({required ServiceRepository serviceRepository})
      : _serviceRepository = serviceRepository;

  Stream<List<ServiceModel>> getServicesStream() {
    return _serviceRepository.getServicesStream();
  }

  Future<List<ServiceModel>> getAllServices() async {
    return await _serviceRepository.getServices();
  }

  Future<List<ServiceModel>> getCustomerServices(String customerId) async {
    return await _serviceRepository.getServicesForCustomer(customerId);
  }

  Future<void> completeService({
    required String serviceId,
    required DateTime completedDate,
    required String technicianName,
    required String serviceNotes,
    required String changesMade,
  }) async {
    await _serviceRepository.completeService(
      serviceId: serviceId,
      completedDate: completedDate,
      technicianName: technicianName,
      serviceNotes: serviceNotes,
      changesMade: changesMade,
    );
  }

  Future<void> rescheduleService({
    required String serviceId,
    required DateTime newDate,
  }) async {
    await _serviceRepository.rescheduleService(
      serviceId: serviceId,
      newServiceDate: newDate,
    );
  }

  Future<String> addManualService(ServiceModel service) async {
    return await _serviceRepository.addManualService(service);
  }

  Future<void> deleteService(String serviceId) async {
    await _serviceRepository.deleteService(serviceId);
  }
}

