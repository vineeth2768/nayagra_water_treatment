import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/customer_data_table.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/confirmation_dialog.dart';

class CustomerListView extends StatefulWidget {
  const CustomerListView({super.key});

  @override
  State<CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends State<CustomerListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerProvider>().refreshCustomers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final customers = customerProvider.paginatedCustomers;
    final totalCustomers = customerProvider.filteredCustomers.length;

    return MainLayout(
      title: AppStrings.customers,
      subtitle: 'Manage water treatment plant clients, contracts, and installation records ($totalCustomers total)',
      headerActions: [
        ElevatedButton.icon(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Generating PDF Report... Download will start shortly.'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.primary,
              ),
            );
            await customerProvider.exportCustomersToPdf();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC53030), // Classic PDF Red badge style
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
          label: const Text('Download PDF'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => customerProvider.exportCustomersToCsv(),
          icon: const Icon(Icons.file_download_outlined, size: 16),
          label: const Text('Export CSV'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => context.go(RouteNames.addCustomer),
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Add Customer'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter & Search Controls Bar
            _buildFilterBar(context, customerProvider),
            const SizedBox(height: 20),

            // Content
            if (customerProvider.isLoading && customerProvider.allCustomers.isEmpty)
              const LoadingWidget(message: 'Loading customer directory...')
            else if (customers.isEmpty)
              EmptyStateWidget(
                icon: Icons.person_search_rounded,
                title: 'No Customers Found',
                subtitle: customerProvider.searchQuery.isNotEmpty ||
                        customerProvider.selectedPlantType != null ||
                        customerProvider.selectedServiceStatus != null
                    ? 'Try adjusting your search query or clear active filters.'
                    : 'Get started by creating your first water plant client.',
                actionLabel: 'Add Customer',
                onAction: () => context.go(RouteNames.addCustomer),
              )
            else
              CustomerDataTable(
                customers: customers,
                currentPage: customerProvider.currentPage,
                totalPages: customerProvider.totalPages,
                onPageChanged: customerProvider.setPage,
                onView: (c) => context.go('/customers/${c.id}'),
                onEdit: (c) => context.go('/customers/${c.id}/edit'),
                onDelete: (c) => _handleDeleteCustomer(context, customerProvider, c),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, CustomerProvider provider) {
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
          // Search Input
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, minWidth: 220),
            child: TextField(
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, site, city...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                suffixIcon: provider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => provider.setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Filters Row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Service Status Filter
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160, minWidth: 130),
                child: DropdownButtonFormField<String>(
                  initialValue: provider.selectedServiceStatus ?? 'All',
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Service Status',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: AppConstants.statusUpcoming, child: Text('Upcoming', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: AppConstants.statusOverdue, child: Text('Overdue', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: AppConstants.statusCompleted, child: Text('Completed', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) => provider.setServiceStatusFilter(val == 'All' ? null : val),
                ),
              ),

              // Sort By
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180, minWidth: 140),
                child: DropdownButtonFormField<String>(
                  initialValue: provider.sortBy,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'createdAt_desc', child: Text('Recently Added', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'installationDate_desc', child: Text('Newest Installed', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'installationDate_asc', child: Text('Oldest Installed', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'name_asc', child: Text('Name (A-Z)', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) provider.setSortBy(val);
                  },
                ),
              ),

              // Clear Filters Button
              if (provider.searchQuery.isNotEmpty ||
                  provider.selectedPlantType != null ||
                  provider.selectedServiceStatus != null)
                TextButton.icon(
                  onPressed: () => provider.resetFilters(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteCustomer(
    BuildContext context,
    CustomerProvider provider,
    CustomerModel customer,
  ) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Customer',
      message: 'Are you sure you want to delete "${customer.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm == true && context.mounted) {
      final success = await provider.deleteCustomer(customer.id);
      if (success && context.mounted) {
        context.read<DashboardProvider>().loadStats(silent: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.customerDeleted),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
