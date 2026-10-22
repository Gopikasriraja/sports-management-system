import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/widgets/glass_card.dart';

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 960;

    return Column(
      children: [
        if (isMobile) ...[
          _buildAttendanceOverview(context),
          const SizedBox(height: 20),
          _buildSportsParticipation(context),
          const SizedBox(height: 20),
          _buildEquipmentStatus(context),
          const SizedBox(height: 20),
          _buildAchievementsBySport(context),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAttendanceOverview(context)),
              const SizedBox(width: 20),
              Expanded(child: _buildSportsParticipation(context)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildEquipmentStatus(context)),
              const SizedBox(width: 20),
              Expanded(child: _buildAchievementsBySport(context)),
            ],
          ),
        ],
      ],
    );
  }

  // 1. Attendance Overview (Custom painted line chart)
  Widget _buildAttendanceOverview(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    return GlassCard(
      backgroundOpacity: isDark ? 0.15 : 0.6,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    'Monthly student participation rates',
                    style: TextStyle(
                      fontSize: 11,
                      color: onBackgroundColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendIndicator('Required', primaryColor),
                  const SizedBox(width: 12),
                  _buildLegendIndicator('Actual', secondaryColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: LineChartPainter(
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                gridColor: onBackgroundColor.withValues(alpha: 0.06),
                textColor: onBackgroundColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Sports Participation (Progress rings)
  Widget _buildSportsParticipation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final sportsData = [
      ProgressItem(name: 'Football', value: 0.85, color: primaryColor),
      ProgressItem(name: 'Cricket', value: 0.72, color: secondaryColor),
      ProgressItem(name: 'Volleyball', value: 0.60, color: Colors.green),
      ProgressItem(name: 'Basketball', value: 0.48, color: Colors.amber),
    ];

    return GlassCard(
      backgroundOpacity: isDark ? 0.15 : 0.6,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sports Participation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          Text(
            'Active student enrollment split',
            style: TextStyle(
              fontSize: 11,
              color: onBackgroundColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Concentric custom painted circular rings
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: ConcentricRingsPainter(
                    items: sportsData,
                    trackColor: onBackgroundColor.withValues(alpha: 0.05),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legends
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: sportsData
                      .map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: onBackgroundColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(item.value * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Equipment Status (Horizontal progress bars)
  Widget _buildEquipmentStatus(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    return GlassCard(
      backgroundOpacity: isDark ? 0.15 : 0.6,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equipment Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          Text(
            'Inventory utilization dashboard',
            style: TextStyle(
              fontSize: 11,
              color: onBackgroundColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusRow(context, 'Available (In Store)', 980, 1200, Colors.teal, onBackgroundColor),
          const SizedBox(height: 16),
          _buildStatusRow(context, 'Issued (In Use)', 220, 1200, secondaryColor, onBackgroundColor),
          const SizedBox(height: 16),
          _buildStatusRow(context, 'Damaged / Maintenance', 40, 1200, Colors.redAccent, onBackgroundColor),
        ],
      ),
    );
  }

  // 4. Achievements by Sport (Bar chart)
  Widget _buildAchievementsBySport(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    return GlassCard(
      backgroundOpacity: isDark ? 0.15 : 0.6,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements by Sport',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          Text(
            'Inter-college tournament medals count',
            style: TextStyle(
              fontSize: 11,
              color: onBackgroundColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: BarChartPainter(
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                gridColor: onBackgroundColor.withValues(alpha: 0.06),
                textColor: onBackgroundColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusRow(BuildContext context, String title, int current, int total, Color color, Color onBg) {
    final double percent = current / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: onBg.withValues(alpha: 0.85)),
            ),
            Text(
              '$current / $total units',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onBg),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: onBg.withValues(alpha: 0.05),
            color: color,
          ),
        ),
      ],
    );
  }
}

class ProgressItem {
  final String name;
  final double value;
  final Color color;

  ProgressItem({required this.name, required this.value, required this.color});
}

// 1. LineChart Custom Painter
class LineChartPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color textColor;

  LineChartPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    const int gridRows = 4;
    final double stepY = size.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      final double y = i * stepY;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Graph Data Points
    final requiredPoints = [0.85, 0.90, 0.88, 0.92, 0.85, 0.94];
    final actualPoints = [0.70, 0.82, 0.78, 0.85, 0.72, 0.88];

    final double stepX = size.width / (requiredPoints.length - 1);

    // Helper to draw a line path
    void drawGraphLine(List<double> points, Color color) {
      final path = Path();
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < points.length; i++) {
        final double x = i * stepX;
        final double y = size.height * (1 - points[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);

      // Draw points
      final dotPaint = Paint()..color = color;
      final bgDotPaint = Paint()..color = Colors.white;
      for (int i = 0; i < points.length; i++) {
        final double x = i * stepX;
        final double y = size.height * (1 - points[i]);
        canvas.drawCircle(Offset(x, y), 5.0, dotPaint);
        canvas.drawCircle(Offset(x, y), 2.5, bgDotPaint);
      }
    }

    drawGraphLine(requiredPoints, primaryColor);
    drawGraphLine(actualPoints, secondaryColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Concentric Rings Painter
class ConcentricRingsPainter extends CustomPainter {
  final List<ProgressItem> items;
  final Color trackColor;

  ConcentricRingsPainter({required this.items, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    const double strokeWidth = 10.0;
    const double spacing = 14.0;

    for (int i = 0; i < items.length; i++) {
      final double radius = center - (i * spacing) - (strokeWidth / 2);

      final trackPaint = Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(center, center), radius, trackPaint);

      final progressPaint = Paint()
        ..color = items[i].color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(center, center), radius: radius),
        -1.5708, // Start at top (-90 degrees)
        items[i].value * 6.28319, // sweep angle
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. BarChart Custom Painter (Horizontal Medals split)
class BarChartPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color textColor;

  BarChartPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barData = [
      {'name': 'Football', 'val': 0.85},
      {'name': 'Cricket', 'val': 0.65},
      {'name': 'Athletics', 'val': 0.95},
    ];

    final double barHeight = (size.height / barData.length) - 14.0;
    final double stepY = size.height / barData.length;

    for (int i = 0; i < barData.length; i++) {
      final item = barData[i];
      final double y = i * stepY + 4.0;
      final double progressWidth = size.width * (item['val'] as double);

      // Draw background bar track
      final trackPaint = Paint()
        ..color = gridColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, size.width, barHeight),
          const Radius.circular(6),
        ),
        trackPaint,
      );

      // Draw progressive bar fill
      final fillPaint = Paint()
        ..color = i == 1 ? secondaryColor : (i == 2 ? Colors.green : primaryColor)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, progressWidth, barHeight),
          const Radius.circular(6),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
