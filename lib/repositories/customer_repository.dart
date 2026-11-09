import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../core/utils/date_formatter.dart';

class CustomerRepository {
  final CollectionReference<Map<String, dynamic>> _collection;
  final List<CustomerModel> _localCustomers = [];

  CustomerRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseFirestore.instance).collection('customers');

  Stream<List<CustomerModel>> getCustomersStream() {
    try {
      return _collection
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) => CustomerModel.fromFirestore(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _localCustomers.clear();
        _localCustomers.addAll(list);
        return list;
      }).handleError((error) {
        debugPrint('Firestore customer stream error: $error');
        return _localCustomers;
      });
    } catch (e) {
      debugPrint('Firestore customer stream exception: $e');
      return Stream.value(_localCustomers);
    }
  }

  Future<List<CustomerModel>> getCustomers() async {
    try {
      final snapshot = await _collection.get();
      final list = snapshot.docs.map((doc) => CustomerModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _localCustomers.clear();
      _localCustomers.addAll(list);
      return list;
    } catch (e) {
      debugPrint('Firestore getCustomers error: $e');
      return _localCustomers;
    }
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return CustomerModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Firestore getCustomerById error: $e');
    }
    final match = _localCustomers.where((c) => c.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  Future<String> addCustomer(CustomerModel customer) async {
    final nextDate = DateFormatter.addMonths(customer.installationDate, customer.serviceIntervalMonths);
    final enrichedCustomer = customer.copyWith(
      nextServiceDate: nextDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final docRef = await _collection.add(enrichedCustomer.toMap());
      final savedCustomer = enrichedCustomer.copyWith(id: docRef.id);
      _localCustomers.removeWhere((c) => c.id == docRef.id);
      _localCustomers.insert(0, savedCustomer);
      debugPrint('Customer added to Firestore: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore addCustomer fallback: $e');
      final localId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
      final savedCustomer = enrichedCustomer.copyWith(id: localId);
      _localCustomers.removeWhere((c) => c.id == localId);
      _localCustomers.insert(0, savedCustomer);
      return localId;
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final updated = customer.copyWith(updatedAt: DateTime.now());
    try {
      await _collection.doc(customer.id).update(updated.toMap());
    } catch (e) {
      debugPrint('Firestore updateCustomer error: $e');
    }

    final index = _localCustomers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _localCustomers[index] = updated;
    }
  }

  Future<void> updateCustomerServiceDates({
    required String customerId,
    required DateTime lastServiceDate,
    required DateTime nextServiceDate,
    required int totalServicesCompleted,
  }) async {
    try {
      await _collection.doc(customerId).update({
        'lastServiceDate': Timestamp.fromDate(lastServiceDate),
        'nextServiceDate': Timestamp.fromDate(nextServiceDate),
        'totalServicesCompleted': totalServicesCompleted,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Firestore update service dates error: $e');
    }

    final index = _localCustomers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _localCustomers[index] = _localCustomers[index].copyWith(
        lastServiceDate: lastServiceDate,
        nextServiceDate: nextServiceDate,
        totalServicesCompleted: totalServicesCompleted,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteCustomer error: $e');
    }
    _localCustomers.removeWhere((c) => c.id == id);
  }
}
