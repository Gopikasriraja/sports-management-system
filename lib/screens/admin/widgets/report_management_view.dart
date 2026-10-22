import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../models/report_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/report_provider.dart';

class ReportManagementView extends StatefulWidget {
  const ReportManagementView({super.key});

  @override
  State<ReportManagementView> createState() => _ReportManagementViewState();
}

class _ReportManagementViewState extends State<ReportManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All';

  static const List<String> _reportTypes = [
    'Attendance',
    'Equipment',
    'Events',
    'Students',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createReport() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    var selectedType = _reportTypes.first;

    final reportDetails = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create report'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Report title',
                    hintText: 'e.g. October attendance summary',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a report title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Report type'),
                  items: _reportTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, (
                    titleController.text.trim(),
                    selectedType,
                  ));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    if (!mounted || reportDetails == null) return;

    final user = context.read<AuthProvider>().currentUser;
    final generatedBy = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : user?.email ?? 'Unknown';
    final report = ReportModel(
      reportId: DateTime.now().microsecondsSinceEpoch.toString(),
      title: reportDetails.$1,
      type: reportDetails.$2,
      generatedBy: generatedBy,
      generatedAt: DateTime.now(),
    );
    final provider = context.read<ReportProvider>();
    final saved = await provider.saveReport(report);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Report saved.'
              : 'Could not save report: ${provider.errorMessage ?? 'Unknown error'}',
        ),
        backgroundColor: saved ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _deleteReport(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text('“${report.title}” will be removed from report history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<ReportProvider>();
    final deleted = await provider.deleteReport(report.reportId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Report deleted.'
              : 'Could not delete report: ${provider.errorMessage ?? 'Unknown error'}',
        ),
        backgroundColor: deleted ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final canManageReports = AppRoles.canManageReports(
      context.watch<AuthProvider>().currentUser?.role,
    );

    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        final query = _searchController.text.trim().toLowerCase();
        final reports = provider.reports.where((report) {
          final matchesType =
              _selectedType == 'All' || report.type == _selectedType;
          final matchesQuery =
              query.isEmpty ||
              report.title.toLowerCase().contains(query) ||
              report.type.toLowerCase().contains(query) ||
              report.generatedBy.toLowerCase().contains(query);
          return matchesType && matchesQuery;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canManageReports
                          ? 'Create and review saved report records.'
                          : 'Review saved report records.',
                    ),
                  ],
                ),
                if (canManageReports)
                  FilledButton.icon(
                    onPressed: provider.isLoading ? null : _createReport,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create report record'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search reports',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['All', ..._reportTypes]
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedType = value);
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh reports',
                  onPressed: provider.isLoading ? null : provider.fetchReports,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.errorMessage != null)
              MaterialBanner(
                content: Text(
                  'Could not load reports: ${provider.errorMessage}',
                ),
                leading: const Icon(Icons.error_outline_rounded),
                actions: [
                  TextButton(
                    onPressed: provider.fetchReports,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            if (provider.isLoading && provider.reports.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (reports.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    canManageReports
                        ? 'No reports found. Create a report to get started.'
                        : 'No reports found.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            _iconForType(report.type),
                            color: primaryColor,
                          ),
                        ),
                        title: Text(
                          report.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${report.type} · ${report.generatedBy} · '
                          '${DateFormat.yMMMd().add_jm().format(report.generatedAt)}',
                        ),
                        trailing: canManageReports
                            ? IconButton(
                                tooltip: 'Delete report',
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _deleteReport(report),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Attendance':
        return Icons.fact_check_rounded;
      case 'Equipment':
        return Icons.sports_soccer_rounded;
      case 'Events':
        return Icons.event_note_rounded;
      case 'Students':
        return Icons.people_alt_rounded;
      default:
        return Icons.description_rounded;
    }
  }
}
