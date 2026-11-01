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

    final customer = CustomerModel(
      id: '',
      name: _nameController.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      phoneNumber: _phoneController.text.trim(),
      alternatePhoneNumber: _altPhoneController.text.trim().isNotEmpty ? _altPhoneController.text.trim() : null,
      siteName: _siteNameController.text.trim().isNotEmpty ? _siteNameController.text.trim() : _nameController.text.trim(),
      installationDate: _installationDate,
      plantType: _plantType,
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
    );

    final customerId = await provider.addCustomer(customer);
    setState(() => _isSaving = false);

    if (customerId != null && mounted) {
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
                              hint: '10-digit mobile number',
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
                              hint: 'Alternate mobile or office landline',
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
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
                                  firstDate: DateTime(2015),
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
                                  firstDate: DateTime(2015),
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

                  // Section 3: Address Information
                  _buildSectionCard(
                    title: '3. Address Information',
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

                  // Section 4: Notes
                  _buildSectionCard(
                    title: '4. Additional Remarks & Water Specifications',
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

