// dart:convert removed - unused import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/validation/student_registration_validator.dart';
import '../../../models/student_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/achievement_provider.dart';
import '../../../providers/equipment_provider.dart';
import '../../home/widgets/glass_card.dart';

// Conditionally import HTML helper for Web downloads without breaking compile on VM/native platforms
import 'export_helper_stub.dart'
    if (dart.library.html) 'export_helper_web.dart'
    as exporter;

class StudentManagementView extends StatefulWidget {
  const StudentManagementView({super.key});

  @override
  State<StudentManagementView> createState() => _StudentManagementViewState();
}

class _StudentManagementViewState extends State<StudentManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _filterDept = 'All';
  String _filterSubDept = 'All';
  String _filterYear = 'All';
  String _filterSport = 'All';
  String _filterStatus = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;

  int _currentPage = 1;
  static const int _pageSize = 8;
  String? _selectedDepartment;
  String? _selectedSubDepartment;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerWebDownload(String content, String fileName, String mimeType) {
    if (kIsWeb) {
      exporter.saveAndDownloadWeb(content, fileName, mimeType);
    }
  }

  String _csvField(String value) => '"${value.replaceAll('"', '""')}"';

  void _exportToCSV(List<StudentModel> students) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Register Number,Name,Department,Year,Section,Gender,Phone,Email,Blood Group,Sports,Address,Status,Created At',
    );

    for (final s in students) {
      final row = [
        s.registerNumber,
        s.name,
        s.department,
        s.year,
        s.section,
        s.gender,
        s.phone,
        s.email,
        s.bloodGroup,
        s.sports.join('; '),
        s.address,
        s.status,
        s.createdAt.toIso8601String(),
      ].map(_csvField);
      buffer.writeln(row.join(','));
    }

    if (kIsWeb) {
      _triggerWebDownload(
        buffer.toString(),
        'MRCAS_Student_List.csv',
        'text/csv',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student list exported successfully as CSV!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('CSV export is ready to view.'),
          action: SnackBarAction(
            label: 'Show CSV',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('CSV Export Data'),
                  content: SizedBox(
                    width: 500,
                    height: 300,
                    child: SingleChildScrollView(
                      child: SelectableText(buffer.toString()),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          backgroundColor: AppColors.secondaryLight,
        ),
      );
    }
  }

  void _showStudentTextReport(List<StudentModel> students) {
    final buffer = StringBuffer();
    buffer.writeln('MRCAS Physical Education & Sports Department');
    buffer.writeln('OFFICIAL STUDENT ATHLETE REGISTRATION REPORT');
    buffer.writeln(
      'Generated on: ${DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now())}',
    );
    buffer.writeln('Total Registered Athletes: ${students.length}\n');
    buffer.writeln('=' * 80);
    buffer.writeln(
      '${'REG NO'.padRight(12)} ${'STUDENT NAME'.padRight(22)} ${'DEPT'.padRight(12)} ${'YEAR'.padRight(10)} ${'SPORTS'}',
    );
    buffer.writeln('=' * 80);

    for (final s in students) {
      final sSports = s.sports.take(2).join(', ');
      buffer.writeln(
        '${s.registerNumber.padRight(12)} '
        '${s.name.padRight(22).substring(0, s.name.length > 21 ? 21 : s.name.length)} '
        '${s.department.padRight(12).substring(0, s.department.length > 11 ? 11 : s.department.length)} '
        '${s.year.padRight(10)} '
        '$sSports',
      );
    }
    buffer.writeln('=' * 80);

    if (kIsWeb) {
      _triggerWebDownload(
        buffer.toString(),
        'MRCAS_Student_List_Report.txt',
        'text/plain',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text report downloaded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF / Printable Report Preview'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                buffer.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final Color secondaryColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackgroundLight;

    final studentProvider = Provider.of<StudentProvider>(context);

    // Apply Search, Filters, Sorting & Pagination local list builders
    List<StudentModel> list = studentProvider.students;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      list = list.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.registerNumber.toLowerCase().contains(query) ||
            s.department.toLowerCase().contains(query) ||
            s.subDepartment.toLowerCase().contains(query) ||
            s.year.toLowerCase().contains(query) ||
            s.sports.any((sport) => sport.toLowerCase().contains(query));
      }).toList();
    }

    // Filter logic
    if (_filterDept != 'All') {
      list = list.where((s) => s.department == _filterDept).toList();
    }
    if (_filterSubDept != 'All') {
      list = list.where((s) => s.subDepartment == _filterSubDept).toList();
    }
    if (_filterYear != 'All') {
      list = list.where((s) => s.year == _filterYear).toList();
    }
    if (_filterSport != 'All') {
      list = list.where((s) => s.sports.contains(_filterSport)).toList();
    }
    if (_filterStatus != 'All') {
      list = list
          .where(
            (student) =>
                student.status.toLowerCase() == _filterStatus.toLowerCase(),
          )
          .toList();
    }

    // Sort logic
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'Name':
          cmp = a.name.compareTo(b.name);
          break;
        case 'Register Number':
          cmp = a.registerNumber.compareTo(b.registerNumber);
          break;
        case 'Department':
          cmp = a.department.compareTo(b.department);
          break;
        case 'Year':
          cmp = a.year.compareTo(b.year);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    // Hierarchy filter logic
    if (_selectedDepartment != null) {
      list = list.where((s) => s.department == _selectedDepartment).toList();
    }
    if (_selectedSubDepartment != null && _selectedSubDepartment!.isNotEmpty) {
      list = list
          .where((s) => s.subDepartment == _selectedSubDepartment)
          .toList();
    }
    if (_selectedYear != null) {
      list = list.where((s) => s.year == _selectedYear).toList();
    }

    // Pagination calculations
    final int totalItems = list.length;
    final int totalPages = (totalItems / _pageSize).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final int startIndex = (_currentPage - 1) * _pageSize;
    final int endIndex = startIndex + _pageSize > totalItems
        ? totalItems
        : startIndex + _pageSize;
    final List<StudentModel> paginatedList = totalItems > 0
        ? list.sublist(startIndex, endIndex)
        : [];

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumbs(primaryColor),
          const SizedBox(height: 16),
          if (_selectedDepartment == null)
            _buildDepartmentView(isDark, primaryColor, studentProvider.students)
          else if (_selectedSubDepartment == null)
            _buildSubDepartmentView(
              isDark,
              primaryColor,
              studentProvider.students,
            )
          else if (_selectedYear == null)
            _buildYearView(isDark, primaryColor, studentProvider.students)
          else ...[
            // 1. Controls Bar (Search, Filters, Action buttons)
            GlassCard(
              backgroundOpacity: isDark ? 0.15 : 0.65,
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search row with add & import/export triggers
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SearchBar(
                          controller: _searchController,
                          hintText:
                              'Search by Name, Reg Number, Dept, Sport...',
                          leading: const Icon(Icons.search_rounded),
                          elevation: WidgetStateProperty.all(0),
                          backgroundColor: WidgetStateProperty.all(
                            isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                          onChanged: (val) => setState(() {}),
                          trailing: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                }),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!isMobile) ...[
                        // Export Dropdown
                        PopupMenuButton<String>(
                          tooltip: 'Export Student Records',
                          child: OutlinedButton.icon(
                            onPressed: null, // Open dropdown via menu trigger
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Export'),
                          ),
                          onSelected: (val) {
                            if (val == 'csv') {
                              _exportToCSV(list);
                            } else if (val == 'pdf') {
                              _showStudentTextReport(list);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'csv',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_view_rounded,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Export to Excel / CSV'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'pdf',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text('View / download text report'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                      ],
                      FloatingActionButton.extended(
                        onPressed: () => _showAddEditDialog(null),
                        label: const Text('Add Student'),
                        icon: const Icon(Icons.add_rounded),
                        backgroundColor: secondaryColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filters & Sorting selectors row
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      _buildFilterDropdown(
                        label: 'Dept',
                        val: _filterDept,
                        items: [
                          'All',
                          'B.Sc Computer Science',
                          'BBA',
                          'B.Com',
                          'Visual Communication',
                          'Psychology',
                          'Costume Design & Fashion Technology (CDFT)',
                        ],
                        onChanged: (val) => setState(() {
                          _filterDept = val!;
                          _currentPage = 1;
                        }),
                      ),
                      _buildFilterDropdown(
                        label: 'Sub Dept',
                        val: _filterSubDept,
                        items: [
                          'All',
                          'Artificial Intelligence (AI)',
                          'Data Science & Analytics (DSA)',
                          'FinTech & Blockchain (FTB)',
                          'Cyber Security & Cloud Computing (CSCC)',
                          'General BBA',
                          'BBA Digital Marketing (BBA DM)',
                          'Computer Applications (CA)',
                          'General',
                          'Professional Accounting (PA)',
                        ],
                        onChanged: (val) => setState(() {
                          _filterSubDept = val!;
                          _currentPage = 1;
                        }),
                      ),
                      _buildFilterDropdown(
                        label: 'Year',
                        val: _filterYear,
                        items: [
                          'All',
                          '1st Year',
                          '2nd Year',
                          '3rd Year',
                          'PG 1st Year',
                          'PG 2nd Year',
                        ],
                        onChanged: (val) => setState(() {
                          _filterYear = val!;
                          _currentPage = 1;
                        }),
                      ),
                      _buildFilterDropdown(
                        label: 'Sport',
                        val: _filterSport,
                        items: [
                          'All',
                          'Football',
                          'Athletics',
                          'Basketball',
                          'Cricket',
                          'Volleyball',
                          'Badminton',
                        ],
                        onChanged: (val) => setState(() {
                          _filterSport = val!;
                          _currentPage = 1;
                        }),
                      ),
                      _buildFilterDropdown(
                        label: 'Status',
                        val: _filterStatus,
                        items: ['All', 'Active', 'Inactive'],
                        onChanged: (val) => setState(() {
                          _filterStatus = val!;
                          _currentPage = 1;
                        }),
                      ),
                      _buildFilterDropdown(
                        label: 'Sort By',
                        val: _sortBy,
                        items: [
                          'Name',
                          'Register Number',
                          'Department',
                          'Year',
                        ],
                        onChanged: (val) => setState(() {
                          _sortBy = val!;
                        }),
                      ),
                      IconButton(
                        icon: Icon(
                          _sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                        ),
                        tooltip: _sortAscending
                            ? 'Sort Ascending'
                            : 'Sort Descending',
                        onPressed: () => setState(() {
                          _sortAscending = !_sortAscending;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Data Render Section
            studentProvider.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : paginatedList.isEmpty
                ? Center(
                    child: GlassCard(
                      backgroundOpacity: isDark ? 0.1 : 0.4,
                      borderRadius: 16,
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 64,
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Student Athletes Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your search criteria or filter options.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Responsive Layout
                      isMobile
                          ? ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: paginatedList.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final s = paginatedList[index];
                                return _buildMobileStudentCard(
                                  s,
                                  primaryColor,
                                  secondaryColor,
                                  onBackgroundColor,
                                );
                              },
                            )
                          : GlassCard(
                              backgroundOpacity: isDark ? 0.15 : 0.65,
                              borderRadius: 16,
                              padding: EdgeInsets.zero,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 24,
                                  headingRowColor: WidgetStateProperty.all(
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.03)
                                        : Colors.black.withValues(alpha: 0.02),
                                  ),
                                  columns: [
                                    const DataColumn(
                                      label: Text(
                                        'Athlete',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Reg No',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Dept & Year',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Sport',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Phone',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: paginatedList.map((s) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: primaryColor
                                                    .withValues(alpha: 0.1),
                                                child: Text(
                                                  s.name[0].toUpperCase(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                s.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (s.isSportsQuota) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.shade700
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'QUOTA',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.amber.shade700,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(s.registerNumber)),
                                        DataCell(
                                          Text(
                                            '${s.department}${s.subDepartment.isNotEmpty ? '\n${s.subDepartment}' : ''} (${s.year})',
                                          ),
                                        ),
                                        DataCell(
                                          Wrap(
                                            spacing: 4,
                                            children: s.sports.map((sport) {
                                              return Chip(
                                                labelPadding: EdgeInsets.zero,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 0,
                                                    ),
                                                label: Text(
                                                  sport,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        DataCell(Text(s.phone)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: s.status == 'Active'
                                                  ? Colors.green.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : Colors.red.withValues(
                                                      alpha: 0.08,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              s.status,
                                              style: TextStyle(
                                                color: s.status == 'Active'
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.visibility_rounded,
                                                  size: 18,
                                                ),
                                                tooltip: 'View Profile',
                                                onPressed: () =>
                                                    _showStudentDetails(s),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                  size: 18,
                                                  color: Colors.blueAccent,
                                                ),
                                                tooltip: 'Edit Record',
                                                onPressed: () =>
                                                    _showAddEditDialog(s),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  s.status.toLowerCase() ==
                                                          'active'
                                                      ? Icons
                                                            .person_off_outlined
                                                      : Icons.person_outline,
                                                  size: 18,
                                                  color: Colors.redAccent,
                                                ),
                                                tooltip:
                                                    s.status.toLowerCase() ==
                                                        'active'
                                                    ? 'Deactivate student'
                                                    : 'Reactivate student',
                                                onPressed: () =>
                                                    _showDeleteConfirm(s),
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

                      // 3. Pagination Controls Row
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${startIndex + 1} to $endIndex of $totalItems athletes',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: onBackgroundColor.withValues(alpha: 0.6),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded),
                                onPressed: _currentPage > 1
                                    ? () => setState(() => _currentPage--)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Page $_currentPage of $totalPages',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded),
                                onPressed: _currentPage < totalPages
                                    ? () => setState(() => _currentPage++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String val,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          onChanged: onChanged,
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(
                '$label: $e',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileStudentCard(
    StudentModel s,
    Color primaryColor,
    Color secondaryColor,
    Color onBackgroundColor,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          child: Text(
            s.name[0].toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            if (s.isSportsQuota)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'QUOTA',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Reg No: ${s.registerNumber}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${s.department}${s.subDepartment.isNotEmpty ? ' - ${s.subDepartment}' : ''} (${s.year})',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: s.sports.map((sport) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sport,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: s.status == 'Active'
                    ? Colors.green.withValues(alpha: 0.08)
                    : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.status,
                style: TextStyle(
                  color: s.status == 'Active' ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'view') {
              _showStudentDetails(s);
            } else if (val == 'edit') {
              _showAddEditDialog(s);
            } else if (val == 'status') {
              _showDeleteConfirm(s);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Athlete')),
            PopupMenuItem(
              value: 'status',
              child: Text(
                s.status.toLowerCase() == 'active'
                    ? 'Deactivate student'
                    : 'Reactivate student',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(StudentModel s) {
    final deactivate = s.status.toLowerCase() == 'active';
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deactivate ? 'Deactivate student?' : 'Reactivate student?'),
        content: Text(
          '${deactivate ? 'Deactivate' : 'Reactivate'} ${s.name} '
          '(${s.registerNumber})? Existing participation records will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(deactivate ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      final actor = context.read<AuthProvider>().currentUser;
      if (actor == null || !AppRoles.canManageStudents(actor.role)) return;
      final userProvider = context.read<UserProvider>();
      final studentProvider = context.read<StudentProvider>();
      final linkedUser = userProvider.users.cast<UserModel?>().firstWhere(
        (user) =>
            user?.uid == s.studentId ||
            user?.registerNumber.toLowerCase() ==
                s.registerNumber.toLowerCase(),
        orElse: () => null,
      );
      if (linkedUser != null) {
        final accountUpdated = await userProvider.updateUser(
          existingUser: linkedUser,
          actorUid: actor.uid,
          actorRole: actor.role,
          name: linkedUser.name,
          department: linkedUser.department,
          role: AppRoles.student,
          phone: linkedUser.phone,
          status: deactivate ? 'inactive' : 'active',
          registerNumber: linkedUser.registerNumber,
        );
        if (!accountUpdated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  userProvider.errorMessage ?? 'Could not update the account.',
                ),
              ),
            );
          }
          return;
        }
      }
      final updated = await studentProvider.saveStudent(
        s.copyWith(status: deactivate ? 'Inactive' : 'Active'),
        actorUid: actor.uid,
        actorRole: actor.role,
      );
      var statusMessage = updated
          ? 'Student ${deactivate ? 'deactivated' : 'reactivated'}.'
          : studentProvider.errorMessage ?? 'Could not update student status.';
      if (!updated && linkedUser != null) {
        final accountRestored = await userProvider.updateUser(
          existingUser: linkedUser,
          actorUid: actor.uid,
          actorRole: actor.role,
          name: linkedUser.name,
          department: linkedUser.department,
          role: AppRoles.student,
          phone: linkedUser.phone,
          status: linkedUser.status,
          registerNumber: linkedUser.registerNumber,
        );
        if (!accountRestored) {
          statusMessage +=
              ' The linked account status could not be restored: '
              '${userProvider.errorMessage ?? 'unknown error'}';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(statusMessage)));
      }
    });
  }

  void _showStudentDetails(StudentModel student) {
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null) return;
    // Dynamically trigger asynchronous provider loading for student statistics
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    final achievementProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );
    final equipmentProvider = Provider.of<EquipmentProvider>(
      context,
      listen: false,
    );

    attendanceProvider.fetchAttendanceForStudent(
      student.studentId,
      actorUid: actor.uid,
      actorRole: actor.role,
    );
    achievementProvider.fetchAchievementsForStudent(student.studentId);
    equipmentProvider.fetchIssuesByStudent(student.studentId);

    showDialog(
      context: context,
      builder: (context) {
        return Consumer3<
          AttendanceProvider,
          AchievementProvider,
          EquipmentProvider
        >(
          builder: (context, attendance, achievement, equipment, child) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            final Color primaryColor = isDark
                ? AppColors.primaryDark
                : AppColors.primaryLight;
            // ignore: unused_local_variable
            final Color secondaryColor = isDark
                ? AppColors.secondaryDark
                : AppColors.secondaryLight;
            final Color onBackgroundColor = isDark
                ? AppColors.onBackgroundDark
                : AppColors.onBackgroundLight;

            // Compute statistics
            final logs = attendance.attendanceLogs;
            final presentCount = logs
                .where((l) => l.status == 'Present' || l.status == 'Late')
                .length;
            final absentCount = logs
                .where((l) => l.status == 'Absent')
                .length;
            final totalAttendance = logs
                .where(
                  (l) =>
                      l.status == 'Present' ||
                      l.status == 'Absent' ||
                      l.status == 'Late',
                )
                .length;
            final double attendancePercentage = totalAttendance > 0
                ? (presentCount / totalAttendance) * 100
                : 0.0;

            final achievementsList = achievement.achievements;
            final issuedLogsList = equipment.issueLogs;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: DefaultTabController(
                length: 10,
                child: Container(
                  width: 900,
                  height: 700,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  student.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Register Number: ${student.registerNumber}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: onBackgroundColor.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        isScrollable: true,
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: primaryColor,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        tabs: const [
                          Tab(text: 'Profile'),
                          Tab(text: 'Contact'),
                          Tab(text: 'Parent'),
                          Tab(text: 'Academic'),
                          Tab(text: 'Sports'),
                          Tab(text: 'Medical'),
                          Tab(text: 'Achievements'),
                          Tab(text: 'Attendance'),
                          Tab(text: 'Documents'),
                          Tab(text: 'Equipment'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProfileTab(student),
                            _buildContactTab(student),
                            _buildParentTab(student),
                            _buildAcademicTab(student),
                            _buildSportsTab(student),
                            _buildMedicalTab(student),
                            _buildAchievementsTab(
                              student,
                              achievementsList,
                              primaryColor,
                            ),
                            _buildAttendanceTab(
                              student,
                              totalAttendance,
                              presentCount,
                              absentCount,
                              attendancePercentage,
                              primaryColor,
                            ),
                            _buildDocumentsTab(student, primaryColor),
                            _buildEquipmentTab(
                              student,
                              issuedLogsList,
                              primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool highlight = false,
    Color highlightColor = Colors.green,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: highlight ? highlightColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(StudentModel? student) {
    final formKey = GlobalKey<FormState>();
    final isEdit = student != null;
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null || !AppRoles.canManageStudents(actor.role)) return;

    final regNoCtrl = TextEditingController(
      text: student?.registerNumber ?? '',
    );
    final nameCtrl = TextEditingController(text: student?.name ?? '');
    final phoneCtrl = TextEditingController(text: student?.phone ?? '');
    final emailCtrl = TextEditingController(text: student?.email ?? '');
    final passwordCtrl = TextEditingController(text: 'Student@123');
    final addressCtrl = TextEditingController(text: student?.address ?? '');

    String dept = student?.department ?? 'Sports Science';
    String year = student?.year ?? '3rd Year';
    String section = student?.section ?? 'A';
    String gender = student?.gender ?? 'Male';
    String blood = student?.bloodGroup ?? 'B+';
    List<String> selectedSports = student != null
        ? List.from(student.sports)
        : [];

    XFile? pickedProfileImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final Color primaryColor = isDark
              ? AppColors.primaryDark
              : AppColors.primaryLight;
          final Color secondaryColor = isDark
              ? AppColors.secondaryDark
              : AppColors.secondaryLight;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                  color: secondaryColor,
                ),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit Student Details' : 'Add New Student'),
              ],
            ),
            content: SizedBox(
              width: 600,
              height: 550,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image upload row
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(Icons.person_rounded, size: 36),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final file = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (file != null) {
                                  setDialogState(() {
                                    pickedProfileImage = file;
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.add_a_photo_rounded,
                                size: 16,
                              ),
                              label: Text(
                                pickedProfileImage == null
                                    ? 'Upload Profile Photo'
                                    : 'Image Selected',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: regNoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Register Number *',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            StudentRegistrationValidator.validateRegisterNumber,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Student Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: StudentRegistrationValidator.validateName,
                      ),
                      const SizedBox(height: 12),

                      // Dept & Year selectors
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: dept,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  [
                                        'Sports Science',
                                        'Physical Education',
                                        'Arts',
                                        'Commerce',
                                        'B.Sc CS',
                                      ]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) => dept = val!,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: year,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(),
                              ),
                              items: ['1st Year', '2nd Year', '3rd Year']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => year = val!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Section & Gender selectors
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: section,
                              decoration: const InputDecoration(
                                labelText: 'Section',
                                border: OutlineInputBorder(),
                              ),
                              items: ['A', 'B', 'C']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => section = val!,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: gender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Male', 'Female']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => gender = val!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: StudentRegistrationValidator.validateEmail,
                      ),
                      const SizedBox(height: 12),

                      if (!isEdit) ...[
                        TextFormField(
                          controller: passwordCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Initial Password *',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (val) =>
                              val == null || val.trim().length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Blood group
                      DropdownButtonFormField<String>(
                        initialValue: blood,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => blood = val!,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Address Details',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Sports Checklist
                      const Text(
                        'Sports Interests * (Select one or more)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            [
                              'Football',
                              'Athletics',
                              'Basketball',
                              'Cricket',
                              'Volleyball',
                              'Badminton',
                            ].map((sport) {
                              final isSelected = selectedSports.contains(sport);
                              return FilterChip(
                                label: Text(sport),
                                selected: isSelected,
                                onSelected: (checked) {
                                  setDialogState(() {
                                    if (checked) {
                                      selectedSports.add(sport);
                                    } else {
                                      selectedSports.remove(sport);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (selectedSports.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one sport.'),
                        ),
                      );
                      return;
                    }

                    final studentProvider = context.read<StudentProvider>();
                    final userProvider = context.read<UserProvider>();
                    bool registerAvailable;
                    try {
                      registerAvailable = await studentProvider
                          .isRegisterNumberAvailable(
                            regNoCtrl.text,
                            actorUid: actor.uid,
                            actorRole: actor.role,
                            excludingStudentId: student?.studentId,
                            excludingEmail: student?.email,
                          );
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not verify register number uniqueness: '
                              '$error',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    if (!registerAvailable) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'A student with this register number already exists.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // 1. Create or update credentials in users collection
                    String finalStudentId = student?.studentId ?? '';

                    if (!isEdit) {
                      final success = await userProvider.createUser(
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        department: dept,
                        role: 'Student',
                        status: 'Active',
                        password: passwordCtrl.text,
                        registerNumber: regNoCtrl.text.trim(),
                        profileImageFile: pickedProfileImage,
                        actorUid: actor.uid,
                        actorRole: actor.role,
                      );
                      if (!success) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                userProvider.errorMessage ??
                                    'Failed to create student credentials.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }

                      final matchingUsers = userProvider.users.where(
                        (user) =>
                            user.email.toLowerCase() ==
                            emailCtrl.text.trim().toLowerCase(),
                      );
                      if (matchingUsers.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'The user profile was created but could not '
                                'be linked to the student record.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }
                      finalStudentId = matchingUsers.first.uid;
                    } else {
                      // Update existing user document
                      final existingUser = userProvider.users.firstWhere(
                        (u) => u.registerNumber == student.registerNumber,
                        orElse: () => UserModel(
                          uid: student.studentId,
                          name: student.name,
                          email: student.email,
                          role: 'Student',
                          department: student.department,
                          year: student.year,
                          registerNumber: student.registerNumber,
                          phone: student.phone,
                          profileImage: student.profileImage,
                          status: student.status.toLowerCase(),
                          createdAt: student.createdAt,
                        ),
                      );
                      final success = await userProvider.updateUser(
                        existingUser: existingUser,
                        actorUid: actor.uid,
                        actorRole: actor.role,
                        name: nameCtrl.text.trim(),
                        department: dept,
                        role: 'Student',
                        phone: phoneCtrl.text.trim(),
                        status: student.status.toLowerCase(),
                        registerNumber: regNoCtrl.text.trim(),
                        profileImageFile: pickedProfileImage,
                      );
                      if (!success) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                userProvider.errorMessage ??
                                    'Failed to update student credentials.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }
                      finalStudentId = student.studentId;
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                    }

                    String uploadUrl = student?.profileImage ?? '';
                    if (pickedProfileImage != null) {
                      uploadUrl = userProvider.selectedUser?.profileImage ?? '';
                    }

                    final newStudent = StudentModel(
                      studentId: finalStudentId,
                      registerNumber: regNoCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      department: dept,
                      year: year,
                      section: section,
                      gender: gender,
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      bloodGroup: blood,
                      address: addressCtrl.text.trim(),
                      sports: selectedSports,
                      profileImage: uploadUrl,
                      createdAt: student?.createdAt ?? DateTime.now(),
                      status: student?.status ?? 'Active',
                    );

                    final saved = await studentProvider.saveStudent(
                      newStudent,
                      actorUid: actor.uid,
                      actorRole: actor.role,
                    );
                    if (!context.mounted) return;
                    var saveMessage = saved
                        ? isEdit
                              ? 'Student profile updated.'
                              : 'Student registered successfully.'
                        : studentProvider.errorMessage ??
                              'Could not save student profile.';
                    if (!saved && !isEdit) {
                      final createdUser = userProvider.selectedUser;
                      if (createdUser != null &&
                          createdUser.uid == finalStudentId) {
                        final accountDeactivated = await userProvider
                            .updateUser(
                              existingUser: createdUser,
                              actorUid: actor.uid,
                              actorRole: actor.role,
                              name: createdUser.name,
                              department: createdUser.department,
                              role: createdUser.role,
                              phone: createdUser.phone,
                              status: 'inactive',
                              registerNumber: createdUser.registerNumber,
                            );
                        saveMessage += accountDeactivated
                            ? ' The new account was deactivated because its '
                                  'student record could not be saved.'
                            : ' The new account could not be deactivated: '
                                  '${userProvider.errorMessage ?? 'unknown error'}.';
                      }
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(saveMessage),
                        backgroundColor: saved
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                    );
                  }
                },
                child: const Text('Save Details'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumbs(Color primaryColor) {
    List<Widget> crumbs = [];

    // Root
    crumbs.add(
      InkWell(
        onTap: () => setState(() {
          _selectedDepartment = null;
          _selectedSubDepartment = null;
          _selectedYear = null;
        }),
        child: Text(
          'Departments',
          style: TextStyle(
            color: _selectedDepartment == null ? Colors.grey : primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (_selectedDepartment != null) {
      crumbs.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right, size: 16),
        ),
      );
      crumbs.add(
        InkWell(
          onTap: () => setState(() {
            _selectedSubDepartment = null;
            _selectedYear = null;
          }),
          child: Text(
            _selectedDepartment!,
            style: TextStyle(
              color: _selectedSubDepartment == null && _selectedYear == null
                  ? Colors.grey
                  : primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (_selectedSubDepartment != null && _selectedSubDepartment!.isNotEmpty) {
      crumbs.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right, size: 16),
        ),
      );
      crumbs.add(
        InkWell(
          onTap: () => setState(() {
            _selectedYear = null;
          }),
          child: Text(
            _selectedSubDepartment!,
            style: TextStyle(
              color: _selectedYear == null ? Colors.grey : primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (_selectedYear != null) {
      crumbs.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right, size: 16),
        ),
      );
      crumbs.add(
        Text(
          _selectedYear!,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: crumbs),
    );
  }

  Widget _buildDepartmentView(
    bool isDark,
    Color primaryColor,
    List<StudentModel> allStudents,
  ) {
    final depts = [
      'B.Sc Computer Science',
      'BBA',
      'B.Com',
      'Visual Communication',
      'Psychology',
      'Costume Design & Fashion Technology (CDFT)',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: depts.length,
      itemBuilder: (context, index) {
        final dept = depts[index];
        final count = allStudents.where((s) => s.department == dept).length;
        return InkWell(
          onTap: () => setState(() {
            _selectedDepartment = dept;
            if (dept == 'Visual Communication' ||
                dept == 'Psychology' ||
                dept == 'Costume Design & Fashion Technology (CDFT)') {
              _selectedSubDepartment = '';
            }
          }),
          child: GlassCard(
            backgroundOpacity: isDark ? 0.15 : 0.65,
            borderRadius: 12,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_center_rounded,
                  size: 32,
                  color: primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  dept,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count Students',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearView(
    bool isDark,
    Color primaryColor,
    List<StudentModel> allStudents,
  ) {
    final years = [
      '1st Year',
      '2nd Year',
      '3rd Year',
      'PG 1st Year',
      'PG 2nd Year',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final count = allStudents
            .where(
              (s) =>
                  s.department == _selectedDepartment &&
                  (s.subDepartment == _selectedSubDepartment ||
                      _selectedSubDepartment == '') &&
                  s.year == year,
            )
            .length;
        return InkWell(
          onTap: () => setState(() => _selectedYear = year),
          child: GlassCard(
            backgroundOpacity: isDark ? 0.15 : 0.65,
            borderRadius: 12,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded, size: 32, color: primaryColor),
                const SizedBox(height: 12),
                Text(
                  year,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count Students',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubDepartmentView(
    bool isDark,
    Color primaryColor,
    List<StudentModel> allStudents,
  ) {
    final Map<String, List<String>> structure = {
      'B.Sc Computer Science': [
        'Artificial Intelligence (AI)',
        'Data Science & Analytics (DSA)',
        'FinTech & Blockchain (FTB)',
        'Cyber Security & Cloud Computing (CSCC)',
      ],
      'BBA': ['General BBA', 'BBA Digital Marketing (BBA DM)'],
      'B.Com': [
        'Computer Applications (CA)',
        'General',
        'Professional Accounting (PA)',
      ],
    };

    final subDepts = structure[_selectedDepartment] ?? [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: subDepts.length,
      itemBuilder: (context, index) {
        final subDept = subDepts[index];
        final count = allStudents
            .where(
              (s) =>
                  s.department == _selectedDepartment &&
                  s.subDepartment == subDept,
            )
            .length;
        return InkWell(
          onTap: () => setState(() => _selectedSubDepartment = subDept),
          child: GlassCard(
            backgroundOpacity: isDark ? 0.15 : 0.65,
            borderRadius: 12,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree_rounded, size: 32, color: primaryColor),
                const SizedBox(height: 12),
                Text(
                  subDept,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count Students',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Student Details Tab Builders ---

  Widget _buildProfileTab(StudentModel student) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Department', student.department),
                if (student.subDepartment.isNotEmpty)
                  _buildDetailItem('Sub Department', student.subDepartment),
                _buildDetailItem('Academic Year', student.year),
                _buildDetailItem('Section', student.section),
                _buildDetailItem('Date of Birth', student.dateOfBirth),
                _buildDetailItem('Gender', student.gender),
                _buildDetailItem('Blood Group', student.bloodGroup),
                _buildDetailItem('Aadhaar Number', student.aadhaarNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab(StudentModel student) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Mobile Number', student.phone),
                _buildDetailItem(
                  'Alternate Mobile',
                  student.alternateMobileNumber,
                ),
                _buildDetailItem('Email', student.email),
                _buildDetailItem('Address', student.address),
                _buildDetailItem('City', student.city),
                _buildDetailItem('District', student.district),
                _buildDetailItem('State', student.state),
                _buildDetailItem('PIN Code', student.pinCode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentTab(StudentModel student) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(
                  'Father Name',
                  student.fatherName.isNotEmpty
                      ? student.fatherName
                      : student.parentName,
                ),
                _buildDetailItem('Mother Name', student.motherName),
                _buildDetailItem('Parent Mobile', student.parentMobileNumber),
                _buildDetailItem('Guardian Name', student.guardianName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicTab(StudentModel student) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Admission Year', student.admissionYear),
                _buildDetailItem('Current Semester', student.currentSemester),
                _buildDetailItem('Academic Status', student.academicStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsTab(StudentModel student) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Sports Name', student.sports.join(', ')),
                _buildDetailItem('Sports Category', student.sportsCategory),
                _buildDetailItem('Coach Name', student.coachName),
                _buildDetailItem(
                  'Sports Quota',
                  student.isSportsQuota ? 'Yes' : 'No',
                ),
                _buildDetailItem('Practice Batch', student.practiceBatch),
                _buildDetailItem('Jersey Number', student.jerseyNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab(StudentModel student) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Height', student.height),
                _buildDetailItem('Weight', student.weight),
                _buildDetailItem('Blood Group', student.bloodGroup),
                _buildDetailItem('Medical Issues', student.medicalIssues),
                _buildDetailItem('Emergency Contact', student.emergencyContact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(
    StudentModel student,
    List<dynamic> achievementsList,
    Color primaryColor,
  ) {
    if (achievementsList.isEmpty) {
      return const Center(
        child: Text(
          'No active achievements logged.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: achievementsList.length,
      itemBuilder: (context, index) {
        final ach = achievementsList[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: primaryColor.withValues(alpha: 0.04),
          child: ListTile(
            dense: true,
            leading: const Icon(
              Icons.military_tech_rounded,
              color: Colors.amber,
            ),
            title: Text(
              '${ach.medal} Medal in ${ach.event}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Level: ${ach.level} | Sport: ${ach.sport} (${ach.year})',
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab(
    StudentModel student,
    int totalAttendance,
    int presentCount,
    int absentCount,
    double attendancePercentage,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          SizedBox(
            width: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(
                  'Total Attendance Logs',
                  '$totalAttendance sessions',
                ),
                _buildDetailItem(
                  'Present Attendance',
                  '$presentCount sessions',
                ),
                _buildDetailItem('Absent Attendance', '$absentCount sessions'),
                _buildDetailItem(
                  'Attendance Ratio',
                  totalAttendance == 0
                      ? 'Unavailable'
                      : '${attendancePercentage.toStringAsFixed(1)}%',
                  highlight: true,
                  highlightColor: totalAttendance > 0 && attendancePercentage >= 85
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(StudentModel student, Color primaryColor) {
    final docs = [
      'Student Photo',
      'Aadhaar Copy',
      'Community Certificate',
      'Sports Certificate',
      'Medical Certificate',
    ];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          color: primaryColor.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preview/Download ${docs[index]} (Mocked)'),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file_rounded,
                  size: 36,
                  color: primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  docs[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEquipmentTab(
    StudentModel student,
    List<dynamic> issuedLogsList,
    Color primaryColor,
  ) {
    if (issuedLogsList.isEmpty) {
      return const Center(
        child: Text(
          'No equipment items currently issued to this student.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: issuedLogsList.length,
      itemBuilder: (context, index) {
        final log = issuedLogsList[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: primaryColor.withValues(alpha: 0.04),
          child: ListTile(
            dense: true,
            leading: const Icon(
              Icons.outbound_rounded,
              color: Colors.blueAccent,
            ),
            title: Text(
              'Issue Log Reference: #${log.issueId.substring(0, 5).toUpperCase()}',
            ),
            subtitle: Text(
              'Issued on: ${DateFormat('dd-MMM-yyyy').format(log.issueDate)} | Status: ${log.status.toUpperCase()}',
            ),
          ),
        );
      },
    );
  }
}
