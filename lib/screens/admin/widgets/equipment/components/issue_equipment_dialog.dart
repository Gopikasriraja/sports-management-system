import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../models/equipment_model.dart';
import '../../../../../models/equipment_issue_model.dart';
import '../../../../../models/student_model.dart';
import '../../../../../providers/equipment_provider.dart';
import '../../../../../providers/student_provider.dart';
import '../../../../../providers/auth_provider.dart';

class IssueEquipmentDialog extends StatefulWidget {
  final EquipmentModel? preSelected;

  const IssueEquipmentDialog({super.key, this.preSelected});

  @override
  State<IssueEquipmentDialog> createState() => _IssueEquipmentDialogState();
}

class _IssueEquipmentDialogState extends State<IssueEquipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qtyCtrl;

  DateTime _issueDate = DateTime.now();
  late DateTime _expectedReturn;

  EquipmentModel? _selectedEquip;
  StudentModel? _selectedStudent;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
    _expectedReturn = DateTime.now().add(const Duration(days: 7));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final equipProvider = Provider.of<EquipmentProvider>(context, listen: false);
      final studProvider = Provider.of<StudentProvider>(context, listen: false);

      final availableEquips = equipProvider.equipmentList.where((e) => e.availableQuantity > 0).toList();
      final studentList = studProvider.students;

      if (availableEquips.isEmpty && widget.preSelected == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No equipment available to issue.'), backgroundColor: Colors.orange),
        );
        return;
      }

      if (studentList.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students registered in system database.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() {
        _selectedEquip = widget.preSelected ?? availableEquips.first;
        _selectedStudent = studentList.first;
      });
    });
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _issueEquipment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEquip == null || _selectedStudent == null) return;

    Navigator.pop(context);

    final equipProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final qty = int.parse(_qtyCtrl.text);
    final currentCoach = authProvider.currentUser?.name ?? authProvider.currentUser?.email ?? 'Sports Staff';

    final issueModel = EquipmentIssueModel(
      issueId: 'IS-${DateFormat('yyMMddHHmmss').format(DateTime.now())}',
      equipmentId: _selectedEquip!.equipmentId,
      studentId: _selectedStudent!.studentId,
      issueDate: _issueDate,
      status: 'issued',
      quantity: qty,
      expectedReturnDate: _expectedReturn,
      issuedBy: currentCoach,
      studentName: _selectedStudent!.name,
      equipmentName: _selectedEquip!.equipmentName,
    );

    final success = await equipProvider.issueEquipment(issueModel);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipment issued successfully.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(equipProvider.errorMessage ?? 'Failed to issue equipment.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedEquip == null || _selectedStudent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    final equipProvider = Provider.of<EquipmentProvider>(context);
    final studProvider = Provider.of<StudentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final availableEquips = equipProvider.equipmentList.where((e) => e.availableQuantity > 0).toList();
    final studentList = studProvider.students;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.outbox_rounded, color: secondaryColor, size: 28),
          const SizedBox(width: 10),
          const Text('Issue Sports Equipment', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<StudentModel>(
                  initialValue: _selectedStudent,
                  decoration: const InputDecoration(
                    labelText: 'Select Student Athlete *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: studentList.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        '${s.name} (${s.registerNumber}) - ${s.department}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedStudent = val),
                ),
                const SizedBox(height: 12),
                if (widget.preSelected != null)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Selected Equipment',
                      prefixIcon: Icon(Icons.sports_soccer_rounded),
                      border: OutlineInputBorder(),
                    ),
                    child: Text('${_selectedEquip!.equipmentName} (${_selectedEquip!.availableQuantity} available)'),
                  )
                else
                  DropdownButtonFormField<EquipmentModel>(
                    initialValue: _selectedEquip,
                    decoration: const InputDecoration(
                      labelText: 'Select Equipment *',
                      prefixIcon: Icon(Icons.sports_soccer_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: availableEquips.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          '${e.equipmentName} (${e.availableQuantity} left)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedEquip = val;
                        _qtyCtrl.text = '1';
                      });
                    },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _qtyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Quantity to Issue *',
                    prefixIcon: const Icon(Icons.tag_rounded),
                    border: const OutlineInputBorder(),
                    helperText: 'Max available: ${_selectedEquip!.availableQuantity}',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter quantity';
                    final num = int.tryParse(val);
                    if (num == null || num < 1) return 'Must be >= 1';
                    if (num > _selectedEquip!.availableQuantity) return 'Not enough stock!';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _issueDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 3)),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() {
                              _issueDate = picked;
                              if (_expectedReturn.isBefore(_issueDate)) {
                                _expectedReturn = _issueDate.add(const Duration(days: 7));
                              }
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Issue Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today_rounded, size: 14),
                          ),
                          child: Text(DateFormat('dd-MMM-yyyy').format(_issueDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expectedReturn,
                            firstDate: _issueDate.add(const Duration(days: 1)),
                            lastDate: _issueDate.add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setState(() => _expectedReturn = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expected Return',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today_rounded, size: 14),
                          ),
                          child: Text(DateFormat('dd-MMM-yyyy').format(_expectedReturn)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Authorized Issued By',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(authProvider.currentUser?.name ?? authProvider.currentUser?.email ?? 'Sports Staff'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _issueEquipment,
          child: const Text('Issue Goods'),
        ),
      ],
    );
  }
}
