import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../models/equipment_model.dart';
import '../../../../home/widgets/glass_card.dart';
import '../components/equipment_card.dart';

class InventoryTab extends StatelessWidget {
  final List<EquipmentModel> items;
  final Color primaryColor;
  final Color secondaryColor;
  final Color onBackgroundColor;
  final bool canManageInventory;
  final bool isDark;

  const InventoryTab({
    super.key,
    required this.items,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onBackgroundColor,
    required this.canManageInventory,
    required this.isDark,
  });

  // Removed _showDeleteConfirmDialog for Phase 1 Read Only

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: primaryColor.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text('No equipment items found matching filters.', style: TextStyle(fontWeight: FontWeight.bold)),
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
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final e = items[index];
          return EquipmentCard(
            item: e,
            primaryColor: primaryColor,
            onBackgroundColor: onBackgroundColor,
            canManageInventory: canManageInventory,
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
            DataColumn(label: Text('Image', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ID / Code', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Stock (T / A / I)', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Condition', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Purchase Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: items.map((e) {
            final lowStock = e.availableQuantity <= e.minStockLevel && e.availableQuantity > 0;
            final outOfStock = e.availableQuantity == 0;
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      image: e.equipmentImage.isNotEmpty
                          ? DecorationImage(image: NetworkImage(e.equipmentImage), fit: BoxFit.cover)
                          : null,
                    ),
                    child: e.equipmentImage.isEmpty ? Icon(Icons.sports_soccer_rounded, size: 16, color: primaryColor) : null,
                  ),
                ),
                DataCell(Text(e.equipmentId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                DataCell(Text(e.equipmentName, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(e.category)),
                DataCell(Text(e.brand.isEmpty ? 'N/A' : e.brand)),
                DataCell(Text('${e.quantity} / ${e.availableQuantity} / ${e.issuedQuantity}')),
                DataCell(Text(e.condition)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: outOfStock
                          ? Colors.red.withValues(alpha: 0.08)
                          : (lowStock ? Colors.orange.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      e.status,
                      style: TextStyle(
                        color: outOfStock ? Colors.red : (lowStock ? Colors.orange : Colors.green),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(DateFormat('dd-MMM-yyyy').format(e.purchaseDate))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // [PHASE 1 - READ ONLY]: All actions except View are disabled
                      IconButton(
                        icon: const Icon(Icons.visibility_rounded, size: 18, color: Colors.blueGrey),
                        tooltip: 'View Equipment Details (View Only)',
                        onPressed: () {
                          // View only mode for Phase 1
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View Details (Coming soon)')),
                          );
                        },
                      ),
                    ],
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
