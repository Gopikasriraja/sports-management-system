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
import 'widgets/quick_actions.dart';
import 'widgets/student_management_view.dart';
import 'user_management_view.dart';
import 'widgets/equipment/equipment_management_view.dart';
import 'widgets/event_management_view.dart';
import 'widgets/gallery_management_view.dart';
import 'widgets/attendance_management_view.dart';
import 'widgets/report_management_view.dart';
import 'widgets/notification_management_view.dart';
import '../user/widgets/training_schedule_view.dart';
import '../teams/team_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
    } else if (auth.currentUser?.role != AppRoles.admin) {
      final role = auth.currentUser?.role;
      if (AppRoles.canAccessOperationsPortal(role)) {
        context.go('/staff');
      } else if (role == AppRoles.student) {
        context.go('/user');
      } else {
        context.go('/welcome');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Admin authorization required.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleTabSelect(String tab) {
    if (tab == 'Logout') return;
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
      final bool isAdmin =
          Provider.of<AuthProvider>(context).currentUser?.role ==
          AppRoles.admin;

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
                        'Welcome Back, Admin',
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

            // 1. Quick Actions List (Admin Only)
            if (isAdmin) ...[
              QuickActions(onNavigate: _handleTabSelect),
              const SizedBox(height: 28),
            ],

            // 2. Summary Cards Grid
            DashboardCards(onNavigate: _handleTabSelect),
            const SizedBox(height: 28),

            // Activity feed, events, and announcements
            if (isMobile) ...[
              const RecentActivities(),
              const SizedBox(height: 20),
              RecentEvents(onOpenCalendar: () {
                _handleTabSelect('Sports Calendar');
              }),
              const SizedBox(height: 20),
              const AnnouncementsWidget(),
            ] else ...[
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
            ],
          ],
        ),
      );
    }

    // Secondary Tab Screens Placeholder when clicked on sidebar menus
    Widget buildTabContent() {
      if (_activeTab == 'Student Management') {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: StudentManagementView(),
        );
      }
      if (_activeTab == 'Teams') {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: TeamManagementScreen(),
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
        return _ModuleStatusCard(
          title: 'Achievements',
          description:
              'There is no standalone achievements management screen yet. '
              'Achievement records are available within student profile details.',
          actionLabel: 'Open Student Management',
          onPressed: () => _handleTabSelect('Student Management'),
        );
      }
      if (_activeTab == 'Settings') {
        return const _ModuleStatusCard(
          title: 'System Settings',
          description:
              'A system settings screen has not been implemented. '
              'No settings have been changed from this page.',
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

class _ModuleStatusCard extends StatelessWidget {
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _ModuleStatusCard({
    required this.title,
    required this.description,
    this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 14),
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                if (actionLabel != null && onPressed != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
