import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/achievement_provider.dart';
import '../../../providers/equipment_provider.dart';
import '../../../models/student_model.dart';
import '../../home/widgets/glass_card.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      
      studentProvider.fetchStudents().then((_) {
        // Find matching student
        final user = auth.currentUser;
        if (user != null) {
          final matched = studentProvider.students.firstWhere(
            (s) => s.email.toLowerCase() == user.email.toLowerCase() ||
                   s.registerNumber.toLowerCase() == user.registerNumber.toLowerCase(),
            orElse: () => StudentModel(
              studentId: '',
              registerNumber: user.registerNumber,
              name: user.name,
              department: user.department,
              year: user.year,
              section: '',
              gender: '',
              phone: user.phone,
              email: user.email,
              bloodGroup: '',
              address: '',
              sports: const [],
              profileImage: user.profileImage,
              createdAt: user.createdAt,
            ),
          );

          if (matched.studentId.isNotEmpty) {
            if (mounted) {
              Provider.of<AttendanceProvider>(context, listen: false)
                  .fetchAttendanceForStudent(
                    matched.studentId,
                    actorUid: user.uid,
                    actorRole: user.role,
                  );
              Provider.of<AchievementProvider>(context, listen: false).fetchAchievementsForStudent(matched.studentId);
              Provider.of<EquipmentProvider>(context, listen: false).fetchIssuesByStudent(matched.studentId);
            }
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final authProvider = Provider.of<AuthProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final achievementProvider = Provider.of<AchievementProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);

    final user = authProvider.currentUser;
    if (user == null) {
      return const Center(child: Text('User session expired. Please login again.'));
    }

    // Find the matching student or fall back to user model values
    final student = studentProvider.students.firstWhere(
      (s) => s.email.toLowerCase() == user.email.toLowerCase() ||
             s.registerNumber.toLowerCase() == user.registerNumber.toLowerCase(),
      orElse: () => StudentModel(
        studentId: '',
        registerNumber: user.registerNumber,
        name: user.name,
        department: user.department,
        year: user.year,
        section: '',
        gender: '',
        phone: user.phone,
        email: user.email,
        bloodGroup: '',
        address: '',
        sports: const [],
        profileImage: user.profileImage,
        createdAt: user.createdAt,
      ),
    );

    // Compute attendance statistics
    final logs = attendanceProvider.attendanceLogs;
    final presentCount = logs
        .where((l) => l.status == 'Present' || l.status == 'Late')
        .length;
    final totalAttendance = logs
        .where((l) => l.status == 'Present' || l.status == 'Absent' || l.status == 'Late')
        .length;
    final double attendancePercentage = totalAttendance > 0
        ? (presentCount / totalAttendance) * 100
        : 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header
          GlassCard(
            backgroundOpacity: isDark ? 0.15 : 0.6,
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  backgroundImage: student.profileImage.isNotEmpty ? NetworkImage(student.profileImage) : null,
                  child: student.profileImage.isEmpty
                      ? Text(
                          student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  student.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: onBackgroundColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'Official MRCAS Athlete Profile',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Personal, Contact & Sports details
          GlassCard(
            backgroundOpacity: isDark ? 0.15 : 0.6,
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: AppColors.secondaryLight, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Personal & Academic Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProfileRow('Register Number', student.registerNumber, onBackgroundColor),
                _buildProfileRow('Department', student.department, onBackgroundColor),
                _buildProfileRow('Academic Year', student.year, onBackgroundColor),
                _buildProfileRow('Section Class', student.section, onBackgroundColor),
                _buildProfileRow('Primary Sports Registered', student.sports.join(', '), onBackgroundColor),
                _buildProfileRow('Blood Group', student.bloodGroup, onBackgroundColor),
                _buildProfileRow('Contact Phone', student.phone, onBackgroundColor),
                _buildProfileRow('Residence Address', student.address, onBackgroundColor),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Performance & Stats (Attendance, Achievements, Equipment)
          GlassCard(
            backgroundOpacity: isDark ? 0.15 : 0.6,
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: AppColors.secondaryLight, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Athlete Insights & Stats',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Attendance',
                      totalAttendance == 0
                          ? 'Unavailable'
                          : '${attendancePercentage.toStringAsFixed(0)}%',
                      Icons.calendar_month_rounded,
                      attendancePercentage >= 85 ? Colors.green : Colors.red,
                    ),
                    _buildStatCard(
                      'Medals',
                      '${achievementProvider.achievements.length}',
                      Icons.emoji_events_rounded,
                      Colors.amber,
                    ),
                    _buildStatCard(
                      'Equipments',
                      '${equipmentProvider.issueLogs.length}',
                      Icons.inventory_2_rounded,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Detailed lists under tabs
          if (student.studentId.isNotEmpty) ...[
            Text(
              'Detailed logs & reports',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onBackgroundColor.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 12),
            _buildCollapseSection(
              title: 'My Achievements List',
              icon: Icons.emoji_events_rounded,
              child: achievementProvider.achievements.isEmpty
                  ? const Text('No achievements logged in the system yet.', style: TextStyle(fontStyle: FontStyle.italic))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: achievementProvider.achievements.length,
                      itemBuilder: (context, index) {
                        final ach = achievementProvider.achievements[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.military_tech_rounded, color: Colors.amber),
                          title: Text('${ach.medal} Medal in ${ach.event}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Level: ${ach.level} | Sport: ${ach.sport} (${ach.year})'),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            _buildCollapseSection(
              title: 'Equipment Issue Logs',
              icon: Icons.inventory_2_rounded,
              child: equipmentProvider.issueLogs.isEmpty
                  ? const Text('No equipment items currently issued to you.', style: TextStyle(fontStyle: FontStyle.italic))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: equipmentProvider.issueLogs.length,
                      itemBuilder: (context, index) {
                        final item = equipmentProvider.issueLogs[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.outbound_rounded, color: Colors.blueAccent),
                          title: Text('Issue ID: #${item.issueId.substring(0, 5).toUpperCase()}'),
                          subtitle: Text('Issued on: ${DateFormat('dd-MM-yyyy').format(item.issueDate)} | Status: ${item.status.toUpperCase()}'),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String val, Color textCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              val.isNotEmpty ? val : 'Not Specified',
              style: TextStyle(fontWeight: FontWeight.w600, color: textCol, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCollapseSection({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.secondaryLight),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: child,
          )
        ],
      ),
    );
  }
}
