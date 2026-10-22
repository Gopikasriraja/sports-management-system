import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../models/equipment_return_model.dart';
import '../../../../home/widgets/glass_card.dart';

class ReturnsTab extends StatelessWidget {
  final List<EquipmentReturnModel> list;
  final Color primaryColor;
  final bool isDark;

  const ReturnsTab({
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
              Icon(Icons.assignment_turned_in_outlined, size: 64, color: primaryColor.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text('No returns logs logged in the database.', style: TextStyle(fontWeight: FontWeight.bold)),
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
          final r = list[index];
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
                      Text('Return ID: ${r.returnId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Chip(
                        label: Text(r.condition, style: const TextStyle(fontSize: 9)),
                        padding: EdgeInsets.zero,
                        backgroundColor: r.condition == 'Good' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Returned Quantity: ${r.returnedQuantity} units', style: const TextStyle(fontSize: 12)),
                  Text('Return Date: ${DateFormat('dd-MMM-yyyy').format(r.returnDate)}', style: const TextStyle(fontSize: 12)),
                  Text('Received By: ${r.returnedTo}', style: const TextStyle(fontSize: 12)),
                  if (r.remarks.isNotEmpty)
                    Text('Remarks: ${r.remarks}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
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
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          columns: const [
            DataColumn(label: Text('Return ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Issue ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Qty Returned', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Return Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Condition', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Remarks / Explanation', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Received By', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: list.map((r) {
            return DataRow(
              cells: [
                DataCell(Text(r.returnId, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                DataCell(Text(r.issueId, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                DataCell(Text(r.returnedQuantity.toString())),
                DataCell(Text(DateFormat('dd-MMM-yyyy').format(r.returnDate))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: r.condition == 'Good'
                          ? Colors.green.withValues(alpha: 0.08)
                          : (r.condition == 'Damaged' ? Colors.orange.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      r.condition,
                      style: TextStyle(
                        color: r.condition == 'Good'
                            ? Colors.green
                            : (r.condition == 'Damaged' ? Colors.orange : Colors.redAccent),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(r.remarks.isEmpty ? 'N/A' : r.remarks)),
                DataCell(Text(r.returnedTo)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
