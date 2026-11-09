import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/technician_model.dart';

class TechnicianRepository {
  final CollectionReference<Map<String, dynamic>> _collection;
  final List<TechnicianModel> _localTechnicians = [];

  TechnicianRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseFirestore.instance).collection('technicians');

  Stream<List<TechnicianModel>> getTechniciansStream() {
    try {
      return _collection
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) => TechnicianModel.fromFirestore(doc)).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _localTechnicians.clear();
        _localTechnicians.addAll(list);
        return list;
      }).handleError((error) {
        debugPrint('Firestore technicians stream error: $error');
        return _localTechnicians;
      });
    } catch (e) {
      debugPrint('Firestore technicians stream exception: $e');
      return Stream.value(_localTechnicians);
    }
  }

  Future<List<TechnicianModel>> getTechnicians() async {
    try {
      final snapshot = await _collection.get();
      final list = snapshot.docs.map((doc) => TechnicianModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _localTechnicians.clear();
      _localTechnicians.addAll(list);
      return list;
    } catch (e) {
      debugPrint('Firestore getTechnicians error: $e');
      return _localTechnicians;
    }
  }

  Future<String> addTechnician(TechnicianModel technician) async {
    final toSave = technician.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final docRef = await _collection.add(toSave.toMap());
      final saved = toSave.copyWith(id: docRef.id);
      _localTechnicians.removeWhere((t) => t.id == docRef.id);
      _localTechnicians.add(saved);
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore addTechnician fallback: $e');
      final localId = 'tech_${DateTime.now().millisecondsSinceEpoch}';
      final saved = toSave.copyWith(id: localId);
      _localTechnicians.removeWhere((t) => t.id == localId);
      _localTechnicians.add(saved);
      return localId;
    }
  }

  Future<void> updateTechnician(TechnicianModel technician) async {
    final updated = technician.copyWith(updatedAt: DateTime.now());
    try {
      await _collection.doc(technician.id).update(updated.toMap());
    } catch (e) {
      debugPrint('Firestore updateTechnician error: $e');
    }

    final index = _localTechnicians.indexWhere((t) => t.id == technician.id);
    if (index != -1) {
      _localTechnicians[index] = updated;
    }
  }

  Future<void> deleteTechnician(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteTechnician error: $e');
    }
    _localTechnicians.removeWhere((t) => t.id == id);
  }
}

