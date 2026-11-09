import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/technician_model.dart';
import '../../providers/technician_provider.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/custom_text_field.dart';

class TechniciansView extends StatefulWidget {
  const TechniciansView({super.key});

  @override
  State<TechniciansView> createState() => _TechniciansViewState();
}

class _TechniciansViewState extends State<TechniciansView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TechnicianProvider>().refreshTechnicians();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({TechnicianModel? technician}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddEditTechnicianDialog(technician: technician),
    );
  }

  Future<void> _handleDelete(TechnicianModel technician) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Technician',
      message: 'Are you sure you want to remove "${technician.name}" from the technician roster?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      final success = await context.read<TechnicianProvider>().deleteTechnician(technician.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Technician removed successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TechnicianProvider>();
    final technicians = provider.filteredTechnicians;

    return MainLayout(
      title: 'Technicians',
      subtitle: 'Manage field engineers, RO plant technicians, and service team members (${provider.allTechnicians.length} total)',
      headerActions: [
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Add Technician'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search & Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by technician name, phone, or specialization...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (val) => provider.setSearchQuery(val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            if (provider.isLoading && provider.allTechnicians.isEmpty)
              const LoadingWidget(message: 'Loading technician roster...')
            else if (technicians.isEmpty)
              EmptyStateWidget(
                title: provider.searchQuery.isNotEmpty ? 'No Technicians Found' : 'No Technicians Registered',
                subtitle: provider.searchQuery.isNotEmpty
                    ? 'No technician matches "${provider.searchQuery}". Try a different keyword.'
                    : 'Click "Add Technician" to register your field service engineers and assign them to plant maintenance jobs.',
                actionLabel: provider.searchQuery.isNotEmpty ? null : 'Add Technician',
                onAction: provider.searchQuery.isNotEmpty ? null : () => _showAddEditDialog(),
              )
            else
              _buildTechniciansGrid(context, technicians),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniciansGrid(BuildContext context, List<TechnicianModel> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 180,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final t = list[index];
            return _buildTechnicianCard(context, t);
          },
        );
      },
    );
  }

  Widget _buildTechnicianCard(BuildContext context, TechnicianModel t) {
    final initials = t.name.trim().isNotEmpty
        ? t.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'TC';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Status, Actions
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                tooltip: 'Edit Technician',
                onPressed: () => _showAddEditDialog(technician: t),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                tooltip: 'Delete Technician',
                onPressed: () => _handleDelete(t),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),

          // Contact Details
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 15, color: AppColors.secondary),
              const SizedBox(width: 8),
              SelectableText(
                t.phoneNumber,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.isActive ? AppColors.successLight : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: t.isActive
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.isActive ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      t.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: t.isActive ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (t.email != null && t.email!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.email!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddEditTechnicianDialog extends StatefulWidget {
  final TechnicianModel? technician;

  const _AddEditTechnicianDialog({this.technician});

  @override
  State<_AddEditTechnicianDialog> createState() => _AddEditTechnicianDialogState();
}

class _AddEditTechnicianDialogState extends State<_AddEditTechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedRole;
  late bool _isActive;
  bool _isSaving = false;

  final List<String> _roleOptions = [
    'Service Technician',
    'Lead RO Engineer',
    'Plant Commissioning Specialist',
    'Maintenance Electrician',
    'Water Quality Specialist',
    'Field Support Technician',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.technician;
    _nameController = TextEditingController(text: t?.name ?? '');
    _phoneController = TextEditingController(text: t?.phoneNumber ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _selectedRole = t != null && _roleOptions.contains(t.role) ? t.role : _roleOptions[0];
    _isActive = t?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<TechnicianProvider>();

    final isEditing = widget.technician != null;
    final model = TechnicianModel(
      id: widget.technician?.id ?? '',
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      role: _selectedRole,
      isActive: _isActive,
      createdAt: widget.technician?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = isEditing
        ? await provider.updateTechnician(model)
        : await provider.addTechnician(model);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Technician updated successfully.' : 'Technician added successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to save technician.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.technician != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(isEditing ? 'Edit Technician' : 'Add New Technician'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'e.g., Rajesh Kumar',
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  isRequired: true,
                  validator: (val) => Validators.required(val, 'Name is required'),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number *',
                  hint: 'e.g., +91 9447012345 or +971 50...',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  isRequired: true,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Designation / Specialization *',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                  ),
                  items: _roleOptions.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address (Optional)',
                  hint: 'e.g., rajesh@nayagra.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Technician', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Available for field service assignments', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Save Changes' : 'Add Technician'),
        ),
      ],
    );
  }
}
