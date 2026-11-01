import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';

class ServiceModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String siteName;
  final String city;
  final String plantType;
  final DateTime? installationDate;
  final int serviceNumber;
  final DateTime serviceDate;
  final DateTime? completedDate;
  final String status; // 'Upcoming', 'Completed', 'Overdue'
  final String? technicianName;
  final String? serviceNotes;
  final String? changesMade;
  final DateTime? nextServiceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.siteName = '',
    this.city = '',
    this.plantType = '',
    this.installationDate,
    required this.serviceNumber,
    required this.serviceDate,
    this.completedDate,
    required this.status,
    this.technicianName,
    this.serviceNotes,
    this.changesMade,
    this.nextServiceDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Automatically computes whether an upcoming service has become overdue
  String get dynamicStatus {
    if (status == AppConstants.statusCompleted) {
      return AppConstants.statusCompleted;
    }
    if (DateFormatter.isOverdue(serviceDate)) {
      return AppConstants.statusOverdue;
    }
    return AppConstants.statusUpcoming;
  }

  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isOverdue => dynamicStatus == AppConstants.statusOverdue;
  bool get isDueSoon => !isCompleted && !isOverdue && DateFormatter.isDueSoon(serviceDate);

  int get daysRemaining => DateFormatter.daysRemaining(serviceDate);

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'siteName': siteName,
      'city': city,
      'plantType': plantType,
      'installationDate': installationDate != null ? Timestamp.fromDate(installationDate!) : null,
      'serviceNumber': serviceNumber,
      'serviceDate': Timestamp.fromDate(serviceDate),
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'status': status,
      'technicianName': technicianName,
      'serviceNotes': serviceNotes,
      'changesMade': changesMade,
      'nextServiceDate': nextServiceDate != null ? Timestamp.fromDate(nextServiceDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ServiceModel.fromMap(data, doc.id);
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ServiceModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      siteName: map['siteName'] ?? '',
      city: map['city'] ?? '',
      plantType: map['plantType'] ?? '',
      installationDate: parseDateTime(map['installationDate']),
      serviceNumber: (map['serviceNumber'] as num?)?.toInt() ?? 1,
      serviceDate: parseDateTime(map['serviceDate']) ?? DateTime.now(),
      completedDate: parseDateTime(map['completedDate']),
      status: map['status'] ?? AppConstants.statusUpcoming,
      technicianName: map['technicianName'],
      serviceNotes: map['serviceNotes'],
      changesMade: map['changesMade'],
      nextServiceDate: parseDateTime(map['nextServiceDate']),
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  ServiceModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? siteName,
    String? city,
    String? plantType,
    DateTime? installationDate,
    int? serviceNumber,
    DateTime? serviceDate,
    DateTime? completedDate,
    String? status,
    String? technicianName,
    String? serviceNotes,
    String? changesMade,
    DateTime? nextServiceDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      siteName: siteName ?? this.siteName,
      city: city ?? this.city,
      plantType: plantType ?? this.plantType,
      installationDate: installationDate ?? this.installationDate,
      serviceNumber: serviceNumber ?? this.serviceNumber,
      serviceDate: serviceDate ?? this.serviceDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      technicianName: technicianName ?? this.technicianName,
      serviceNotes: serviceNotes ?? this.serviceNotes,
      changesMade: changesMade ?? this.changesMade,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

