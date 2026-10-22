import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../models/equipment_model.dart';
import '../../../../providers/equipment_provider.dart';
import '../../../../providers/student_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../home/widgets/glass_card.dart';

import 'tabs/inventory_tab.dart';
import 'tabs/issue_equipment_tab.dart';
import 'tabs/returns_tab.dart';
import 'tabs/reports_tab.dart';
// Add Equipment feature removed for Phase 1

class EquipmentManagementView extends StatefulWidget {
  const EquipmentManagementView({super.key});

  @override
  State<EquipmentManagementView> createState() => _EquipmentManagementViewState();
}

class _EquipmentManagementViewState extends State<EquipmentManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _filterCategory = 'All';
  String _filterStockStatus = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;

  int _currentPage = 1;
  static const int _pageSize = 8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EquipmentProvider>(context, listen: false).fetchEquipment();
      Provider.of<EquipmentProvider>(context, listen: false).fetchIssues();
      Provider.of<EquipmentProvider>(context, listen: false).fetchReturns();
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool canManageInventory =
        AppRoles.canManageEquipmentInventory(auth.currentUser?.role);

    final equipProvider = Provider.of<EquipmentProvider>(context);

    // Filter Logic
    List<EquipmentModel> items = equipProvider.equipmentList;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      items = items.where((e) {
        return e.equipmentName.toLowerCase().contains(query) ||
            e.equipmentId.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query) ||
            e.brand.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterCategory != 'All') {
      items = items.where((e) => e.category == _filterCategory).toList();
    }

    if (_filterStockStatus != 'All') {
      items = items.where((e) {
        if (_filterStockStatus == 'Available') return e.availableQuantity > 0;
        if (_filterStockStatus == 'Issued') return e.issuedQuantity > 0;
        if (_filterStockStatus == 'Damaged') return e.damagedQuantity > 0;
        if (_filterStockStatus == 'Low Stock') return e.availableQuantity <= e.minStockLevel && e.availableQuantity > 0;
        return true;
      }).toList();
    }

    items.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'Name':
          cmp = a.equipmentName.compareTo(b.equipmentName);
          break;
        case 'ID':
          cmp = a.equipmentId.compareTo(b.equipmentId);
          break;
        case 'Category':
          cmp = a.category.compareTo(b.category);
          break;
        case 'Quantity':
          cmp = a.quantity.compareTo(b.quantity);
          break;
        case 'Brand':
          cmp = a.brand.compareTo(b.brand);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    final int totalItems = items.length;
    final int totalPages = (totalItems / _pageSize).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final int startIndex = (_currentPage - 1) * _pageSize;
    final int endIndex = startIndex + _pageSize > totalItems ? totalItems : startIndex + _pageSize;
    final List<EquipmentModel> paginatedItems = totalItems > 0 ? items.sublist(startIndex, endIndex) : [];

    final hasLowStock = equipProvider.lowStockEquipmentCount > 0;
    final hasOutOfStock = equipProvider.outOfStockEquipmentCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasOutOfStock || hasLowStock) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: hasOutOfStock ? Colors.redAccent.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasOutOfStock ? Colors.redAccent.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  hasOutOfStock ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                  color: hasOutOfStock ? Colors.redAccent : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasOutOfStock
                        ? 'Alert: ${equipProvider.outOfStockEquipmentCount} equipment types are completely OUT OF STOCK! Please update stock.'
                        : 'Alert: ${equipProvider.lowStockEquipmentCount} items are running low on available stock. Consider reordering.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: hasOutOfStock ? Colors.redAccent : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            _buildSummaryCard('Total Equipment', equipProvider.totalEquipmentCount.toString(), Icons.inventory_2_rounded, primaryColor, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Available Equipment', equipProvider.availableEquipmentUnits.toString(), Icons.check_circle_outline_rounded, Colors.green, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Issued Equipment', equipProvider.issuedEquipmentUnits.toString(), Icons.outbox_rounded, Colors.orange, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Damaged Equipment', equipProvider.damagedEquipmentUnits.toString(), Icons.broken_image_rounded, Colors.redAccent, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Low Stock', equipProvider.lowStockEquipmentCount.toString(), Icons.warning_amber_rounded, Colors.amber, isDark),
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
            Tab(text: 'Catalog Inventory'),
            Tab(text: 'Issued Logs'),
            Tab(text: 'Returns Logs'),
            Tab(text: 'Reports Ledger'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 700,
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Tab 1: Catalog
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                hintText: 'Search by Equipment Name, Category, Brand, Code...',
                                leading: const Icon(Icons.search_rounded),
                                elevation: WidgetStateProperty.all(0),
                                backgroundColor: WidgetStateProperty.all(
                                  isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                ),
                                onChanged: (val) => setState(() {
                                  _currentPage = 1;
                                }),
                              ),
                            ),
                            // [PHASE 1 - READ ONLY]: Add Equipment feature is disabled for now.
                            /*
                            const SizedBox(width: 12),
                            FloatingActionButton.extended(
                              onPressed: () => showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const AddEditEquipmentDialog(),
                              ),
                              label: const Text('Add Equipment'),
                              icon: const Icon(Icons.add_rounded),
                              backgroundColor: secondaryColor,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              elevation: 2,
                            ),
                            */
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildFilterDropdown(
                              label: 'Category',
                              val: _filterCategory,
                              items: [
                                'All', 'Cricket', 'Football', 'Basketball', 'Volleyball',
                                'Badminton', 'Athletics', 'Chess', 'Table Tennis',
                                'Kabaddi', 'Hockey', 'Yoga', 'Other'
                              ],
                              onChanged: (val) => setState(() {
                                _filterCategory = val!;
                                _currentPage = 1;
                              }),
                            ),
                            _buildFilterDropdown(
                              label: 'Stock status',
                              val: _filterStockStatus,
                              items: ['All', 'Available', 'Issued', 'Damaged', 'Low Stock'],
                              onChanged: (v) => setState(() => _filterStockStatus = v ?? 'All'),
                            ),
                            _buildFilterDropdown(
                              label: 'Sort By',
                              val: _sortBy,
                              items: ['Name', 'Category', 'Quantity', 'ID', 'Brand'],
                              onChanged: (v) => setState(() => _sortBy = v ?? 'Name'),
                            ),
                            IconButton(
                              icon: Icon(_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                              onPressed: () => setState(() => _sortAscending = !_sortAscending),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  equipProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: InventoryTab(
                                    items: paginatedItems,
                                    primaryColor: primaryColor,
                                    secondaryColor: secondaryColor,
                                    onBackgroundColor: onBackgroundColor,
                                    canManageInventory: canManageInventory,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Showing ${totalItems > 0 ? startIndex + 1 : 0} to $endIndex of $totalItems items',
                                    style: TextStyle(fontSize: 12.5, color: onBackgroundColor.withValues(alpha: 0.6)),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left_rounded),
                                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(border: Border.all(color: primaryColor.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          'Page $_currentPage of ${totalPages == 0 ? 1 : totalPages}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right_rounded),
                                        onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ],
              ),
              // Tab 2: Issue Logs
              equipProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(child: IssueEquipmentTab(list: equipProvider.issueLogs, primaryColor: primaryColor, isDark: isDark)),
              // Tab 3: Return Logs
              equipProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(child: ReturnsTab(list: equipProvider.returnLogs, primaryColor: primaryColor, isDark: isDark)),
              // Tab 4: Reports
              SingleChildScrollView(child: ReportsTab(list: equipProvider.equipmentList, issues: equipProvider.issueLogs, returns: equipProvider.returnLogs, primaryColor: primaryColor, secondaryColor: secondaryColor, isDark: isDark)),
            ],
          ),
        ),
      ],
    );
  }
}
