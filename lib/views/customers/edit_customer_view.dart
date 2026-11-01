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
import '../../routes/route_names.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';

class EditCustomerView extends StatefulWidget {
  final String customerId;

  const EditCustomerView({super.key, required this.customerId});

  @override
  State<EditCustomerView> createState() => _EditCustomerViewState();
}

class _EditCustomerViewState extends State<EditCustomerView> {
  final _formKey = GlobalKey<FormState>();

  CustomerModel? _originalCustomer;
  bool _initialized = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  DateTime? _dob;
  String? _gender;

  late TextEditingController _siteNameController;
  late DateTime _installationDate;
  late String _plantType;
  DateTime? _firstContactDate;

  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late String _state;
  late TextEditingController _pinCodeController;

  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _altPhoneController = TextEditingController();
    _siteNameController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _pinCodeController = TextEditingController();
    _notesController = TextEditingController();
    _installationDate = DateTime.now();
    _plantType = AppConstants.plantTypes[0];
    _state = 'Gujarat';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final customer = context.read<CustomerProvider>().getCustomerById(widget.customerId);
      if (customer != null) {
        _originalCustomer = customer;
        _nameController.text = customer.name;
        _phoneController.text = customer.phoneNumber;
        _altPhoneController.text = customer.alternatePhoneNumber ?? '';
        _dob = customer.dateOfBirth;
        _gender = customer.gender;

        _siteNameController.text = customer.siteName;
        _installationDate = customer.installationDate;
        _plantType = customer.plantType;
        _firstContactDate = customer.firstContactDate;

        _addressController.text = customer.fullAddress;
        _cityController.text = customer.city;
        _state = customer.state.isNotEmpty ? customer.state : 'Gujarat';
        _pinCodeController.text = customer.pinCode;

        _notesController.text = customer.customerNotes;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _siteNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate() || _originalCustomer == null) return;

    setState(() => _isSaving = true);
    final provider = context.read<CustomerProvider>();

    final updated = _originalCustomer!.copyWith(
      name: _nameController.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      phoneNumber: _phoneController.text.trim(),
      alternatePhoneNumber: _altPhoneController.text.trim().isNotEmpty ? _altPhoneController.text.trim() : null,
      siteName: _siteNameController.text.trim(),
      installationDate: _installationDate,
      plantType: _plantType,
      firstContactDate: _firstContactDate,
      fullAddress: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _state,
      pinCode: _pinCodeController.text.trim(),
      customerNotes: _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success = await provider.updateCustomer(updated);
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.customerUpdated),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/customers/${widget.customerId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_originalCustomer == null && _initialized) {
      return MainLayout(
        title: AppStrings.editCustomer,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Customer not found'),
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

    return MainLayout(
      title: 'Edit Customer: ${_originalCustomer?.name ?? ''}',
      subtitle: 'Update plant installation specifications, contact information, and service parameters',
      headerActions: [
        OutlinedButton(
          onPressed: () => context.go('/customers/${widget.customerId}'),
          child: const Text('Cancel'),
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
                  // Personal Information
                  _buildSectionCard(
                    title: '1. Personal Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: CustomTextField(
                              controller: _nameController,
                              label: 'Customer / Organization Name',
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
                              label: 'Secondary Contact Number',
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dob ?? DateTime(1990),
                                  firstDate: DateTime(1940),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _dob = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date of Birth',
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

                  // Installation Information
                  _buildSectionCard(
                    title: '2. Installation Details & Site Information',
                    icon: Icons.precision_manufacturing_outlined,
                    children: [
                      CustomTextField(
                        controller: _siteNameController,
                        label: 'Site / Facility Name',
                        prefixIcon: const Icon(Icons.factory_outlined, size: 18),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _installationDate,
                                  firstDate: DateTime(2015),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
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
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _firstContactDate ?? _installationDate,
                                  firstDate: DateTime(2015),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _firstContactDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'First Contact Date',
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

                  // Address
                  _buildSectionCard(
                    title: '3. Address Information',
                    icon: Icons.location_on_outlined,
                    children: [
                      CustomTextField(
                        controller: _addressController,
                        label: 'Full Address',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _cityController,
                              label: 'City',
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
                              keyboardType: TextInputType.number,
                              validator: Validators.pinCode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Remarks
                  _buildSectionCard(
                    title: '4. Remarks & Technical Notes',
                    icon: Icons.notes_rounded,
                    children: [
                      CustomTextField(
                        controller: _notesController,
                        label: 'Customer Notes',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => context.go('/customers/${widget.customerId}'),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _updateCustomer,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isSaving ? 'Updating...' : 'Save Changes'),
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
