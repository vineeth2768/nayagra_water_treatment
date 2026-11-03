import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/service_status_badge.dart';
import '../../widgets/complete_service_dialog.dart';
import '../../widgets/reschedule_service_dialog.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/confirmation_dialog.dart';

class UpcomingServicesView extends StatelessWidget {
  const UpcomingServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final services = serviceProvider.upcomingServices;

    return MainLayout(
      title: AppStrings.upcomingServices,
      subtitle: 'Monitor 6-month preventive maintenance cycles, overdue notifications, and dispatch technicians',
      headerActions: [
        OutlinedButton.icon(
          onPressed: () => serviceProvider.exportUpcomingToCsv(),
          icon: const Icon(Icons.file_download_outlined, size: 16),
          label: const Text('Export CSV'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Bar
            _buildFilterBar(context, serviceProvider),
            const SizedBox(height: 20),

            if (serviceProvider.isLoading && serviceProvider.allServices.isEmpty)
              const LoadingWidget(message: 'Loading upcoming services...')
            else if (services.isEmpty)
              EmptyStateWidget(
                icon: Icons.done_all_rounded,
                title: 'No Upcoming Services Found',
                subtitle: serviceProvider.upcomingSearchQuery.isNotEmpty ||
                        serviceProvider.upcomingStatusFilter != null ||
                        serviceProvider.upcomingCityFilter != null
                    ? 'Try clearing active search or date filters.'
                    : 'All water treatment plants are up to date! Great job.',
              )
            else
              _buildUpcomingTable(context, services, serviceProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, ServiceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Search
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, minWidth: 200),
            child: TextField(
              onChanged: provider.setUpcomingSearch,
              decoration: InputDecoration(
                hintText: 'Search customer, site, city...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                suffixIcon: provider.upcomingSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => provider.setUpcomingSearch(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Status Filter
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160, minWidth: 130),
                child: DropdownButtonFormField<String>(
                  initialValue: provider.upcomingStatusFilter ?? 'All',
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Status Filter',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Schedules', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Overdue', child: Text('Overdue Only', style: TextStyle(fontSize: 12, color: AppColors.danger))),
                    DropdownMenuItem(value: 'DueSoon', child: Text('Due Soon (<30d)', style: TextStyle(fontSize: 12, color: AppColors.warning))),
                    DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming (>30d)', style: TextStyle(fontSize: 12, color: AppColors.success))),
                  ],
                  onChanged: (val) => provider.setUpcomingStatusFilter(val == 'All' ? null : val),
                ),
              ),

              // City Filter
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160, minWidth: 120),
                child: DropdownButtonFormField<String>(
                  initialValue: provider.upcomingCityFilter ?? 'All',
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'City Filter',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'All', child: Text('All Cities', style: TextStyle(fontSize: 12))),
                    ...provider.availableCities.map(
                      (city) => DropdownMenuItem(value: city, child: Text(city, style: const TextStyle(fontSize: 12))),
                    ),
                  ],
                  onChanged: (val) => provider.setUpcomingCityFilter(val == 'All' ? null : val),
                ),
              ),

              // Date Range Picker
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                  provider.upcomingDateRange != null
                      ? '${DateFormatter.formatShortDate(provider.upcomingDateRange!.start)} - ${DateFormatter.formatShortDate(provider.upcomingDateRange!.end)}'
                      : 'Date Range',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    initialDateRange: provider.upcomingDateRange,
                  );
                  if (picked != null) {
                    provider.setUpcomingDateRange(picked);
                  }
                },
              ),

              if (provider.upcomingSearchQuery.isNotEmpty ||
                  provider.upcomingStatusFilter != null ||
                  provider.upcomingCityFilter != null ||
                  provider.upcomingDateRange != null)
                TextButton.icon(
                  onPressed: () => provider.resetUpcomingFilters(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTable(BuildContext context, List<ServiceModel> services, ServiceProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width > 1200
                ? MediaQuery.of(context).size.width - 320
                : 1100,
          ),
          child: DataTable(
            headingRowHeight: 46,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 66,
            horizontalMargin: 20,
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('CUSTOMER')),
              DataColumn(label: Text('CONTACT')),
              DataColumn(label: Text('SITE / LOCATION')),
              DataColumn(label: Text('PLANT TYPE')),
              DataColumn(label: Text('CYCLE')),
              DataColumn(label: Text('SERVICE DUE DATE')),
              DataColumn(label: Text('REMAINING')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: services.map((s) {
              final isOverdue = s.isOverdue;
              final isDueSoon = s.isDueSoon;

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (isOverdue) {
                    return AppColors.dangerLight.withValues(alpha: 0.15);
                  }
                  return null;
                }),
                cells: [
                  // Customer Name
                  DataCell(
                    InkWell(
                      onTap: () => context.go('/customers/${s.customerId}'),
                      child: Text(
                        s.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  // Contact
                  DataCell(
                    Text(s.customerPhone.isNotEmpty ? s.customerPhone : '-', style: const TextStyle(fontSize: 13)),
                  ),
                  // Site & City
                  DataCell(
                    Text(
                      s.city.isNotEmpty ? '${s.siteName} (${s.city})' : s.siteName,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  // Plant Type
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(s.plantType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  // Service Number
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Service #${s.serviceNumber}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ),
                  ),
                  // Due Date
                  DataCell(
                    Text(
                      DateFormatter.formatDate(s.serviceDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Days Remaining
                  DataCell(
                    Text(
                      DateFormatter.formatRemainingDays(s.serviceDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOverdue
                            ? AppColors.danger
                            : (isDueSoon ? AppColors.warning : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  // Status Badge
                  DataCell(
                    ServiceStatusBadge(
                      status: s.dynamicStatus,
                      isDueSoon: isDueSoon,
                    ),
                  ),
                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Reschedule Service',
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textSecondary),
                          onPressed: () async {
                            final newDate = await RescheduleServiceDialog.show(context, s);
                            if (newDate != null && context.mounted) {
                              await provider.rescheduleService(serviceId: s.id, newDate: newDate);
                              if (context.mounted) {
                                context.read<DashboardProvider>().loadStats(silent: true);
                              }
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete Service',
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                          onPressed: () async {
                            final confirm = await ConfirmationDialog.show(
                              context,
                              title: 'Delete Service',
                              message: 'Are you sure you want to delete this scheduled service for "${s.customerName}"?',
                              confirmText: 'Delete',
                              isDestructive: true,
                            );
                            if (confirm == true && context.mounted) {
                              final success = await provider.deleteService(s.id);
                              if (success && context.mounted) {
                                context.read<DashboardProvider>().loadStats(silent: true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Service scheduled entry deleted.'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final res = await CompleteServiceDialog.show(context, s);
                            if (res != null && context.mounted) {
                              await provider.markServiceCompleted(
                                serviceId: s.id,
                                completedDate: res['completedDate'],
                                technicianName: res['technicianName'],
                                serviceNotes: res['serviceNotes'],
                                changesMade: res['changesMade'],
                              );
                              if (context.mounted) {
                                context.read<DashboardProvider>().loadStats(silent: true);
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
                          label: const Text('Complete'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
