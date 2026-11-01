import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import '../models/customer_model.dart';
import 'service_status_badge.dart';

class CustomerDataTable extends StatelessWidget {
  final List<CustomerModel> customers;
  final void Function(CustomerModel)? onEdit;
  final void Function(CustomerModel)? onDelete;
  final void Function(CustomerModel)? onView;
  final int currentPage;
  final int totalPages;
  final void Function(int)? onPageChanged;

  const CustomerDataTable({
    super.key,
    required this.customers,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table container with horizontal scroll
          SingleChildScrollView(
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
                columnSpacing: 24,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                columns: const [
                  DataColumn(label: Text('CUSTOMER NAME')),
                  DataColumn(label: Text('CONTACT NUMBER')),
                  DataColumn(label: Text('SITE NAME')),
                  DataColumn(label: Text('CITY')),
                  DataColumn(label: Text('PLANT TYPE')),
                  DataColumn(label: Text('INSTALLED')),
                  DataColumn(label: Text('NEXT SERVICE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: customers.map((c) {
                  final isOverdue = c.nextServiceDate != null && DateFormatter.isOverdue(c.nextServiceDate!);
                  final isDueSoon = c.nextServiceDate != null && DateFormatter.isDueSoon(c.nextServiceDate!);
                  final status = isOverdue
                      ? AppConstants.statusOverdue
                      : (c.totalServicesCompleted > 0 && c.nextServiceDate == null
                          ? AppConstants.statusCompleted
                          : AppConstants.statusUpcoming);

                  return DataRow(
                    cells: [
                      // Name
                      DataCell(
                        InkWell(
                          onTap: () => onView?.call(c),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                              if (c.totalServicesCompleted > 0)
                                Text(
                                  '${c.totalServicesCompleted} services completed',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Phone
                      DataCell(
                        Text(
                          c.phoneNumber,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      // Site
                      DataCell(
                        Text(
                          c.siteName.isNotEmpty ? c.siteName : '-',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      // City
                      DataCell(
                        Text(
                          c.city.isNotEmpty ? c.city : '-',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                          child: Text(
                            c.plantType,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      // Installation Date
                      DataCell(
                        Text(
                          DateFormatter.formatDate(c.installationDate),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      // Next Service Date
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormatter.formatDate(c.nextServiceDate),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                              ),
                            ),
                            if (c.nextServiceDate != null)
                              Text(
                                DateFormatter.formatRemainingDays(c.nextServiceDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? AppColors.danger
                                      : (isDueSoon ? AppColors.warning : AppColors.textMuted),
                                  fontWeight: isOverdue || isDueSoon ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Status Badge
                      DataCell(
                        ServiceStatusBadge(
                          status: status,
                          isDueSoon: isDueSoon,
                        ),
                      ),
                      // Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'View Profile & History',
                              icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.secondary),
                              onPressed: () => onView?.call(c),
                            ),
                            IconButton(
                              tooltip: 'Edit Customer',
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                              onPressed: () => onEdit?.call(c),
                            ),
                            IconButton(
                              tooltip: 'Delete Customer',
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                              onPressed: () => onDelete?.call(c),
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

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing Page $currentPage of $totalPages',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: currentPage > 1 && onPageChanged != null
                          ? () => onPageChanged!(currentPage - 1)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$currentPage',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: currentPage < totalPages && onPageChanged != null
                          ? () => onPageChanged!(currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
