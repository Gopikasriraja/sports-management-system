import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../chat/chatbot_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_roles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'widgets/user_sidebar.dart';
import 'widgets/user_top_bar.dart';
import 'widgets/dashboard_overview.dart';
import 'widgets/profile_view.dart';
import 'widgets/sports_calendar.dart';
import 'widgets/user_achievements.dart';
import 'widgets/equipment_availability.dart';
import 'widgets/attendance_history.dart';
import 'widgets/media_gallery.dart';
import 'widgets/department_contact.dart';
import 'widgets/training_schedule_view.dart';
import '../teams/team_management_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarCollapsed = false;
  String _activeTab = 'Dashboard';

  @override
  void initState() {
    super.initState();
    // Access control: redirect checking post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser == null) {
        context.go('/welcome');
      } else if (auth.currentUser?.role != AppRoles.student) {
        final role = auth.currentUser?.role;
        if (role == AppRoles.admin) {
          context.go('/admin');
        } else if (AppRoles.canAccessOperationsPortal(role)) {
          context.go('/staff');
        } else {
          context.go('/welcome');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Access Redirect: Admin, Manager, or Staff authorization active.',
            ),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    });
  }

  void _handleTabSelect(String tab) {
    if (tab == 'Logout') return;
    setState(() {
      _activeTab = tab;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
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

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth <= 640;
    final bool isTablet = screenWidth > 640 && screenWidth <= 1024;

    // Premium sports grading background gradients
    final Color bgGradientStart = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFEFF6FF);
    final Color bgGradientEnd = isDark
        ? const Color(0xFF1E1B4B)
        : const Color(0xFFDBEAFE);

    final sidebar = UserSidebar(
      collapsed: isTablet ? true : _sidebarCollapsed,
      activeItem: _activeTab,
      onItemSelect: _handleTabSelect,
    );

    final topBar = UserTopBar(
      isMobile: isMobile,
      onMenuPressed: () {
        if (isMobile) {
          _scaffoldKey.currentState?.openDrawer();
        } else {
          setState(() {
            _sidebarCollapsed = !_sidebarCollapsed;
          });
        }
      },
    );

    // Dynamic views builder
    Widget buildBodyContent() {
      switch (_activeTab) {
        case 'Dashboard':
          return DashboardOverview(onNavigate: _handleTabSelect);
        case 'My Profile':
          return const ProfileView();
        case 'Sports Calendar':
          return const SportsCalendar();
        case 'Training Schedule':
          return const TrainingScheduleView();
        case 'Sports Teams':
          return const TeamManagementScreen();
        case 'Achievements':
          return const UserAchievements();
        case 'Equipment Availability':
          return const EquipmentAvailability();
        case 'Attendance':
          return const AttendanceHistory();
        case 'Gallery':
          return const MediaGallery();
        case 'News & Announcements':
          return const _StudentAnnouncementsView();
        case 'Contact Sports Department':
          return const DepartmentContact();
        default:
          return DashboardOverview(onNavigate: _handleTabSelect);
      }
    }

    return PopScope<Object?>(
      canPop: _activeTab == 'Dashboard',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _activeTab != 'Dashboard') {
          setState(() => _activeTab = 'Dashboard');
        }
      },
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgGradientStart, bgGradientEnd],
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: isMobile ? Drawer(child: sidebar) : null,
        floatingActionButton: const ChatbotLauncher(),
        body: SafeArea(
          child: Row(
            children: [
              if (!isMobile) sidebar,
              Expanded(
                child: Column(
                  children: [
                    topBar,
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display dynamic section title
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _activeTab == 'Dashboard'
                                            ? 'Student Athlete Portal'
                                            : _activeTab,
                                        style: TextStyle(
                                          fontSize: isMobile ? 22 : 26,
                                          fontWeight: FontWeight.w900,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _activeTab == 'Dashboard'
                                            ? 'Overview of sports notifications, events, and performance.'
                                            : 'MRCAS Department of Physical Education.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: onBackgroundColor.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            buildBodyContent(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ModuleNotice extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _ModuleNotice({
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(message, style: theme.textTheme.bodyMedium),
                  if (onRetry != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentAnnouncementsView extends StatelessWidget {
    const _StudentAnnouncementsView();

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final provider = context.watch<NotificationProvider>();
      final announcements = [...provider.notifications]
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

      if (provider.isLoading && announcements.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (provider.errorMessage != null && announcements.isEmpty) {
        return _ModuleNotice(
          title: 'Announcements unavailable',
          message: 'Announcements could not be loaded. Please try again.',
          onRetry: provider.fetchNotifications,
        );
      }
      if (announcements.isEmpty) {
        return _ModuleNotice(
          title: 'No announcements',
          message: 'There are no department announcements at this time.',
        );
      }

      return Column(
        children: announcements.map((announcement) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.campaign_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                announcement.title,
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${DateFormat('d MMM yyyy').format(announcement.createdAt)}\n'
                  '${announcement.message}',
                ),
              ),
              isThreeLine: true,
            ),
          );
        }).toList(),
      );
    }
}
