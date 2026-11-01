import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class CompletedServicesView extends StatelessWidget {
  const CompletedServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final services = serviceProvider.completedServices;

    return MainLayout(
      title: AppStrings.completedServices,
      subtitle: 'Audit log of completed maintenance, technician interventions, and parts replacements',
      headerActions: [
        OutlinedButton.icon(
          onPressed: () => serviceProvider.exportCompletedToCsv(),
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
              const LoadingWidget(message: 'Loading completed service history...')
            else if (services.isEmpty)
              EmptyStateWidget(
                icon: Icons.assignment_turned_in_outlined,
                title: 'No Completed Services Found',
                subtitle: serviceProvider.completedSearchQuery.isNotEmpty ||
                        serviceProvider.completedDateRange != null
                    ? 'Try clearing active search or date filters.'
                    : 'When technicians complete a scheduled 6-month service, it will be permanently cataloged here.',
              )
            else
              _buildCompletedTable(context, services),
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
            constraints: const BoxConstraints(maxWidth: 340, minWidth: 220),
            child: TextField(
              onChanged: provider.setCompletedSearch,
              decoration: InputDecoration(
                hintText: 'Search customer, technician, parts...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                suffixIcon: provider.completedSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => provider.setCompletedSearch(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Date Range
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                  provider.completedDateRange != null
                      ? '${DateFormatter.formatShortDate(provider.completedDateRange!.start)} - ${DateFormatter.formatShortDate(provider.completedDateRange!.end)}'
                      : 'Date Completed Range',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: provider.completedDateRange,
                  );
                  if (picked != null) {
                    provider.setCompletedDateRange(picked);
                  }
                },
              ),
              if (provider.completedSearchQuery.isNotEmpty || provider.completedDateRange != null) ...[
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => provider.resetCompletedFilters(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTable(BuildContext context, List<ServiceModel> services) {
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
            dataRowMaxHeight: 74,
            horizontalMargin: 20,
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('CUSTOMER')),
              DataColumn(label: Text('SITE')),
              DataColumn(label: Text('CYCLE')),
              DataColumn(label: Text('COMPLETED ON')),
              DataColumn(label: Text('TECHNICIAN')),
              DataColumn(label: Text('SERVICE WORK / NOTES')),
              DataColumn(label: Text('NEXT SCHEDULED')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: services.map((s) {
              return DataRow(
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
                  // Site
                  DataCell(
                    Text(s.siteName.isNotEmpty ? s.siteName : '-', style: const TextStyle(fontSize: 13)),
                  ),
                  // Service Number
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Service #${s.serviceNumber}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.info),
                      ),
                    ),
                  ),
                  // Completed Date
                  DataCell(
                    Text(
                      DateFormatter.formatDate(s.completedDate ?? s.updatedAt),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  // Technician
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin_circle_outlined, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          s.technicianName ?? 'Unassigned',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Notes & Changes
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.serviceNotes ?? 'No notes recorded',
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (s.changesMade != null && s.changesMade!.isNotEmpty)
                            Text(
                              'Replaced: ${s.changesMade}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Next Service Date
                  DataCell(
                    Text(
                      DateFormatter.formatDate(s.nextServiceDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Actions
                  DataCell(
                    IconButton(
                      tooltip: 'View Full Service Report',
                      icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
                      onPressed: () => _showServiceReportDialog(context, s),
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

  void _showServiceReportDialog(BuildContext context, ServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.info, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Service Report #${service.serviceNumber}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _reportRow('Customer', service.customerName),
                _reportRow('Plant Site', service.siteName),
                _reportRow('Plant Type', service.plantType),
                _reportRow('Completed Date', DateFormatter.formatDate(service.completedDate ?? service.updatedAt)),
                _reportRow('Lead Technician', service.technicianName ?? '-'),
                _reportRow('Next Scheduled Service', DateFormatter.formatDate(service.nextServiceDate)),
                const SizedBox(height: 12),
                const Text('Work Performed / Service Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    service.serviceNotes ?? 'No notes recorded.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                if (service.changesMade != null && service.changesMade!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Parts Replaced & Consumables:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      service.changesMade!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
