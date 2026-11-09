import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TechnicianModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.role = 'Service Technician',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory TechnicianModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return TechnicianModel.fromMap(data, doc.id);
  }

  factory TechnicianModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return TechnicianModel(
      id: id,
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      role: map['role'] ?? 'Service Technician',
      isActive: map['isActive'] ?? true,
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  TechnicianModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TechnicianModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

