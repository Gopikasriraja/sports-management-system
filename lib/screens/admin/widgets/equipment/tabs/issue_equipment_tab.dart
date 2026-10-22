import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../models/equipment_issue_model.dart';
import '../../../../home/widgets/glass_card.dart';
import '../components/issue_log_card.dart';
import '../components/return_equipment_dialog.dart';

class IssueEquipmentTab extends StatelessWidget {
  final List<EquipmentIssueModel> list;
  final Color primaryColor;
  final bool isDark;

  const IssueEquipmentTab({
    super.key,
    required this.list,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.assignment_ind_outlined, size: 64, color: primaryColor.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text('No equipment currently issued out to students.', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final i = list[index];
          return IssueLogCard(
            issue: i,
            isDark: isDark,
          );
        },
      );
    }

    return GlassCard(
      backgroundOpacity: isDark ? 0.15 : 0.65,
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          columns: const [
            DataColumn(label: Text('Issue ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Athlete Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Equipment', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Qty (Iss / Ret)', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Issue Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Expected Return', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Return Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Issued By', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: list.map((i) {
            final returned = i.status == 'returned';
            return DataRow(
              cells: [
                DataCell(Text(i.issueId, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                DataCell(Text(i.studentName, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(i.equipmentName)),
                DataCell(Text('${i.quantity} / ${i.returnedQuantity}')),
                DataCell(Text(DateFormat('dd-MMM-yyyy').format(i.issueDate))),
                DataCell(Text(DateFormat('dd-MMM-yyyy').format(i.expectedReturnDate))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: returned ? Colors.green.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      i.status.toUpperCase(),
                      style: TextStyle(
                        color: returned ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(i.returnDate != null ? DateFormat('dd-MMM-yyyy').format(i.returnDate!) : 'N/A')),
                DataCell(Text(i.issuedBy)),
                DataCell(
                  returned
                      ? const Text('Completed', style: TextStyle(fontSize: 12, color: Colors.grey))
                      : IconButton(
                          icon: const Icon(Icons.keyboard_return_rounded, color: Colors.green, size: 18),
                          tooltip: 'Return Equipment',
                          onPressed: () => showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => ReturnEquipmentDialog(issue: i),
                          ),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
