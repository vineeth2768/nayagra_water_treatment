import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/service_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/service_status_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class ServiceHistoryView extends StatefulWidget {
  const ServiceHistoryView({super.key});

  @override
  State<ServiceHistoryView> createState() => _ServiceHistoryViewState();
}

class _ServiceHistoryViewState extends State<ServiceHistoryView> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final allServices = serviceProvider.allServices;

    // Filter
    var filtered = allServices.where((s) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final match = s.customerName.toLowerCase().contains(q) ||
            s.siteName.toLowerCase().contains(q) ||
            s.city.toLowerCase().contains(q) ||
            (s.technicianName?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'Completed' && !s.isCompleted) return false;
        if (_selectedStatus == 'Overdue' && !s.isOverdue) return false;
        if (_selectedStatus == 'Upcoming' && (s.isCompleted || s.isOverdue)) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    return MainLayout(
      title: AppStrings.serviceHistory,
      subtitle: 'Complete chronological maintenance ledger for all registered water treatment facilities',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter controls
            Container(
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320, minWidth: 220),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search ledger by customer, site, technician...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    children: ['All', 'Upcoming', 'Overdue', 'Completed'].map((status) {
                      final isSelected = _selectedStatus == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: AppColors.secondary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedStatus = status);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (serviceProvider.isLoading && allServices.isEmpty)
              const LoadingWidget(message: 'Loading service ledger...')
            else if (filtered.isEmpty)
              const EmptyStateWidget(
                icon: Icons.history_rounded,
                title: 'No Service Ledger Entries',
                subtitle: 'No records match the current filter selection.',
              )
            else
              Container(
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
                      dataRowMaxHeight: 64,
                      horizontalMargin: 20,
                      columnSpacing: 22,
                      columns: const [
                        DataColumn(label: Text('DATE')),
                        DataColumn(label: Text('CUSTOMER')),
                        DataColumn(label: Text('SITE')),
                        DataColumn(label: Text('SERVICE #')),
                        DataColumn(label: Text('PLANT TYPE')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('TECHNICIAN')),
                        DataColumn(label: Text('PROFILE')),
                      ],
                      rows: filtered.map((s) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                DateFormatter.formatDate(s.isCompleted ? (s.completedDate ?? s.serviceDate) : s.serviceDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: () => context.go('/customers/${s.customerId}'),
                                child: Text(
                                  s.customerName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                                ),
                              ),
                            ),
                            DataCell(Text(s.siteName, style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Text('Service #${s.serviceNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            DataCell(
                              Text(s.plantType, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                            DataCell(
                              ServiceStatusBadge(
                                status: s.dynamicStatus,
                                isDueSoon: s.isDueSoon,
                              ),
                            ),
                            DataCell(
                              Text(s.technicianName ?? '-', style: const TextStyle(fontSize: 12)),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.secondary),
                                onPressed: () => context.go('/customers/${s.customerId}'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
