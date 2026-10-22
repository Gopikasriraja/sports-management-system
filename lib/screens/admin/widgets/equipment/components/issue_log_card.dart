import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../models/equipment_issue_model.dart';
import 'return_equipment_dialog.dart';

class IssueLogCard extends StatelessWidget {
  final EquipmentIssueModel issue;
  final bool isDark;

  const IssueLogCard({
    super.key,
    required this.issue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final returned = issue.status == 'returned';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(issue.equipmentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: returned ? Colors.green.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.status.toUpperCase(),
                    style: TextStyle(
                      color: returned ? Colors.green : Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Issued To: ${issue.studentName}', style: const TextStyle(fontSize: 12)),
            Text('Quantity Issued: ${issue.quantity} unit(s) (Returned: ${issue.returnedQuantity})', style: const TextStyle(fontSize: 12)),
            Text('Issue Date: ${DateFormat('dd-MMM-yyyy').format(issue.issueDate)}', style: const TextStyle(fontSize: 12)),
            Text('Expected Return: ${DateFormat('dd-MMM-yyyy').format(issue.expectedReturnDate)}', style: const TextStyle(fontSize: 12)),
            if (issue.returnDate != null)
              Text('Actual Return: ${DateFormat('dd-MMM-yyyy').format(issue.returnDate!)}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            if (!returned)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => ReturnEquipmentDialog(issue: issue),
                    ),
                    icon: const Icon(Icons.keyboard_return_rounded, size: 16),
                    label: const Text('Return Goods', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
