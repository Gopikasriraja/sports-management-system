import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../providers/event_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../home/widgets/glass_card.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../models/event_model.dart';
import 'components/add_edit_event_dialog.dart';

class EventManagementView extends StatefulWidget {
  const EventManagementView({super.key});

  @override
  State<EventManagementView> createState() => _EventManagementViewState();
}

class _EventManagementViewState extends State<EventManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _filterCategory = 'All';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Data stream is initialized in provider constructor
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: GlassCard(
        backgroundOpacity: isDark ? 0.15 : 0.6,
        borderRadius: 14,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String val,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      value: val,
      isDense: true,
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(10),
      hint: Text(label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  List<EventModel> _getEventsForDay(DateTime day, List<EventModel> allEvents) {
    return allEvents.where((event) => isSameDay(event.startDate, day) || 
      (event.startDate.isBefore(day) && event.endDate.isAfter(day)) || 
      isSameDay(event.endDate, day)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool canManageEvents =
        AppRoles.canManageEvents(auth.currentUser?.role);

    final eventProvider = Provider.of<EventProvider>(context);
    List<EventModel> allEvents = eventProvider.events;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      allEvents = allEvents.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query) ||
            e.venue.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterCategory != 'All') {
      allEvents = allEvents.where((e) => e.category == _filterCategory).toList();
    }

    if (_filterStatus != 'All') {
      allEvents = allEvents.where((e) => e.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            _buildSummaryCard('Total Events', eventProvider.totalEvents.toString(), Icons.event_note_rounded, primaryColor, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Upcoming Events', eventProvider.upcomingEventsCount.toString(), Icons.schedule_rounded, Colors.blueAccent, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Ongoing Events', eventProvider.ongoingEventsCount.toString(), Icons.play_circle_outline_rounded, Colors.green, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Completed Events', eventProvider.completedEventsCount.toString(), Icons.check_circle_outline_rounded, Colors.purpleAccent, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('This Month', eventProvider.thisMonthEventsCount.toString(), Icons.calendar_month_rounded, Colors.orange, isDark),
          ],
        ),
        const SizedBox(height: 24),
        TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: secondaryColor,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Calendar View'),
            Tab(text: 'Agenda / List View'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 700,
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Calendar View
              GlassCard(
                backgroundOpacity: isDark ? 0.15 : 0.65,
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          if (canManageEvents)
                            Align(
                              alignment: Alignment.centerRight,
                              child: FloatingActionButton.extended(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const AddEditEventDialog(),
                                  );
                                },
                                label: const Text('Create Event'),
                                icon: const Icon(Icons.add_rounded),
                                backgroundColor: secondaryColor,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                elevation: 2,
                              ),
                            ),
                          const SizedBox(height: 12),
                          TableCalendar<EventModel>(
                            firstDay: DateTime.utc(2020, 10, 16),
                            lastDay: DateTime.utc(2030, 3, 14),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              if (!isSameDay(_selectedDay, selectedDay)) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              }
                            },
                            onFormatChanged: (format) {
                              if (_calendarFormat != format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              }
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                            eventLoader: (day) => _getEventsForDay(day, eventProvider.events),
                            headerStyle: const HeaderStyle(formatButtonVisible: true, titleCentered: true),
                            calendarStyle: CalendarStyle(
                              selectedDecoration: BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                              todayDecoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.5), shape: BoxShape.circle),
                              markerDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Events on ${DateFormat('MMM dd, yyyy').format(_selectedDay ?? DateTime.now())}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Divider(),
                            Expanded(
                              child: _getEventsForDay(_selectedDay ?? DateTime.now(), eventProvider.events).isEmpty
                                  ? const Center(child: Text('No events for this day.'))
                                  : ListView.builder(
                                      itemCount: _getEventsForDay(_selectedDay ?? DateTime.now(), eventProvider.events).length,
                                      itemBuilder: (context, index) {
                                        final event = _getEventsForDay(_selectedDay ?? DateTime.now(), eventProvider.events)[index];
                                        return Card(
                                          elevation: 0,
                                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                          margin: const EdgeInsets.symmetric(vertical: 8),
                                          child: ListTile(
                                            leading: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: primaryColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                image: event.bannerImage.isNotEmpty
                                                    ? DecorationImage(image: NetworkImage(event.bannerImage), fit: BoxFit.cover)
                                                    : null,
                                              ),
                                              child: event.bannerImage.isEmpty ? Icon(Icons.event, color: primaryColor) : null,
                                            ),
                                            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text('${event.startTime} - ${event.venue}'),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Agenda View
              GlassCard(
                backgroundOpacity: isDark ? 0.15 : 0.65,
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SearchBar(
                            controller: _searchController,
                            hintText: 'Search...',
                            leading: const Icon(Icons.search_rounded),
                            elevation: WidgetStateProperty.all(0),
                            backgroundColor: WidgetStateProperty.all(
                              isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildFilterDropdown(
                          label: 'Category',
                          val: _filterCategory,
                          items: ['All', 'Cricket', 'Football', 'Basketball', 'Other'],
                          onChanged: (val) => setState(() => _filterCategory = val ?? 'All'),
                        ),
                        const SizedBox(width: 12),
                        _buildFilterDropdown(
                          label: 'Status',
                          val: _filterStatus,
                          items: ['All', 'Upcoming', 'Ongoing', 'Completed', 'Cancelled'],
                          onChanged: (val) => setState(() => _filterStatus = val ?? 'All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                          columns: const [
                            DataColumn(label: Text('Banner', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Venue', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: allEvents.map((e) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    width: 40,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      image: e.bannerImage.isNotEmpty
                                          ? DecorationImage(image: NetworkImage(e.bannerImage), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: e.bannerImage.isEmpty ? Icon(Icons.image_outlined, size: 16, color: primaryColor) : null,
                                  ),
                                ),
                                DataCell(Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(e.category)),
                                DataCell(Text('${DateFormat('MMM dd').format(e.startDate)} - ${DateFormat('MMM dd').format(e.endDate)}\n${e.startTime}')),
                                DataCell(Text(e.venue)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: e.status.toLowerCase() == 'completed' ? Colors.green.withValues(alpha: 0.1) : 
                                             e.status.toLowerCase() == 'upcoming' ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      e.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: e.status.toLowerCase() == 'completed' ? Colors.green : 
                                             e.status.toLowerCase() == 'upcoming' ? Colors.blue : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.visibility_rounded, size: 18), onPressed: () {}),
                                      if (canManageEvents)
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blueAccent),
                                          tooltip: 'Edit Event',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AddEditEventDialog(event: e),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
