import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../chat/chatbot_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_roles.dart';
import '../../providers/auth_provider.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'widgets/dashboard_cards.dart';
import 'widgets/recent_activities.dart';
import 'widgets/recent_events.dart';
import 'widgets/announcements.dart';
import 'widgets/student_management_view.dart';
import 'user_management_view.dart';
import 'widgets/equipment/equipment_management_view.dart';
import 'widgets/event_management_view.dart';
import 'widgets/gallery_management_view.dart';
import 'widgets/attendance_management_view.dart';
import 'widgets/report_management_view.dart';
import 'widgets/notification_management_view.dart';
import 'widgets/quick_actions.dart';
import '../teams/team_management_screen.dart';
import '../user/widgets/training_schedule_view.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarCollapsed = false;
  String _activeTab = 'Dashboard';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccess();
    });
  }

  void _checkAccess() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser == null) {
      context.go('/welcome');
    } else if (!AppRoles.canAccessOperationsPortal(
      auth.currentUser?.role,
    )) {
      final role = auth.currentUser?.role;
      if (role == AppRoles.admin) {
        context.go('/admin');
      } else if (role == AppRoles.student) {
        context.go('/user');
      } else {
        context.go('/welcome');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access Denied: Manager or Sports Staff authorization required.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleTabSelect(String tab) {
    if (tab == 'Logout') return;
    final role = context.read<AuthProvider>().currentUser?.role;
    if (!AppRoles.canOpenOperationsTab(role, tab)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to open this section.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _activeTab = tab;
    });
    // On mobile, close drawer after selection
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRole = Provider.of<AuthProvider>(context).currentUser?.role;
    final portalRole = currentRole == AppRoles.manager
        ? AppRoles.manager
        : AppRoles.sportsStaff;

    final Color primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final Color onBackgroundColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackgroundLight;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth <= 640;
    final bool isTablet = screenWidth > 640 && screenWidth <= 1024;

    // Background Gradient matching MRCAS premium branding theme
    final Color bgGradientStart = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFEFF6FF);
    final Color bgGradientEnd = isDark
        ? const Color(0xFF1E1B4B)
        : const Color(0xFFDBEAFE);

    // Sidebar setup
    final sidebar = AdminSidebar(
      collapsed: isTablet ? true : _sidebarCollapsed,
      activeItem: _activeTab,
      onItemSelect: _handleTabSelect,
    );

    // Top Bar setup
    final topBar = AdminTopBar(
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

    // Main Dashboard content section
    Widget buildDashboardContent() {
      final role = context.watch<AuthProvider>().currentUser?.role;
      final canViewAnalytics = AppRoles.canViewReports(role);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back, $portalRole',
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Portal overview for MRCAS Department of Physical Education.',
                        style: TextStyle(
                          fontSize: 13,
                          color: onBackgroundColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            QuickActions(onNavigate: _handleTabSelect),
            const SizedBox(height: 28),

            if (canViewAnalytics) ...[
              DashboardCards(onNavigate: _handleTabSelect),
              const SizedBox(height: 28),
            ],

            // Activity Logs and Events Lists Split
            if (canViewAnalytics && isMobile) ...[
              const RecentActivities(),
              const SizedBox(height: 20),
              RecentEvents(onOpenCalendar: () {
                _handleTabSelect('Sports Calendar');
              }),
              const SizedBox(height: 20),
              const AnnouncementsWidget(),
            ] else if (canViewAnalytics) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 3, child: RecentActivities()),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        RecentEvents(onOpenCalendar: () {
                          _handleTabSelect('Sports Calendar');
                        }),
                        const SizedBox(height: 20),
                        const AnnouncementsWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (isMobile) ...[
              RecentEvents(onOpenCalendar: () {
                _handleTabSelect('Sports Calendar');
              }),
              const SizedBox(height: 20),
              const AnnouncementsWidget(),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: RecentEvents(onOpenCalendar: () {
                      _handleTabSelect('Sports Calendar');
                    }),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(flex: 2, child: AnnouncementsWidget()),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Secondary Tab Screens Placeholder when clicked on sidebar menus
    Widget buildTabContent() {
      final role = context.read<AuthProvider>().currentUser?.role;
      if (!AppRoles.canOpenOperationsTab(role, _activeTab)) {
        return const Center(
          child: Text('You do not have permission to open this section.'),
        );
      }
      if (_activeTab == 'Teams' || _activeTab == 'Sports Teams') {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: TeamManagementScreen(),
        );
      }

      if (_activeTab == 'Student Management') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: StudentManagementView(),
        );
      }
      if (_activeTab == 'User Management') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: UserManagementView(),
        );
      }
      if (_activeTab == 'Sports Equipment') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: EquipmentManagementView(),
        );
      }
      if (_activeTab == 'Sports Calendar') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: EventManagementView(),
        );
      }
      if (_activeTab == 'Training Schedule') {
        return const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: TrainingScheduleView(readOnly: false),
        );
      }
      if (_activeTab == 'Gallery') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: GalleryManagementView(),
        );
      }
      if (_activeTab == 'Attendance' || _activeTab == 'Attendance Management') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: AttendanceManagementView(),
        );
      }
      if (_activeTab == 'Reports') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: ReportManagementView(),
        );
      }
      if (_activeTab == 'Notifications') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: NotificationManagementView(),
        );
      }
      if (_activeTab == 'Achievements') {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'There is no standalone achievements screen yet. '
              'Achievement records are available within student profile details.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 64,
                color: primaryColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                '$_activeTab Module',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This section is not implemented yet. Clean architecture placeholder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onBackgroundColor.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      );
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
              // Show sidebar on desktop and tablet
              if (!isMobile) sidebar,

              // Main content region
              Expanded(
                child: Column(
                  children: [
                    topBar,
                    Expanded(
                      child: _activeTab == 'Dashboard'
                          ? buildDashboardContent()
                          : buildTabContent(),
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
