import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';

class _ProductItemController {
  final TextEditingController nameController;
  final TextEditingController detailsController;

  _ProductItemController({String name = '', String details = ''})
      : nameController = TextEditingController(text: name),
        detailsController = TextEditingController(text: details);

  void dispose() {
    nameController.dispose();
    detailsController.dispose();
  }
}

class AddCustomerView extends StatefulWidget {
  const AddCustomerView({super.key});

  @override
  State<AddCustomerView> createState() => _AddCustomerViewState();
}

class _AddCustomerViewState extends State<AddCustomerView> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  DateTime? _dob;
  String? _gender;

  // Installation
  final _siteNameController = TextEditingController();
  DateTime _installationDate = DateTime.now();
  final String _plantType = 'Water Treatment Plant';
  DateTime? _firstContactDate;

  // Products / Equipment (Multiple allowed)
  final List<_ProductItemController> _productControllers = [
    _ProductItemController(),
  ];

  // Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String _state = 'Kerala';
  final _pinCodeController = TextEditingController();

  // Additional
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _siteNameController.dispose();
    for (final p in _productControllers) {
      p.dispose();
    }
    _addressController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<CustomerProvider>();

    final firstScheduledServiceDate = DateFormatter.addMonths(_installationDate, 6);

    final products = _productControllers
        .where((p) => p.nameController.text.trim().isNotEmpty)
        .map((p) => CustomerProduct(
              name: p.nameController.text.trim(),
              details: p.detailsController.text.trim(),
            ))
        .toList();

    final plantType = products.isNotEmpty
        ? products.map((p) => p.name).join(', ')
        : _plantType;

    final customer = CustomerModel(
      id: '',
      name: _nameController.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      phoneNumber: _phoneController.text.trim(),
      alternatePhoneNumber: _altPhoneController.text.trim().isNotEmpty ? _altPhoneController.text.trim() : null,
      siteName: _siteNameController.text.trim().isNotEmpty ? _siteNameController.text.trim() : _nameController.text.trim(),
      installationDate: _installationDate,
      plantType: plantType,
      firstContactDate: _firstContactDate,
      fullAddress: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _state,
      pinCode: _pinCodeController.text.trim(),
      customerNotes: _notesController.text.trim(),
      nextServiceDate: firstScheduledServiceDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      products: products,
    );

    final customerId = await provider.addCustomer(customer);
    setState(() => _isSaving = false);

    if (customerId != null && mounted) {
      // Trigger silent dashboard stats refresh in the background
      context.read<DashboardProvider>().loadStats(silent: true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.customerCreated),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(RouteNames.customers);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save customer. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstServiceDate = DateFormatter.addMonths(_installationDate, 6);

    return MainLayout(
      title: AppStrings.addCustomer,
      subtitle: 'Register a new customer and schedule initial plant commissioning service',
      headerActions: [
        OutlinedButton(
          onPressed: () => context.go(RouteNames.customers),
          child: const Text('Back to List'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 6-Month Scheduling Automation Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Automated 6-Month Service Scheduling Engine',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Based on the installation date of ${DateFormatter.formatDate(_installationDate)}, Service #1 will automatically be scheduled for ${DateFormatter.formatDate(firstServiceDate)}.',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Personal Information
                  _buildSectionCard(
                    title: '1. Personal Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: CustomTextField(
                              controller: _nameController,
                              label: 'Customer / Organization Name',
                              hint: 'e.g., Apex Solvents Pvt. Ltd. / Rajesh Kumar',
                              isRequired: true,
                              validator: (val) => Validators.required(val, 'Customer name is required'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: CustomDropdown<String>(
                              label: 'Gender',
                              value: _gender,
                              items: AppConstants.genderOptions
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) => setState(() => _gender = val),
                              hint: 'Select Gender',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _phoneController,
                              label: 'Primary Contact Number',
                              hint: 'e.g., +971 50 123 4567 or 9876543210',
                              isRequired: true,
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                              validator: Validators.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _altPhoneController,
                              label: 'Secondary Contact Number (Optional)',
                              hint: 'Alternate mobile or UAE/landline',
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                              validator: (val) => Validators.phone(val, false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dob ?? now,
                                  firstDate: DateTime(1940),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  setState(() => _dob = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date of Birth (Optional)',
                                  suffixIcon: Icon(Icons.cake_outlined, size: 18),
                                ),
                                child: Text(
                                  _dob != null ? DateFormatter.formatDate(_dob) : 'Select Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _dob != null ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Installation Information
                  _buildSectionCard(
                    title: '2. Installation Details & Site Information',
                    icon: Icons.precision_manufacturing_outlined,
                    children: [
                      CustomTextField(
                        controller: _siteNameController,
                        label: 'Site / Facility Name',
                        hint: 'e.g., Plant Unit 2 / Main Cafeteria / Boiler Room',
                        prefixIcon: const Icon(Icons.factory_outlined, size: 18),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _installationDate,
                                  firstDate: DateTime(1980),
                                  lastDate: now.add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _installationDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Installation Date *',
                                  suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                ),
                                child: Text(
                                  DateFormatter.formatDate(_installationDate),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _firstContactDate ?? now,
                                  firstDate: DateTime(1980),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  setState(() => _firstContactDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'First Contact Date (Optional)',
                                  suffixIcon: Icon(Icons.history_toggle_off_rounded, size: 18),
                                ),
                                child: Text(
                                  _firstContactDate != null ? DateFormatter.formatDate(_firstContactDate) : 'Not specified',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _firstContactDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Installed Products & Equipment Details
                  _buildSectionCard(
                    title: '3. Installed Products & Equipment Details',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      const Text(
                        'Add all equipment and plant products installed for this customer (e.g. 1054 Carbon filter, RO plant, Softener). You can add multiple products below.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _productControllers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _productControllers[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Product #${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_productControllers.length > 1)
                                      IconButton(
                                        tooltip: 'Remove Product',
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                        onPressed: () {
                                          setState(() {
                                            final removed = _productControllers.removeAt(index);
                                            removed.dispose();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: CustomTextField(
                                        controller: item.nameController,
                                        label: 'Product / Equipment Name',
                                        hint: 'e.g., 1054 Carbon filter',
                                        prefixIcon: const Icon(Icons.water_rounded, size: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 3,
                                      child: CustomTextField(
                                        controller: item.detailsController,
                                        label: 'Product Details / Description',
                                        hint: 'e.g., FRP 1054 vessel with activated carbon media',
                                        prefixIcon: const Icon(Icons.description_outlined, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _productControllers.add(_ProductItemController());
                            });
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Another Product'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Address Information
                  _buildSectionCard(
                    title: '4. Address Information',
                    icon: Icons.location_on_outlined,
                    children: [
                      CustomTextField(
                        controller: _addressController,
                        label: 'Full Address / Street',
                        hint: 'Plot / Building number, industrial road, landmark...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _cityController,
                              label: 'City',
                              hint: 'e.g., Vaikom / Kottayam / Kochi',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomDropdown<String>(
                              label: 'State',
                              value: _state,
                              items: AppConstants.indianStates
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _state = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _pinCodeController,
                              label: 'PIN Code',
                              hint: '6-digit PIN',
                              keyboardType: TextInputType.number,
                              validator: Validators.pinCode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 5: Notes
                  _buildSectionCard(
                    title: '5. Additional Remarks & Water Specifications',
                    icon: Icons.notes_rounded,
                    children: [
                      CustomTextField(
                        controller: _notesController,
                        label: 'Customer Notes & Technical Requirements',
                        hint: 'Raw water source, feed TDS ppm, required permeate flow, special membrane dosing instructions...',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => context.go(RouteNames.customers),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveCustomer,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isSaving ? 'Registering Customer...' : 'Save & Schedule 1st Service'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
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
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

