import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../firebase_options.dart';
import '../../widgets/main_layout.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _serviceInterval = AppConstants.defaultServiceIntervalMonths;
  int _dueSoonDays = AppConstants.dueSoonThresholdDays;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: AppStrings.settings,
      subtitle: 'System configuration, Firebase connection status, and service calculation parameters',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Business Profile
                _buildCard(
                  title: 'Water Treatment Enterprise Profile',
                  icon: Icons.business_rounded,
                  children: [
                    _buildRow('Company Name', AppConstants.appName),
                    _buildRow('Business Scope', AppConstants.appTagline),
                    _buildRow('CRM Version', 'v${AppConstants.appVersion} (Production Web)'),
                    _buildRow('Headquarters', 'Ahmedabad, Gujarat, India'),
                    _buildRow('Service Hotline', '+91 98765 43210 (Support Desk)'),
                  ],
                ),
                const SizedBox(height: 24),

                // Firebase & Cloud Database Configuration
                _buildCard(
                  title: 'Firebase Cloud Connection & Database',
                  icon: Icons.cloud_done_rounded,
                  children: [
                    _buildRow('Firebase Project ID', DefaultFirebaseOptions.web.projectId),
                    _buildRow('Auth Domain', DefaultFirebaseOptions.web.authDomain ?? 'nayagrawatertreatmentplants.firebaseapp.com'),
                    _buildRow('Storage Bucket', DefaultFirebaseOptions.web.storageBucket ?? 'nayagrawatertreatmentplants.firebasestorage.app'),
                    _buildRow('Web App ID', DefaultFirebaseOptions.web.appId),
                    _buildRow('Database Mode', 'Live Cloud Firestore (Persistent NoSQL)'),
                  ],
                ),
                const SizedBox(height: 24),

                // Automated Service Parameters
                _buildCard(
                  title: 'Automated 6-Month Scheduling Engine Settings',
                  icon: Icons.timer_outlined,
                  children: [
                    const Text(
                      'The system automatically schedules periodic servicing for all customer plants based on their installation date and previous completed maintenance.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Default Service Interval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              const Text('Calculates next service date after completion', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                initialValue: _serviceInterval,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                                items: const [
                                  DropdownMenuItem(value: 3, child: Text('Every 3 Months (Quarterly)')),
                                  DropdownMenuItem(value: 6, child: Text('Every 6 Months (Standard Water Plant Cycle)')),
                                  DropdownMenuItem(value: 12, child: Text('Every 12 Months (Annual)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _serviceInterval = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due Soon Warning Threshold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              const Text('Triggers yellow warning badge before due date', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                initialValue: _dueSoonDays,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                                items: const [
                                  DropdownMenuItem(value: 15, child: Text('15 Days Before')),
                                  DropdownMenuItem(value: 30, child: Text('30 Days Before (Standard)')),
                                  DropdownMenuItem(value: 45, child: Text('45 Days Before')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _dueSoonDays = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Security & Audit
                _buildCard(
                  title: 'Cloud Database & Security Rules',
                  icon: Icons.security_rounded,
                  children: [
                    _buildRow('Authentication Provider', 'Firebase Authentication (Email & Password)'),
                    _buildRow('Primary Database', 'Google Cloud Firestore (Persistent NoSQL)'),
                    _buildRow('Security Rules', 'Authenticated read/write with role verification'),
                    _buildRow('Service Persistence Guarantee', 'Historical service logs immutable; new records appended'),
                    _buildRow('CSV Export Compatibility', 'Universal RFC4180 CSV export with ISO date headers'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.secondary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
