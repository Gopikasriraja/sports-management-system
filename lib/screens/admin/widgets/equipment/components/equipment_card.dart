import 'package:flutter/material.dart';
import '../../../../../models/equipment_model.dart';

class EquipmentCard extends StatelessWidget {
  final EquipmentModel item;
  final Color primaryColor;
  final Color onBackgroundColor;
  final bool canManageInventory;
  final bool isDark;

  const EquipmentCard({
    super.key,
    required this.item,
    required this.primaryColor,
    required this.onBackgroundColor,
    required this.canManageInventory,
    required this.isDark,
  });

  // Removed _showDeleteConfirmDialog for Phase 1 Read Only

  Widget _buildMiniInfo(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = item.availableQuantity <= item.minStockLevel && item.availableQuantity > 0;
    final outOfStock = item.availableQuantity == 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    image: item.equipmentImage.isNotEmpty
                        ? DecorationImage(image: NetworkImage(item.equipmentImage), fit: BoxFit.cover)
                        : null,
                  ),
                  child: item.equipmentImage.isEmpty
                      ? Icon(Icons.sports_soccer_rounded, color: primaryColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.equipmentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${item.brand} | ${item.category}', style: TextStyle(fontSize: 11, color: onBackgroundColor.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: outOfStock
                        ? Colors.red.withValues(alpha: 0.08)
                        : (lowStock ? Colors.orange.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: outOfStock ? Colors.red : (lowStock ? Colors.orange : Colors.green),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniInfo('Available Qty', '${item.availableQuantity} units'),
                _buildMiniInfo('Issued Qty', '${item.issuedQuantity} units'),
                _buildMiniInfo('Damaged Qty', '${item.damagedQuantity} units'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // [PHASE 1 - READ ONLY]: All actions except View are disabled
                IconButton(
                  icon: const Icon(Icons.visibility_rounded, size: 20, color: Colors.blueGrey),
                  tooltip: 'View Equipment Details (View Only)',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View Details (Coming soon)')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
