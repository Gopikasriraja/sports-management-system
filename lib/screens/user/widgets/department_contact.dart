import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/widgets/glass_card.dart';

class DepartmentContact extends StatefulWidget {
  const DepartmentContact({super.key});

  @override
  State<DepartmentContact> createState() => _DepartmentContactState();
}

class _DepartmentContactState extends State<DepartmentContact> {
  final _formKey = GlobalKey<FormState>();
  final _queryController = TextEditingController();
  String _queryType = 'Attendance Query';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final double width = MediaQuery.of(context).size.width;

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
                  'Contact Sports Department',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect with MRCAS Department of Physical Education & Sports.',
                  style: TextStyle(fontSize: 11.5, color: onBackgroundColor.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (width < 960) ...[
          _buildContactInfo(context, primaryColor, secondaryColor, onBackgroundColor),
          const SizedBox(height: 20),
          _buildQueryForm(context, primaryColor, secondaryColor, onBackgroundColor),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildContactInfo(context, primaryColor, secondaryColor, onBackgroundColor)),
              const SizedBox(width: 20),
              Expanded(child: _buildQueryForm(context, primaryColor, secondaryColor, onBackgroundColor)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context, Color primary, Color secondary, Color onBg) {
    final infoList = [
      {'label': 'Director of Physical Education', 'val': 'Dr. K. Ramasamy M.P.Ed., Ph.D.', 'icon': Icons.person_rounded},
      {'label': 'Department Office Location', 'val': 'MRCAS Main Campus, Ground Floor, Block C', 'icon': Icons.location_on_rounded},
      {'label': 'Official Phone Contact', 'val': '+91 452 234 5678 (Ext. 204)', 'icon': Icons.phone_rounded},
      {'label': 'Official Email Address', 'val': 'sports@mrcas.edu.in', 'icon': Icons.email_rounded},
      {'label': 'Working Office Hours', 'val': '08:30 AM - 04:30 PM (Monday - Saturday)', 'icon': Icons.schedule_rounded},
    ];

    return GlassCard(
      backgroundOpacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Directory',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: infoList.length,
            separatorBuilder: (context, index) => Divider(color: onBg.withValues(alpha: 0.08), height: 20),
            itemBuilder: (context, index) {
              final item = infoList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: secondary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onBg.withValues(alpha: 0.45)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['val'] as String,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onBg),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueryForm(BuildContext context, Color primary, Color secondary, Color onBg) {
    final types = ['Attendance Query', 'Equipment Request', 'Event Registration', 'General Support'];

    return GlassCard(
      backgroundOpacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit a Support Query',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary),
            ),
            const SizedBox(height: 16),

            // Dropdown selection
            DropdownButtonFormField<String>(
              initialValue: _queryType,
              decoration: InputDecoration(
                labelText: 'Query Category',
                labelStyle: TextStyle(color: onBg.withValues(alpha: 0.6), fontSize: 13),
                filled: true,
                fillColor: onBg.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: onBg.withValues(alpha: 0.12)),
                ),
              ),
              items: types
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: TextStyle(color: onBg, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _queryType = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Query Input text
            TextFormField(
              controller: _queryController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Detailed Message Description',
                labelStyle: TextStyle(color: onBg.withValues(alpha: 0.6), fontSize: 13),
                hintText: 'Enter query context here...',
                hintStyle: TextStyle(color: onBg.withValues(alpha: 0.4), fontSize: 13),
                filled: true,
                fillColor: onBg.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: onBg.withValues(alpha: 0.12)),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please explain your message.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Support ticket created: "$_queryType" received successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _queryController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Send Support Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
