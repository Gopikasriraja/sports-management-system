import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/glass_card.dart';
import 'widgets/hover_card.dart';
import 'widgets/counter_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // GlobalKeys for scrolling navigation
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _sportsKey = GlobalKey();
  final GlobalKey _eventsKey = GlobalKey();
  final GlobalKey _galleryKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;
    final Color cardBgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      drawer: _buildDrawer(context, primaryColor, secondaryColor),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. MODERN APP BAR
          SliverAppBar(
            pinned: true,
            expandedHeight: 80.0,
            collapsedHeight: 70.0,
            backgroundColor: isDark 
                ? const Color(0xFF0F172A).withValues(alpha: 0.95) 
                : Colors.white.withValues(alpha: 0.95),
            elevation: 2,
            title: Row(
              children: [
                // Use the official college logo without cropping or distortion.
                Image.asset(
                  'assets/images/mrcas_logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: secondaryColor, width: 1.5),
                      ),
                      child: Icon(Icons.school_rounded, color: primaryColor, size: 24),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MRCAS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Dept. of Physical Education & Sports',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: onBackgroundColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Desktop Navigation Items
              if (MediaQuery.of(context).size.width >= 960) ...[
                _buildNavLink('Home', () => _scrollToSection(_heroKey), primaryColor),
                _buildNavLink('About', () => _scrollToSection(_aboutKey), primaryColor),
                _buildNavLink('Sports', () => _scrollToSection(_sportsKey), primaryColor),
                _buildNavLink('Events', () => _scrollToSection(_eventsKey), primaryColor),
                _buildNavLink('Gallery', () => _scrollToSection(_galleryKey), primaryColor),
                _buildNavLink('Contact', () => _scrollToSection(_contactKey), primaryColor),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton(
                    onPressed: () => context.go('/auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                ),
              ] else ...[
                // Mobile Drawer Trigger
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu_rounded, color: primaryColor),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ],
            ],
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // 2. HERO BANNER
              _buildHeroSection(context, primaryColor, secondaryColor, onBackgroundColor, isDark),
              
              // 3. ABOUT SPORTS DEPARTMENT
              _buildAboutSection(context, primaryColor, secondaryColor, onBackgroundColor, cardBgColor, isDark),

              // 4. SPORTS HIGHLIGHTS
              _buildSportsSection(context, primaryColor, secondaryColor, onBackgroundColor, cardBgColor, isDark),

              // 5. STATISTICS (Counter Animations)
              _buildStatsSection(context, primaryColor, secondaryColor, onBackgroundColor, isDark),

              // 6. UPCOMING EVENTS (Horizontal Scroll)
              _buildEventsSection(context, primaryColor, secondaryColor, onBackgroundColor, cardBgColor, isDark),

              // 7. ACHIEVEMENT HIGHLIGHTS
              _buildAchievementsSection(context, primaryColor, secondaryColor, onBackgroundColor, cardBgColor, isDark),

              // 8. GALLERY PREVIEW
              _buildGallerySection(context, primaryColor, secondaryColor, onBackgroundColor, isDark),

              // 9. LATEST NEWS
              _buildNewsSection(context, primaryColor, secondaryColor, onBackgroundColor, cardBgColor, isDark),

              // 10. CONTACT SECTION (Google Map Placeholder)
              _buildContactSection(context, primaryColor, secondaryColor, onBackgroundColor, cardBgColor, isDark),

              // 11. FOOTER
              _buildFooter(context, primaryColor, secondaryColor, onBackgroundColor, isDark),
            ]),
          ),
        ],
      ),
    );
  }

  // 1. Helper navigation links in Header
  Widget _buildNavLink(String title, VoidCallback onTap, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Mobile Drawer Navigation Helper
  Widget _buildDrawer(BuildContext context, Color primaryColor, Color secondaryColor) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer_rounded, size: 48, color: secondaryColor),
                    const SizedBox(height: 12),
                    Text(
                      'MRCAS Sports',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_rounded, color: primaryColor),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_heroKey);
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline_rounded, color: primaryColor),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_aboutKey);
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_handball_rounded, color: primaryColor),
              title: const Text('Sports'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_sportsKey);
              },
            ),
            ListTile(
              leading: Icon(Icons.event_note_rounded, color: primaryColor),
              title: const Text('Events'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_eventsKey);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: primaryColor),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_galleryKey);
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_mail_rounded, color: primaryColor),
              title: const Text('Contact'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_contactKey);
              },
            ),
            const Divider(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. HERO BANNER SECTION
  Widget _buildHeroSection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    return Container(
      key: _heroKey,
      height: 520,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
        ),
      ),
      child: Stack(
        children: [
          // Subtle Diagonal Athletics Background Design Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                painter: HeroGridPainter(lineColor: secondaryColor),
              ),
            ),
          ),
          
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // High-fidelity entry animation placeholder
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOut,
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, (1 - opacity) * 30),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'Welcome to',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 32,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sports Management System',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 32 : 56,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -1,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Department of Physical Education & Sports\nMRCAS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 20,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: onBackgroundColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Primary Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/auth'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          minimumSize: const Size(120, 50),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => _scrollToSection(_sportsKey),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secondaryColor,
                          side: BorderSide(color: secondaryColor, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Explore Sports', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. ABOUT SPORTS DEPARTMENT
  Widget _buildAboutSection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, Color cardBgColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 680;

    return Container(
      key: _aboutKey,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        children: [
          _buildSectionHeader('About Sports Department', 'Fostering athletic excellence, sportsmanship, and holistic training.', primaryColor, secondaryColor),
          const SizedBox(height: 48),

          // Layout Cards
          if (isMobile) ...[
            _buildAboutCard('About Us', 'MRCAS Department of Physical Education and Sports is committed to fostering discipline, physical fitness, and professional athletic training across diverse sports. We cultivate a dynamic ecosystem for outstanding state and national athletes.', Icons.info_rounded, primaryColor, cardBgColor, isDark),
            const SizedBox(height: 16),
            _buildAboutCard('Our Vision', 'To build a state-of-the-art sports training institute that develops globally competent athletes, promotes sports science, and leads in academic-athletic integrations.', Icons.visibility_rounded, primaryColor, cardBgColor, isDark),
            const SizedBox(height: 16),
            _buildAboutCard('Our Mission', 'Providing high-caliber coaching, modern infrastructure, and comprehensive physical training while ensuring athletes achieve academic excellence and strong character.', Icons.flag_rounded, primaryColor, cardBgColor, isDark),
            const SizedBox(height: 16),
            _buildAboutCard('Objectives', 'Organize collegiate sports tournaments, build premium high-performance facilities, provide nutritional counseling, and run specialized coaching camps year-round.', Icons.track_changes_rounded, primaryColor, cardBgColor, isDark),
          ] else ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: width >= 1024 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildAboutCard('About Us', 'MRCAS Department of Physical Education and Sports is committed to fostering discipline, physical fitness, and professional athletic training across diverse sports. We cultivate a dynamic ecosystem for outstanding state and national athletes.', Icons.info_rounded, primaryColor, cardBgColor, isDark),
                _buildAboutCard('Our Vision', 'To build a state-of-the-art sports training institute that develops globally competent athletes, promotes sports science, and leads in academic-athletic integrations.', Icons.visibility_rounded, primaryColor, cardBgColor, isDark),
                _buildAboutCard('Our Mission', 'Providing high-caliber coaching, modern infrastructure, and comprehensive physical training while ensuring athletes achieve academic excellence and strong character.', Icons.flag_rounded, primaryColor, cardBgColor, isDark),
                _buildAboutCard('Objectives', 'Organize collegiate sports tournaments, build premium high-performance facilities, provide nutritional counseling, and run specialized coaching camps year-round.', Icons.track_changes_rounded, primaryColor, cardBgColor, isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutCard(String title, String text, IconData icon, Color primaryColor, Color cardBgColor, bool isDark) {
    return HoverCard(
      child: GlassCard(
        backgroundOpacity: isDark ? 0.08 : 0.04,
        borderOpacity: 0.15,
        borderRadius: 16,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. SPORTS HIGHLIGHTS SECTION
  Widget _buildSportsSection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, Color cardBgColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 1 : (width < 960 ? 2 : 4);

    final sportsList = [
      {'name': 'Cricket', 'desc': 'MRCAS powerhouse team with standard turf practice wickets and expert conditioning.', 'icon': Icons.sports_cricket_rounded},
      {'name': 'Football', 'desc': 'Full-size football turf hosting regular inter-collegiate championships and training clinics.', 'icon': Icons.sports_soccer_rounded},
      {'name': 'Volleyball', 'desc': 'Flooded court arenas designed for advanced setups, spiking practices, and defensive drills.', 'icon': Icons.sports_volleyball_rounded},
      {'name': 'Basketball', 'desc': 'Synthetic outdoor courts with professional fiberglass boards and automated scoreboard panels.', 'icon': Icons.sports_basketball_rounded},
      {'name': 'Athletics', 'desc': 'Running tracks, hurdles, long jump pits, and specialized coaches for track-and-field events.', 'icon': Icons.directions_run_rounded},
      {'name': 'Chess', 'desc': 'Dedicated indoor sports room with advanced boards and strategy sessions led by FIDE masters.', 'icon': Icons.emoji_events_outlined},
      {'name': 'Badminton', 'desc': 'Excellent indoor wooden court setups offering modern high-ceiling play and lightning-fast play.', 'icon': Icons.sports_tennis_rounded},
    ];

    return Container(
      key: _sportsKey,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      color: isDark ? const Color(0xFF0F172A).withAlpha(128) : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          _buildSectionHeader('Sports Highlights', 'Choose your specialization. Train with state-of-the-art facilities.', primaryColor, secondaryColor),
          const SizedBox(height: 48),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sportsList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final sport = sportsList[index];
              return HoverCard(
                child: GlassCard(
                  backgroundOpacity: isDark ? 0.08 : 0.4,
                  borderOpacity: 0.2,
                  borderRadius: 16,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reusable Image Placeholder Container
                      Container(
                        height: 90,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            sport['icon'] as IconData,
                            size: 40,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        sport['name'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          sport['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: onBackgroundColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. STATISTICS SECTION (Animated Counters)
  Widget _buildStatsSection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    final stats = [
      {'title': 'Active Students', 'value': 1200, 'suffix': '+'},
      {'title': 'Sports Disciplines', 'value': 12, 'suffix': ''},
      {'title': 'Certified Coaches', 'value': 8, 'suffix': ''},
      {'title': 'Championships Won', 'value': 45, 'suffix': '+'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: primaryColor,
        image: DecorationImage(
          image: const AssetImage('assets/images/sports_bg.png'), // placeholder check
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(primaryColor.withValues(alpha: 0.92), BlendMode.srcOver),
          onError: (exception, stackTrace) {},
        ),
      ),
      child: Center(
        child: Wrap(
          spacing: 32,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: stats.map((stat) {
            return SizedBox(
              width: isMobile ? width * 0.4 : 180,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CounterWidget(
                    targetValue: stat['value'] as int,
                    suffix: stat['suffix'] as String,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 6. UPCOMING EVENTS (Horizontal Scrolling)
  Widget _buildEventsSection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, Color cardBgColor, bool isDark) {
    final events = [
      {'name': 'Inter-Collegiate Athletic Meet', 'date': 'July 24, 2026', 'venue': 'MRCAS Main Track', 'icon': Icons.directions_run_rounded},
      {'name': 'State T20 Cricket Invitational', 'date': 'August 12, 2026', 'venue': 'MRCAS Sports Arena', 'icon': Icons.sports_cricket_rounded},
      {'name': 'Intra-Department Chess Arena', 'date': 'August 30, 2026', 'venue': 'Indoor Stadium Block B', 'icon': Icons.hotel_class_outlined},
      {'name': 'District Football League Playoff', 'date': 'September 15, 2026', 'venue': 'Soccer Arena East Ground', 'icon': Icons.sports_soccer_rounded},
    ];

    return Container(
      key: _eventsKey,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        children: [
          _buildSectionHeader('Upcoming Events', 'Track match dates, tournaments, and events across MRCAS campuses.', primaryColor, secondaryColor),
          const SizedBox(height: 36),

          // Horizontal Scrolling Wrapper
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16.0, bottom: 8.0, top: 8.0),
                  child: HoverCard(
                    child: GlassCard(
                      backgroundOpacity: isDark ? 0.08 : 0.05,
                      borderOpacity: 0.15,
                      borderRadius: 12,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(event['icon'] as IconData, color: secondaryColor, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event['date'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Text(
                              event['name'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: onBackgroundColor.withValues(alpha: 0.5), size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event['venue'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: onBackgroundColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 7. ACHIEVEMENT HIGHLIGHTS SECTION
  Widget _buildAchievementsSection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, Color cardBgColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 1 : (width < 960 ? 2 : 5);

    final achievements = [
      {'title': 'Gold Tally', 'subtitle': '24 Medals', 'desc': 'First positions in Zonal Athletics, Table Tennis and Chess.', 'icon': Icons.emoji_events_rounded, 'color': Colors.amber},
      {'title': 'Silver Tally', 'subtitle': '18 Medals', 'desc': 'Substantial podium performances in State Powerlifting and Judo.', 'icon': Icons.emoji_events_outlined, 'color': Colors.grey.shade400},
      {'title': 'Bronze Tally', 'subtitle': '12 Medals', 'desc': 'Solid third places in Badminton Singles and Football finals.', 'icon': Icons.emoji_events_outlined, 'color': Colors.amber.shade900},
      {'title': 'State Level', 'subtitle': 'Champions', 'desc': 'Official State Kabaddi champions trophy winner of the year.', 'icon': Icons.military_tech_rounded, 'color': Colors.indigo},
      {'title': 'National Level', 'subtitle': '3 Representatives', 'desc': 'Athletes nominated for National Track events representation.', 'icon': Icons.public_rounded, 'color': Colors.red},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      color: isDark ? const Color(0xFF0F172A).withAlpha(128) : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          _buildSectionHeader('Achievement Highlights', 'Celebrating MRCAS honors, trophies, and podium counts this academic year.', primaryColor, secondaryColor),
          const SizedBox(height: 48),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final ach = achievements[index];
              return HoverCard(
                child: GlassCard(
                  backgroundOpacity: isDark ? 0.08 : 0.4,
                  borderOpacity: 0.2,
                  borderRadius: 16,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ach['icon'] as IconData, color: ach['color'] as Color, size: 44),
                      const SizedBox(height: 12),
                      Text(
                        ach['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ach['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ach['desc'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: onBackgroundColor.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 8. GALLERY PREVIEW SECTION
  Widget _buildGallerySection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 2 : (width < 960 ? 3 : 4);

    return Container(
      key: _galleryKey,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        children: [
          _buildSectionHeader('Gallery Preview', 'Glimpses of MRCAS athletic coaching, tournament tracks, and practice courts.', primaryColor, secondaryColor),
          const SizedBox(height: 48),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              return HoverCard(
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 12,
                  borderOpacity: 0.15,
                  child: Stack(
                    children: [
                      // Placeholder visual pattern
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withValues(alpha: 0.1),
                                secondaryColor.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 40,
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                      // Overlay Label
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Text(
                            'Sport Activity ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gallery route not implemented yet.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('View More Gallery'),
          ),
        ],
      ),
    );
  }

  // 9. LATEST NEWS SECTION
  Widget _buildNewsSection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, Color cardBgColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 1 : (width < 960 ? 2 : 3);

    final newsList = [
      {'title': 'MRCAS Clinches Championship Trophy', 'date': 'July 01, 2026', 'desc': 'Our volleyball team emerged champions in the district invitational cup, defeating regional rivals in straight sets.'},
      {'title': 'State-of-the-Art Fitness Center Opened', 'date': 'June 25, 2026', 'desc': 'College launches fully updated gyms equipped with cardiovascular setups and advanced weights training coaches.'},
      {'title': 'Intramural Tournament Schedules Out', 'date': 'June 18, 2026', 'desc': 'Sports department releases schedules for the annual department sports tournaments. Register by this weekend.'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      color: isDark ? const Color(0xFF0F172A).withAlpha(128) : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          _buildSectionHeader('Latest News', 'Stay updated with sport schedules, league updates, and coach reports.', primaryColor, secondaryColor),
          const SizedBox(height: 48),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: newsList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final news = newsList[index];
              return HoverCard(
                child: GlassCard(
                  backgroundOpacity: isDark ? 0.08 : 0.4,
                  borderOpacity: 0.2,
                  borderRadius: 16,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        news['date'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          news['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: onBackgroundColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Read More', style: TextStyle(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: secondaryColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 10. CONTACT SECTION (Google Map Placeholder)
  Widget _buildContactSection(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, Color cardBgColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 840;

    return Container(
      key: _contactKey,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        children: [
          _buildSectionHeader('Contact Section', 'Connect with our athletic faculty or report student registrations.', primaryColor, secondaryColor),
          const SizedBox(height: 48),

          if (isMobile) ...[
            _buildContactInfo(primaryColor, secondaryColor, onBackgroundColor),
            const SizedBox(height: 24),
            _buildMapPlaceholder(primaryColor, secondaryColor, isDark),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildContactInfo(primaryColor, secondaryColor, onBackgroundColor),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 6,
                  child: _buildMapPlaceholder(primaryColor, secondaryColor, isDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfo(Color primaryColor, Color secondaryColor, Color onBackgroundColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get in Touch',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reach out directly to the Office of physical education for facility bookings or tournament support.',
          style: TextStyle(
            fontSize: 13,
            color: onBackgroundColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        _buildContactTile(Icons.location_on_rounded, 'College Address', 'MRCAS Campus, Manikam Ramaswami Nagar,\nMadurai - 625006, Tamil Nadu, India.', primaryColor),
        const SizedBox(height: 16),
        _buildContactTile(Icons.phone_rounded, 'Phone Contact', '+91 452 2345678, +91 9876543210', primaryColor),
        const SizedBox(height: 16),
        _buildContactTile(Icons.email_rounded, 'Official Email Address', 'sports@mrcas.edu.in, info@mrcas.edu.in', primaryColor),
      ],
    );
  }

  Widget _buildContactTile(IconData icon, String label, String value, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder(Color primaryColor, Color secondaryColor, bool isDark) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Graphic Map Lines Design
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: HeroGridPainter(lineColor: primaryColor),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 56,
                  color: secondaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Google Maps Interactive View',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MRCAS campus GPS location coordinate matches.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 11. FOOTER SECTION
  Widget _buildFooter(BuildContext context, Color primaryColor, Color secondaryColor, Color onBackgroundColor, bool isDark) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    return Container(
      padding: const EdgeInsets.all(40.0),
      color: isDark ? const Color(0xFF070B14) : const Color(0xFF0F172A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              if (isMobile) ...[
                _buildFooterCollegeInfo(primaryColor, secondaryColor),
                const SizedBox(height: 24),
                _buildFooterFastLinks(primaryColor, secondaryColor),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildFooterCollegeInfo(primaryColor, secondaryColor),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 4,
                      child: _buildFooterFastLinks(primaryColor, secondaryColor),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              const Divider(color: Colors.white12),
              const SizedBox(height: 20),
              // Copyright Section
              Text(
                '© 2026 MRCAS – Manikam Ramaswami College of Arts & Science. All Rights Reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Managed by the Department of Physical Education & Sports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterCollegeInfo(Color primaryColor, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MRCAS',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: secondaryColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manikam Ramaswami College of Arts & Science',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Department of Physical Education & Sports',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterFastLinks(Color primaryColor, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Navigation Links',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildFooterLink('Home', () => _scrollToSection(_heroKey), secondaryColor),
            _buildFooterLink('About', () => _scrollToSection(_aboutKey), secondaryColor),
            _buildFooterLink('Sports', () => _scrollToSection(_sportsKey), secondaryColor),
            _buildFooterLink('Events', () => _scrollToSection(_eventsKey), secondaryColor),
            _buildFooterLink('Gallery', () => _scrollToSection(_galleryKey), secondaryColor),
            _buildFooterLink('Contact', () => _scrollToSection(_contactKey), secondaryColor),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(String title, VoidCallback onTap, Color secondaryColor) {
    return InkWell(
      onTap: onTap,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.65),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Common Header Helper for Sections
  Widget _buildSectionHeader(String title, String subtitle, Color primaryColor, Color secondaryColor) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

// Custom Painter to draw grid lines on Hero background
class HeroGridPainter extends CustomPainter {
  final Color lineColor;

  HeroGridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
