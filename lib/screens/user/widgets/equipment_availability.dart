import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/equipment_provider.dart';
import '../../home/widgets/glass_card.dart';

class EquipmentAvailability extends StatefulWidget {
  const EquipmentAvailability({super.key});

  @override
  State<EquipmentAvailability> createState() => _EquipmentAvailabilityState();
}

class _EquipmentAvailabilityState extends State<EquipmentAvailability> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EquipmentProvider>(context, listen: false).fetchEquipment();
    });
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer_rounded;
      case 'cricket':
        return Icons.sports_cricket_rounded;
      case 'basketball':
        return Icons.sports_basketball_rounded;
      case 'volleyball':
        return Icons.sports_volleyball_rounded;
      case 'badminton':
        return Icons.sports_tennis_rounded;
      case 'table tennis':
        return Icons.sports_tennis_rounded;
      case 'athletics':
        return Icons.directions_run_rounded;
      case 'chess':
        return Icons.extension_rounded;
      case 'kabaddi':
        return Icons.groups_rounded;
      case 'hockey':
        return Icons.sports_soccer_rounded; // Fallback
      case 'yoga':
        return Icons.self_improvement_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'football':
        return Colors.blue;
      case 'cricket':
        return Colors.orange;
      case 'basketball':
        return Colors.deepOrange;
      case 'volleyball':
        return Colors.purple;
      case 'badminton':
        return Colors.teal;
      case 'table tennis':
        return Colors.indigo;
      case 'athletics':
        return Colors.redAccent;
      case 'chess':
        return Colors.brown;
      case 'kabaddi':
        return Colors.pink;
      case 'yoga':
        return Colors.lightGreen;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final Color onBackgroundColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackgroundLight;

    final equipProvider = Provider.of<EquipmentProvider>(context);
    final items = equipProvider.equipmentList;

    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 1 : (width < 960 ? 2 : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equipment Availability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View active stock status. Inventory is managed by department coaches.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: onBackgroundColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        equipProvider.isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : equipProvider.errorMessage != null
            ? Center(
                child: GlassCard(
                  backgroundOpacity: isDark ? 0.15 : 0.6,
                  borderRadius: 18,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 44,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Equipment availability could not be loaded.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: equipProvider.fetchEquipment,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : items.isEmpty
            ? Center(
                child: GlassCard(
                  backgroundOpacity: isDark ? 0.15 : 0.6,
                  borderRadius: 18,
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Registered Equipment Available',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sports catalog is currently empty. Ask coach or staff to register inventory items.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: width < 600
                      ? 2.1
                      : (width < 960 ? 1.5 : 1.7),
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final double percent = item.quantity > 0
                      ? (item.availableQuantity / item.quantity)
                            .clamp(0.0, 1.0)
                            .toDouble()
                      : 0.0;
                  final IconData icon = _getIconForCategory(item.category);
                  final Color color = _getColorForCategory(item.category);

                  return GlassCard(
                    backgroundOpacity: isDark ? 0.15 : 0.6,
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: item.equipmentImage.isEmpty
                                  ? Icon(icon, color: color, size: 24)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        item.equipmentImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Icon(
                                          icon,
                                          color: color,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.equipmentName,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: onBackgroundColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${item.brand} | ${item.category}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: onBackgroundColor.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: onBackgroundColor.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            Text(
                              '${item.availableQuantity} / ${item.quantity} units',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 6,
                            backgroundColor: onBackgroundColor.withValues(
                              alpha: 0.05,
                            ),
                            color: percent < 0.3
                                ? Colors.redAccent
                                : (percent < 0.7 ? Colors.amber : Colors.green),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
