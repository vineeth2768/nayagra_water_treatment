class AppConstants {
  static const String appName = 'Nayagra Water Treatment Plants';
  static const String appTagline = 'Introducing customized water treatment plants using latest technologies at an affordable price';
  static const String companyAddress = 'Nayagra Water Treatment Plants, Udayanapuram Vaikom, Kottayam, Kerala';
  static const String appVersion = '1.0.0';

  // Service Interval
  static const int defaultServiceIntervalMonths = 6;
  static const int dueSoonThresholdDays = 30;

  // Plant Types
  static const List<String> plantTypes = [
    'Domestic RO Plant',
    'Commercial RO Plant (250 LPH)',
    'Commercial RO Plant (500 LPH)',
    'Industrial RO Plant (1000+ LPH)',
    'Water Softener System',
    'Sewage Treatment Plant (STP)',
    'Effluent Treatment Plant (ETP)',
    'Demineralization (DM) Plant',
    'Ultrafiltration (UF) System',
    'Iron & Sand Media Filter',
  ];

  // Gender options
  static const List<String> genderOptions = [
    'Male',
    'Female',
    'Other',
  ];

  // Service Statuses
  static const String statusUpcoming = 'Upcoming';
  static const String statusCompleted = 'Completed';
  static const String statusOverdue = 'Overdue';

  // Common Indian States
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Delhi',
    'Gujarat',
    'Haryana',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
    'Other',
  ];

  // Pagination
  static const int defaultPageSize = 10;
}

