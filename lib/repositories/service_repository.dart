import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/service_model.dart';
import '../models/customer_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import 'customer_repository.dart';

class ServiceRepository {
  final CollectionReference<Map<String, dynamic>> _collection;
  final CustomerRepository _customerRepository;
  final List<ServiceModel> _localServices = [];

  ServiceRepository({
    FirebaseFirestore? firestore,
    required CustomerRepository customerRepository,
  })  : _collection = (firestore ?? FirebaseFirestore.instance).collection('services'),
        _customerRepository = customerRepository;

  Stream<List<ServiceModel>> getServicesStream() {
    try {
      return _collection
          .orderBy('serviceDate', descending: false)
          .snapshots()
          .asyncMap((snapshot) async {
        final customers = await _customerRepository.getCustomers();
        final customerIds = customers.map((c) => c.id).toSet();

        final list = <ServiceModel>[];
        for (final doc in snapshot.docs) {
          final service = ServiceModel.fromFirestore(doc);
          // Auto-cleanup orphaned services whose customer record was deleted
          if (customers.isNotEmpty && !customerIds.contains(service.customerId)) {
            _collection.doc(doc.id).delete().catchError((e) {
              debugPrint('Error deleting orphan service: $e');
            });
            continue;
          }
          list.add(service);
        }
        _localServices.clear();
        _localServices.addAll(list);
        return list;
      }).handleError((error) {
        debugPrint('Firestore service stream error: $error');
        return _localServices;
      });
    } catch (e) {
      debugPrint('Firestore service stream exception: $e');
      return Stream.value(_localServices);
    }
  }

  Future<List<ServiceModel>> getServices() async {
    try {
      final customers = await _customerRepository.getCustomers();
      final customerIds = customers.map((c) => c.id).toSet();

      final snapshot = await _collection.orderBy('serviceDate', descending: false).get();
      final list = <ServiceModel>[];
      for (final doc in snapshot.docs) {
        final service = ServiceModel.fromFirestore(doc);
        // Auto-cleanup orphaned services whose customer record was deleted
        if (customers.isNotEmpty && !customerIds.contains(service.customerId)) {
          _collection.doc(doc.id).delete().catchError((e) {
            debugPrint('Error deleting orphan service: $e');
          });
          continue;
        }
        list.add(service);
      }
      _localServices.clear();
      _localServices.addAll(list);
      return list;
    } catch (e) {
      debugPrint('Firestore getServices error: $e');
      return _localServices;
    }
  }

  Future<void> deleteServicesForCustomer(String customerId) async {
    try {
      final snapshot = await _collection.where('customerId', isEqualTo: customerId).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Firestore deleteServicesForCustomer error: $e');
    }
    _localServices.removeWhere((s) => s.customerId == customerId);
  }

  Future<List<ServiceModel>> getServicesForCustomer(String customerId) async {
    final all = await getServices();
    return all.where((s) => s.customerId == customerId).toList()
      ..sort((a, b) => a.serviceNumber.compareTo(b.serviceNumber));
  }

  Future<String> scheduleFirstService(CustomerModel customer) async {
    final intervalMonths = customer.serviceIntervalMonths > 0 ? customer.serviceIntervalMonths : AppConstants.defaultServiceIntervalMonths;
    final firstServiceDate = DateFormatter.addMonths(customer.installationDate, intervalMonths);

    final firstService = ServiceModel(
      id: '',
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phoneNumber,
      siteName: customer.siteName,
      city: customer.city,
      plantType: customer.plantType,
      installationDate: customer.installationDate,
      serviceNumber: 1,
      serviceDate: firstServiceDate,
      status: AppConstants.statusUpcoming,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final docRef = await _collection.add(firstService.toMap());
      final saved = firstService.copyWith(id: docRef.id);
      _localServices.add(saved);
      debugPrint('Scheduled 1st service in Firestore: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error scheduling 1st service in Firestore: $e');
      final localId = 'srv_${DateTime.now().millisecondsSinceEpoch}';
      final saved = firstService.copyWith(id: localId);
      _localServices.add(saved);
      return localId;
    }
  }

  Future<void> completeService({
    required String serviceId,
    required DateTime completedDate,
    required String technicianName,
    required String serviceNotes,
    required String changesMade,
  }) async {
    final all = await getServices();
    final index = all.indexWhere((s) => s.id == serviceId);
    if (index == -1) return;

    final currentService = all[index];
    final customer = await _customerRepository.getCustomerById(currentService.customerId);
    final intervalMonths = (customer != null && customer.serviceIntervalMonths > 0)
        ? customer.serviceIntervalMonths
        : AppConstants.defaultServiceIntervalMonths;
    final nextServiceDate = DateFormatter.addMonths(completedDate, intervalMonths);

    final updatedCurrentService = currentService.copyWith(
      status: AppConstants.statusCompleted,
      completedDate: completedDate,
      technicianName: technicianName,
      serviceNotes: serviceNotes,
      changesMade: changesMade,
      nextServiceDate: nextServiceDate,
      updatedAt: DateTime.now(),
    );

    try {
      await _collection.doc(serviceId).update(updatedCurrentService.toMap());
    } catch (e) {
      debugPrint('Firestore completeService update error: $e');
    }

    final localIdx = _localServices.indexWhere((s) => s.id == serviceId);
    if (localIdx != -1) {
      _localServices[localIdx] = updatedCurrentService;
    } else {
      _localServices.add(updatedCurrentService);
    }

    final nextServiceNumber = currentService.serviceNumber + 1;
    final nextService = ServiceModel(
      id: '',
      customerId: currentService.customerId,
      customerName: currentService.customerName,
      customerPhone: currentService.customerPhone,
      siteName: currentService.siteName,
      city: currentService.city,
      plantType: currentService.plantType,
      installationDate: currentService.installationDate,
      serviceNumber: nextServiceNumber,
      serviceDate: nextServiceDate,
      status: AppConstants.statusUpcoming,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final docRef = await _collection.add(nextService.toMap());
      _localServices.add(nextService.copyWith(id: docRef.id));
    } catch (e) {
      debugPrint('Firestore nextService add error: $e');
      _localServices.add(nextService.copyWith(id: 'srv_${DateTime.now().millisecondsSinceEpoch}'));
    }

    await _customerRepository.updateCustomerServiceDates(
      customerId: currentService.customerId,
      lastServiceDate: completedDate,
      nextServiceDate: nextServiceDate,
      totalServicesCompleted: currentService.serviceNumber,
    );
  }

  Future<void> rescheduleService({
    required String serviceId,
    required DateTime newServiceDate,
  }) async {
    try {
      await _collection.doc(serviceId).update({
        'serviceDate': Timestamp.fromDate(newServiceDate),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Firestore reschedule error: $e');
    }

    final localIdx = _localServices.indexWhere((s) => s.id == serviceId);
    if (localIdx != -1) {
      final updated = _localServices[localIdx].copyWith(
        serviceDate: newServiceDate,
        updatedAt: DateTime.now(),
      );
      _localServices[localIdx] = updated;

      await _customerRepository.updateCustomerServiceDates(
        customerId: updated.customerId,
        lastServiceDate: updated.installationDate ?? DateTime.now(),
        nextServiceDate: newServiceDate,
        totalServicesCompleted: updated.serviceNumber - 1,
      );
    }
  }

  Future<String> addManualService(ServiceModel service) async {
    try {
      final docRef = await _collection.add(service.toMap());
      final saved = service.copyWith(id: docRef.id);
      _localServices.add(saved);
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore addManualService error: $e');
      final localId = 'srv_${DateTime.now().millisecondsSinceEpoch}';
      final saved = service.copyWith(id: localId);
      _localServices.add(saved);
      return localId;
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _collection.doc(serviceId).delete();
    } catch (e) {
      debugPrint('Firestore deleteService error: $e');
    }
    _localServices.removeWhere((s) => s.id == serviceId);
  }
}
