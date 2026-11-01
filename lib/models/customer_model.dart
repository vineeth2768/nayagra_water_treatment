import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final DateTime? dateOfBirth;
  final String? gender;
  final String phoneNumber;
  final String? alternatePhoneNumber;
  final String siteName;
  final DateTime installationDate;
  final String plantType;
  final DateTime? firstContactDate;
  final String fullAddress;
  final String city;
  final String state;
  final String pinCode;
  final String customerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final DateTime? nextServiceDate;
  final DateTime? lastServiceDate;
  final int totalServicesCompleted;

  CustomerModel({
    required this.id,
    required this.name,
    this.dateOfBirth,
    this.gender,
    required this.phoneNumber,
    this.alternatePhoneNumber,
    required this.siteName,
    required this.installationDate,
    required this.plantType,
    this.firstContactDate,
    this.fullAddress = '',
    this.city = '',
    this.state = '',
    this.pinCode = '',
    this.customerNotes = '',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.nextServiceDate,
    this.lastServiceDate,
    this.totalServicesCompleted = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'alternatePhoneNumber': alternatePhoneNumber,
      'siteName': siteName,
      'installationDate': Timestamp.fromDate(installationDate),
      'plantType': plantType,
      'firstContactDate': firstContactDate != null ? Timestamp.fromDate(firstContactDate!) : null,
      'fullAddress': fullAddress,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'customerNotes': customerNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'nextServiceDate': nextServiceDate != null ? Timestamp.fromDate(nextServiceDate!) : null,
      'lastServiceDate': lastServiceDate != null ? Timestamp.fromDate(lastServiceDate!) : null,
      'totalServicesCompleted': totalServicesCompleted,
    };
  }

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CustomerModel.fromMap(data, doc.id);
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      dateOfBirth: parseDateTime(map['dateOfBirth']),
      gender: map['gender'],
      phoneNumber: map['phoneNumber'] ?? '',
      alternatePhoneNumber: map['alternatePhoneNumber'],
      siteName: map['siteName'] ?? '',
      installationDate: parseDateTime(map['installationDate']) ?? DateTime.now(),
      plantType: map['plantType'] ?? 'Commercial RO Plant',
      firstContactDate: parseDateTime(map['firstContactDate']),
      fullAddress: map['fullAddress'] ?? map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
      customerNotes: map['customerNotes'] ?? '',
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']) ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      nextServiceDate: parseDateTime(map['nextServiceDate']),
      lastServiceDate: parseDateTime(map['lastServiceDate']),
      totalServicesCompleted: (map['totalServicesCompleted'] as num?)?.toInt() ?? 0,
    );
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? alternatePhoneNumber,
    String? siteName,
    DateTime? installationDate,
    String? plantType,
    DateTime? firstContactDate,
    String? fullAddress,
    String? city,
    String? state,
    String? pinCode,
    String? customerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? nextServiceDate,
    DateTime? lastServiceDate,
    int? totalServicesCompleted,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      alternatePhoneNumber: alternatePhoneNumber ?? this.alternatePhoneNumber,
      siteName: siteName ?? this.siteName,
      installationDate: installationDate ?? this.installationDate,
      plantType: plantType ?? this.plantType,
      firstContactDate: firstContactDate ?? this.firstContactDate,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      customerNotes: customerNotes ?? this.customerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      totalServicesCompleted: totalServicesCompleted ?? this.totalServicesCompleted,
    );
  }
}

