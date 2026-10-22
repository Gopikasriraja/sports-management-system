import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../models/equipment_issue_model.dart';
import '../../../../../models/equipment_return_model.dart';
import '../../../../../providers/equipment_provider.dart';
import '../../../../../providers/auth_provider.dart';

class ReturnEquipmentDialog extends StatefulWidget {
  final EquipmentIssueModel issue;

  const ReturnEquipmentDialog({super.key, required this.issue});

  @override
  State<ReturnEquipmentDialog> createState() => _ReturnEquipmentDialogState();
}

class _ReturnEquipmentDialogState extends State<ReturnEquipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qtyCtrl;
  late TextEditingController _remarksCtrl;

  late int _remainingQty;
  DateTime _returnDate = DateTime.now();
  String _condition = 'Good';

  @override
  void initState() {
    super.initState();
    _remainingQty = widget.issue.quantity - widget.issue.returnedQuantity;
    _qtyCtrl = TextEditingController(text: _remainingQty.toString());
    _remarksCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _returnEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context);

    final equipProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final qty = int.parse(_qtyCtrl.text);
    final receiver = authProvider.currentUser?.name ?? authProvider.currentUser?.email ?? 'Sports Staff';

    final returnModel = EquipmentReturnModel(
      returnId: 'RE-${DateFormat('yyMMddHHmmss').format(DateTime.now())}',
      issueId: widget.issue.issueId,
      returnDate: _returnDate,
      returnedQuantity: qty,
      condition: _condition,
      remarks: _remarksCtrl.text.trim(),
      returnedTo: receiver,
    );

    final success = await equipProvider.returnEquipment(returnModel);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return logged successfully. Stock adjusted.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(equipProvider.errorMessage ?? 'Failed to log return.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.inbox_rounded, color: secondaryColor, size: 28),
          const SizedBox(width: 10),
          const Text('Return Sports Equipment', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Student Athlete',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(widget.issue.studentName),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Equipment Details',
                    border: OutlineInputBorder(),
                  ),
                  child: Text('${widget.issue.equipmentName} (Issued: ${widget.issue.quantity}, Remaining: $_remainingQty)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _qtyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Quantity Returned *',
                    prefixIcon: const Icon(Icons.tag_rounded),
                    border: const OutlineInputBorder(),
                    helperText: 'Max remaining: $_remainingQty',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter quantity';
                    final num = int.tryParse(val);
                    if (num == null || num < 1) return 'Must be >= 1';
                    if (num > _remainingQty) return 'Exceeds remaining quantity';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: const InputDecoration(
                    labelText: 'Returned Condition *',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Good', 'Damaged', 'Lost']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _condition = val!),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _returnDate,
                      firstDate: widget.issue.issueDate,
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() {
                        _returnDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Return Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 14),
                    ),
                    child: Text(DateFormat('dd-MMM-yyyy').format(_returnDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remarks / Damage explanation',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _returnEquipment,
          child: const Text('Log Return'),
        ),
      ],
    );
  }
}
