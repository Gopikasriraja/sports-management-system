import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../models/equipment_model.dart';
import '../../../../../models/equipment_issue_model.dart';
import '../../../../../models/equipment_return_model.dart';
import '../../../../home/widgets/glass_card.dart';

class ReportsTab extends StatelessWidget {
  final List<EquipmentModel> list;
  final List<EquipmentIssueModel> issues;
  final List<EquipmentReturnModel> returns;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  const ReportsTab({
    super.key,
    required this.list,
    required this.issues,
    required this.returns,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  void _exportReport(BuildContext context, String reportType) {
    final buffer = StringBuffer();
    final nowStr = DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now());

    if (reportType == 'inventory' || reportType == 'stock') {
      buffer.writeln('MRCAS SPORTS DEPARTMENT - INVENTORY STOCK REPORT');
      buffer.writeln('Generated on: $nowStr\n');
      buffer.writeln('=' * 80);
      buffer.writeln('${'ID'.padRight(15)} ${'EQUIPMENT NAME'.padRight(20)} ${'CATEGORY'.padRight(12)} ${'TOTAL'.padRight(6)} ${'AVAIL'.padRight(6)} ${'ISSUED'.padRight(6)} ${'DAMAGED'.padRight(7)}');
      buffer.writeln('=' * 80);
      for (final e in list) {
        buffer.writeln(
          '${e.equipmentId.padRight(15)} '
          '${e.equipmentName.padRight(20).substring(0, e.equipmentName.length > 19 ? 19 : e.equipmentName.length)} '
          '${e.category.padRight(12).substring(0, e.category.length > 11 ? 11 : e.category.length)} '
          '${e.quantity.toString().padRight(6)} '
          '${e.availableQuantity.toString().padRight(6)} '
          '${e.issuedQuantity.toString().padRight(6)} '
          '${e.damagedQuantity.toString().padRight(7)}'
        );
      }
      buffer.writeln('=' * 80);
    } else if (reportType == 'issue') {
      buffer.writeln('MRCAS SPORTS DEPARTMENT - EQUIPMENT ISSUE TRANSACTIONS REPORT');
      buffer.writeln('Generated on: $nowStr\n');
      buffer.writeln('=' * 80);
      buffer.writeln('${'ISSUE ID'.padRight(15)} ${'ATHLETE'.padRight(16)} ${'EQUIPMENT'.padRight(18)} ${'QTY'.padRight(4)} ${'DATE'.padRight(11)} ${'STATUS'}');
      buffer.writeln('=' * 80);
      for (final i in issues) {
        buffer.writeln(
          '${i.issueId.padRight(15)} '
          '${i.studentName.padRight(16).substring(0, i.studentName.length > 15 ? 15 : i.studentName.length)} '
          '${i.equipmentName.padRight(18).substring(0, i.equipmentName.length > 17 ? 17 : i.equipmentName.length)} '
          '${i.quantity.toString().padRight(4)} '
          '${DateFormat('dd-MM-yy').format(i.issueDate).padRight(11)} '
          '${i.status.toUpperCase()}'
        );
      }
      buffer.writeln('=' * 80);
    } else {
      buffer.writeln('MRCAS SPORTS DEPARTMENT - DAMAGE/LOSS REPORT');
      buffer.writeln('Generated on: $nowStr\n');
      buffer.writeln('=' * 80);
      buffer.writeln('${'ID'.padRight(15)} ${'EQUIPMENT NAME'.padRight(25)} ${'TOTAL STOCK'.padRight(12)} ${'DAMAGED'.padRight(10)} ${'LOST'}');
      buffer.writeln('=' * 80);
      for (final e in list.where((item) => item.damagedQuantity > 0 || item.lostQuantity > 0)) {
        buffer.writeln(
          '${e.equipmentId.padRight(15)} '
          '${e.equipmentName.padRight(25).substring(0, e.equipmentName.length > 24 ? 24 : e.equipmentName.length)} '
          '${e.quantity.toString().padRight(12)} '
          '${e.damagedQuantity.toString().padRight(10)} '
          '${e.lostQuantity}'
        );
      }
      buffer.writeln('=' * 80);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${reportType.toUpperCase()} Report Print Preview'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              buffer.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report generated and queued to printer successfully.'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Print Report'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String desc, IconData icon, Color color, String type) {
    return GlassCard(
      backgroundOpacity: isDark ? 0.15 : 0.6,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: () => _exportReport(context, type),
              icon: const Icon(Icons.print_rounded, size: 14),
              label: const Text('Export/Print', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sports Inventory & Transactions Report Generator',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Generate and print physical inventory sheets, outstanding issue ledgers, return receipts, or damaged items reports.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _buildReportCard(context, 'Active Stock Report', 'Overview of current available quantity across categories', Icons.inventory_2_rounded, Colors.green, 'inventory'),
            _buildReportCard(context, 'Issue Log Report', 'List of all active/past issued items with student details', Icons.outbox_rounded, Colors.orange, 'issue'),
            _buildReportCard(context, 'Damage & Loss Report', 'Sum of damaged and lost products for review', Icons.broken_image_rounded, Colors.redAccent, 'damage'),
          ],
        ),
      ],
    );
  }
}
