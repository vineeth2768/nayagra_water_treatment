import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../models/customer_model.dart';
import '../../models/service_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/service_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/service_status_badge.dart';
import '../../widgets/complete_service_dialog.dart';
import '../../widgets/reschedule_service_dialog.dart';
import '../../widgets/empty_state_widget.dart';

class CustomerDetailsView extends StatefulWidget {
  final String customerId;

  const CustomerDetailsView({super.key, required this.customerId});

  @override
  State<CustomerDetailsView> createState() => _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends State<CustomerDetailsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final customer = customerProvider.getCustomerById(widget.customerId);

    if (customer == null) {
      return MainLayout(
        title: AppStrings.customerDetails,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Customer profile not found'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.customers),
                child: const Text('Back to Customers'),
              ),
            ],
          ),
        ),
      );
    }

    final services = serviceProvider.getCustomerServiceHistory(customer.id);
    final isOverdue = customer.nextServiceDate != null && DateFormatter.isOverdue(customer.nextServiceDate!);
    final isDueSoon = customer.nextServiceDate != null && DateFormatter.isDueSoon(customer.nextServiceDate!);

    return MainLayout(
      title: customer.name,
      subtitle: '${customer.siteName} • ${customer.plantType}',
      headerActions: [
        OutlinedButton.icon(
          onPressed: () => context.go(RouteNames.customers),
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Customers'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Generating Customer Plant Report PDF...'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.primary,
              ),
            );
            await PdfExporter.exportCustomerProfilePdf(
              customer: customer,
              services: services,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC53030),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
          label: const Text('Download PDF'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => context.go('/customers/${customer.id}/edit'),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit Customer'),
        ),
      ],
      child: Column(
        children: [
          // Header summary banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AppColors.surface,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.secondaryLight,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ServiceStatusBadge(
                            status: isOverdue
                                ? AppConstants.statusOverdue
                                : (customer.totalServicesCompleted > 0 && customer.nextServiceDate == null
                                    ? AppConstants.statusCompleted
                                    : AppConstants.statusUpcoming),
                            isDueSoon: isDueSoon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${customer.phoneNumber}   •   Site: ${customer.siteName}   •   Location: ${customer.city}, ${customer.state}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Next Service Pill
                if (customer.nextServiceDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.dangerLight
                          : (isDueSoon ? AppColors.warningLight : AppColors.successLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOverdue
                            ? AppColors.danger.withValues(alpha: 0.3)
                            : (isDueSoon
                                ? AppColors.warning.withValues(alpha: 0.3)
                                : AppColors.success.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'NEXT SERVICE DUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isOverdue
                                ? AppColors.danger
                                : (isDueSoon ? AppColors.warning : AppColors.success),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.formatDate(customer.nextServiceDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          DateFormatter.formatRemainingDays(customer.nextServiceDate!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Tabs Bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.secondary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: [
                const Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: '1. Overview'),
                Tab(
                  icon: const Icon(Icons.history_rounded, size: 18),
                  text: '2. 6-Month Service History (${services.length})',
                ),
                const Tab(icon: Icon(Icons.notes_rounded, size: 18), text: '3. Technical Notes'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Overview
                _buildOverviewTab(context, customer),

                // Tab 2: Chronological Timeline Service History
                _buildServiceHistoryTimeline(context, customer, services, serviceProvider),

                // Tab 3: Notes
                _buildNotesTab(context, customer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, CustomerModel customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Details Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildInfoCard(
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                        title: 'Installation & Equipment',
                        icon: Icons.precision_manufacturing_outlined,
                        items: [
                          {'label': 'Plant / Product Type', 'value': customer.plantType},
                          {'label': 'Site Name', 'value': customer.siteName},
                          {'label': 'Commissioning Date', 'value': DateFormatter.formatDate(customer.installationDate)},
                          {'label': 'First Contact Date', 'value': DateFormatter.formatDate(customer.firstContactDate)},
                          {'label': 'Default Service Cycle', 'value': 'Every 6 Months'},
                          {'label': 'Total Cycles Completed', 'value': '${customer.totalServicesCompleted} Completed'},
                        ],
                      ),
                      _buildInfoCard(
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                        title: 'Contact Information',
                        icon: Icons.contact_phone_outlined,
                        items: [
                          {'label': 'Primary Contact', 'value': customer.phoneNumber},
                          {'label': 'Secondary Contact', 'value': customer.alternatePhoneNumber ?? '-'},
                          {'label': 'Gender', 'value': customer.gender ?? '-'},
                          {'label': 'Date of Birth', 'value': DateFormatter.formatDate(customer.dateOfBirth)},
                          {'label': 'Registered Since', 'value': DateFormatter.formatDate(customer.createdAt)},
                        ],
                      ),
                      _buildInfoCard(
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                        title: 'Site Location & Address',
                        icon: Icons.location_on_outlined,
                        items: [
                          {'label': 'Street Address', 'value': customer.fullAddress.isNotEmpty ? customer.fullAddress : '-'},
                          {'label': 'City', 'value': customer.city.isNotEmpty ? customer.city : '-'},
                          {'label': 'State', 'value': customer.state.isNotEmpty ? customer.state : '-'},
                          {'label': 'PIN Code', 'value': customer.pinCode.isNotEmpty ? customer.pinCode : '-'},
                        ],
                      ),
                      _buildInfoCard(
                        width: constraints.maxWidth > 700 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                        title: 'Maintenance Status',
                        icon: Icons.speed_rounded,
                        items: [
                          {'label': 'Last Service Completed', 'value': DateFormatter.formatDate(customer.lastServiceDate)},
                          {'label': 'Next Service Due', 'value': DateFormatter.formatDate(customer.nextServiceDate)},
                          {'label': 'Days Remaining', 'value': customer.nextServiceDate != null ? DateFormatter.formatRemainingDays(customer.nextServiceDate!) : '-'},
                          {'label': 'System Health', 'value': customer.isActive ? 'Active & Monitored' : 'Inactive'},
                        ],
                      ),
                      if (customer.products.isNotEmpty)
                        Container(
                          width: constraints.maxWidth,
                          padding: const EdgeInsets.all(20),
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
                                  const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.secondary),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Installed Products & Equipment',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${customer.products.length} Items',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...customer.products.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final prod = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '#$index',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                            ),
                                            if (prod.details.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                prod.details,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required double width,
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
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
              Icon(icon, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item['label']!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['value']!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServiceHistoryTimeline(
    BuildContext context,
    CustomerModel customer,
    List<ServiceModel> services,
    ServiceProvider provider,
  ) {
    if (services.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.history_rounded,
        title: 'No Service Records Scheduled',
        subtitle: 'The 6-month automated schedule was not generated or has been cleared.',
        actionLabel: 'Schedule 1st Service',
        onAction: () async {
          await provider.addManualService(
            ServiceModel(
              id: '',
              customerId: customer.id,
              customerName: customer.name,
              customerPhone: customer.phoneNumber,
              siteName: customer.siteName,
              city: customer.city,
              plantType: customer.plantType,
              serviceNumber: 1,
              serviceDate: DateFormatter.addMonths(customer.installationDate, 6),
              status: AppConstants.statusUpcoming,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Commissioning baseline node
              _buildTimelineCommissioningNode(customer),

              // Service items
              ...services.asMap().entries.map((entry) {
                final index = entry.key;
                final service = entry.value;
                final isLast = index == services.length - 1;
                return _buildTimelineServiceItem(context, service, provider, isLast);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCommissioningNode(CustomerModel customer) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, size: 16, color: Colors.white),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: AppColors.border,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Plant Installation & Commissioning',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormatter.formatDate(customer.installationDate),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Installed ${customer.plantType} at ${customer.siteName}. 6-month automated maintenance cycle initiated.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineServiceItem(
    BuildContext context,
    ServiceModel service,
    ServiceProvider provider,
    bool isLast,
  ) {
    final isCompleted = service.isCompleted;
    final isOverdue = service.isOverdue;
    final isDueSoon = service.isDueSoon;

    Color badgeColor = AppColors.success;
    if (isCompleted) {
      badgeColor = AppColors.info;
    } else if (isOverdue) {
      badgeColor = AppColors.danger;
    } else if (isDueSoon) {
      badgeColor = AppColors.warning;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line + node
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : (isOverdue ? Icons.priority_high_rounded : Icons.schedule_rounded),
                  size: 16,
                  color: badgeColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOverdue ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border,
                  width: isOverdue ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Service #${service.serviceNumber}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 10),
                          ServiceStatusBadge(
                            status: service.dynamicStatus,
                            isDueSoon: isDueSoon,
                          ),
                        ],
                      ),
                      Text(
                        DateFormatter.formatDate(isCompleted ? (service.completedDate ?? service.serviceDate) : service.serviceDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (isCompleted) ...[
                    if (service.technicianName != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Serviced by: ${service.technicianName}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (service.serviceNotes != null && service.serviceNotes!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service.serviceNotes!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (service.changesMade != null && service.changesMade!.isNotEmpty) ...[
                      Text(
                        'Parts Replaced / Work Done: ${service.changesMade}',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ],
                  ] else ...[
                    // Upcoming or Overdue Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.formatRemainingDays(service.serviceDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOverdue ? AppColors.danger : (isDueSoon ? AppColors.warning : AppColors.textSecondary),
                          ),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final newDate = await RescheduleServiceDialog.show(context, service);
                                if (newDate != null && context.mounted) {
                                  await provider.rescheduleService(
                                    serviceId: service.id,
                                    newDate: newDate,
                                  );
                                }
                              },
                              icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                              label: const Text('Reschedule', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onPressed: () async {
                                final res = await CompleteServiceDialog.show(context, service);
                                if (res != null && context.mounted) {
                                  await provider.markServiceCompleted(
                                    serviceId: service.id,
                                    completedDate: res['completedDate'],
                                    technicianName: res['technicianName'],
                                    serviceNotes: res['serviceNotes'],
                                    changesMade: res['changesMade'],
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(AppStrings.serviceCompleted),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check, size: 14),
                              label: const Text('Mark Completed', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, CustomerModel customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notes_rounded, color: AppColors.secondary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Customer & Plant Operational Notes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 18),
                if (customer.customerNotes.trim().isEmpty)
                  const Text(
                    'No special remarks or notes have been logged for this customer. Click "Edit Customer" to add technical feed details, TDS targets, or operating guidelines.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                  )
                else
                  Text(
                    customer.customerNotes,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

