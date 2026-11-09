import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../models/service_model.dart';
import '../providers/technician_provider.dart';
import 'custom_text_field.dart';

class CompleteServiceDialog extends StatefulWidget {
  final ServiceModel service;

  const CompleteServiceDialog({super.key, required this.service});

  static Future<Map<String, dynamic>?> show(BuildContext context, ServiceModel service) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CompleteServiceDialog(service: service),
    );
  }

  @override
  State<CompleteServiceDialog> createState() => _CompleteServiceDialogState();
}

class _CompleteServiceDialogState extends State<CompleteServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _completedDate;
  final _technicianController = TextEditingController();
  final _notesController = TextEditingController();
  final _changesController = TextEditingController();
  bool _initializedTech = false;
  String? _selectedTechId;

  final List<String> _quickNotes = [
    'Filter replacement completed.',
    'Membrane CIP chemical cleaning completed.',
    'High pressure pump checked and serviced.',
    'Water pressure and flow rate adjusted.',
    'RO membrane replaced.',
    'General maintenance & TDS calibration done.',
  ];

  @override
  void initState() {
    super.initState();
    _completedDate = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedTech) {
      final techs = context.read<TechnicianProvider>().activeTechnicians;
      if (techs.isNotEmpty) {
        _selectedTechId = techs.first.id;
        _technicianController.text = techs.first.name;
      }
      _initializedTech = true;
    }
  }

  @override
  void dispose() {
    _technicianController.dispose();
    _notesController.dispose();
    _changesController.dispose();
    super.dispose();
  }

  void _appendQuickNote(String note) {
    setState(() {
      if (_notesController.text.trim().isEmpty) {
        _notesController.text = note;
      } else {
        _notesController.text += '\n$note';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nextCalculated = DateFormatter.addMonths(_completedDate, 6);
    final activeTechs = context.watch<TechnicianProvider>().activeTechnicians;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.successLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Service #${widget.service.serviceNumber}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              widget.service.customerName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info box about 6-month calculation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Completing this service will automatically schedule Service #${widget.service.serviceNumber + 1} for ${DateFormatter.formatDate(nextCalculated)} (+6 months).',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Service Completion Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _completedDate,
                        firstDate: DateTime(1980),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _completedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Completion Date *',
                        suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                      child: Text(
                        DateFormatter.formatDate(_completedDate),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Technician Selection
                  if (activeTechs.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTechId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Technician *',
                        prefixIcon: Icon(Icons.engineering_outlined, size: 18),
                      ),
                      items: [
                        ...activeTechs.map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text('${t.name} (${t.role})', overflow: TextOverflow.ellipsis),
                            )),
                        const DropdownMenuItem(
                          value: '__custom__',
                          child: Text('+ Other / Type Custom Name...'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedTechId = val;
                          if (val != null && val != '__custom__') {
                            final tech = activeTechs.firstWhere((t) => t.id == val);
                            _technicianController.text = tech.name;
                          } else if (val == '__custom__') {
                            _technicianController.clear();
                          }
                        });
                      },
                    ),
                    if (_selectedTechId == '__custom__') ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _technicianController,
                        label: 'Custom Technician Name *',
                        hint: 'e.g., Rajesh Verma / Service Team Alpha',
                        isRequired: true,
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter technician name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ] else ...[
                    CustomTextField(
                      controller: _technicianController,
                      label: 'Technician Name *',
                      hint: 'e.g., Rajesh Verma / Service Team Alpha',
                      isRequired: true,
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter technician name';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Quick notes tags
                  const Text(
                    'Quick Notes Suggestions:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickNotes.map((note) {
                      return ActionChip(
                        label: Text(note, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.background,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () => _appendQuickNote(note),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Service Notes (Multiline)
                  CustomTextField(
                    controller: _notesController,
                    label: 'Service Notes / Work Performed',
                    hint: 'Enter detailed work performed, pressure readings, TDS levels...',
                    isRequired: true,
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide service notes describing the work performed';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Changes / Parts Replaced
                  CustomTextField(
                    controller: _changesController,
                    label: 'Changes Made / Consumables Replaced (Optional)',
                    hint: 'e.g., Replaced 5-micron spool filter, 2kg Antiscalant added, dosing pump calibrated',
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.of(context).pop({
                              'completedDate': _completedDate,
                              'technicianName': _technicianController.text.trim(),
                              'serviceNotes': _notesController.text.trim(),
                              'changesMade': _changesController.text.trim(),
                            });
                          }
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Confirm & Save Completion'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

