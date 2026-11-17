import 'package:flutter/material.dart';
import '../config/api_constants.dart';
import '../models/extra_models.dart';
import '../models/property_model.dart';
import '../models/rental_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'property_detail_screen.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  AdminDashboardModel? _dashboard;
  List<PropertyModel> _properties = [];
  String _propertyFilterStatus = 'PENDING_REVIEW';
  List<AdminUserModel> _users = [];
  List<ContractModel> _rentals = [];
  List<PaymentModel> _overduePayments = [];
  List<ComplaintModel> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final dash = await _api.getAdminDashboard();
      final props = await _api.getAdminProperties(status: _propertyFilterStatus);
      final users = await _api.getAdminUsers();
      final rentals = await _api.getAdminRentals();
      final overdue = await _api.getAdminOverduePayments();
      final complaints = await _api.getAdminComplaints();

      if (mounted) {
        setState(() {
          _dashboard = dash;
          _properties = props;
          _users = users;
          _rentals = rentals;
          _overduePayments = overdue;
          _complaints = complaints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectOrTakeDownDialog(PropertyModel p, {required bool isTakeDown}) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(isTakeDown ? 'Take Down Listing' : 'Reject Listing'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Explain why this listing is rejected or taken down...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                if (isTakeDown) {
                  await _api.takeDownProperty(p.id, reasonCtrl.text.trim());
                } else {
                  await _api.rejectProperty(p.id, reasonCtrl.text.trim());
                }
                _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isTakeDown ? 'Take Down' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _showResolveComplaintDialog(ComplaintModel comp) {
    String selectedStatus = comp.status;
    final resCtrl = TextEditingController(text: comp.resolution ?? '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text('Resolve Complaint #${comp.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                dropdownColor: AppTheme.surfaceDark,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val ?? 'RESOLVED'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Resolution Note',
                  hintText: 'Enter resolution details...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.resolveAdminComplaint(
                    comp.id,
                    status: selectedStatus,
                    resolution: resCtrl.text.trim(),
                  );
                  _loadAll();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textMuted,
          isScrollable: true,
          tabs: [
            Tab(text: 'Listings (${_properties.length})'),
            Tab(text: 'Users (${_users.length})'),
            Tab(text: 'Rentals (${_rentals.length})'),
            Tab(text: 'Complaints (${_complaints.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                if (_dashboard != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceDark,
                      border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        _KpiItem('Users', '${_dashboard!.totalUsers}', AppTheme.primaryLight),
                        _KpiItem('Pending Review', '${_dashboard!.pendingListings}', AppTheme.accentAmber),
                        _KpiItem('Published', '${_dashboard!.publishedListings}', AppTheme.accentEmerald),
                        _KpiItem('Active Leases', '${_dashboard!.activeRentals}', AppTheme.accentCyan),
                        _KpiItem('Overdue', '${_dashboard!.overduePayments}', AppTheme.accentRose),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: VERIFY / MODERATE LISTINGS
                      Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              children: ['PENDING_REVIEW', 'PUBLISHED', 'DRAFT', 'REJECTED', 'UNPUBLISHED']
                                  .map((st) {
                                final selected = _propertyFilterStatus == st;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(st),
                                    selected: selected,
                                    selectedColor: AppTheme.primary,
                                    onSelected: (_) {
                                      setState(() => _propertyFilterStatus = st);
                                      _loadAll();
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadAll,
                              child: _properties.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No properties with status $_propertyFilterStatus',
                                        style: const TextStyle(color: AppTheme.textDim),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _properties.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, idx) {
                                        final p = _properties[idx];
                                        final imgUrl = ApiConstants.resolveImageUrl(p.primaryImageUrl);
                                        return Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceDark,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppTheme.borderDark),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              InkWell(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => PropertyDetailScreen(propertyId: p.id),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        imgUrl,
                                                        width: 64,
                                                        height: 64,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => Container(
                                                          width: 64,
                                                          height: 64,
                                                          color: Colors.white12,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            p.title,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Host: ${p.landlordName ?? "Landlord"} • \$${p.price.toStringAsFixed(0)}/mo',
                                                            style: const TextStyle(
                                                              color: AppTheme.textMuted,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          Text(
                                                            p.address,
                                                            style: const TextStyle(
                                                              color: AppTheme.textDim,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  if (p.status == 'PENDING_REVIEW') ...[
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          _showRejectOrTakeDownDialog(p, isTakeDown: false),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: AppTheme.accentRose,
                                                        side: const BorderSide(color: AppTheme.accentRose),
                                                      ),
                                                      child: const Text('Reject'),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton.icon(
                                                      icon: const Icon(Icons.verified, size: 16),
                                                      label: const Text('Verify & Publish'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppTheme.accentEmerald,
                                                      ),
                                                      onPressed: () async {
                                                        await _api.verifyProperty(p.id);
                                                        _loadAll();
                                                      },
                                                    ),
                                                  ] else if (p.status == 'PUBLISHED') ...[
                                                    OutlinedButton.icon(
                                                      icon: const Icon(Icons.block, size: 16),
                                                      label: const Text('Take Down'),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: AppTheme.accentRose,
                                                        side: const BorderSide(color: AppTheme.accentRose),
                                                      ),
                                                      onPressed: () =>
                                                          _showRejectOrTakeDownDialog(p, isTakeDown: true),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // TAB 2: USERS
                      RefreshIndicator(
                        onRefresh: _loadAll,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final u = _users[idx];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${u.email} • ${u.phone ?? "No phone"}',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: u.enabled,
                                    activeThumbColor: AppTheme.accentEmerald,
                                    onChanged: (val) async {
                                      try {
                                        await _api.setAdminUserEnabled(u.id, val);
                                        _loadAll();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: AppTheme.accentRose,
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // TAB 3: RENTALS & OVERDUE
                      RefreshIndicator(
                        onRefresh: _loadAll,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_overduePayments.isNotEmpty) ...[
                              const Text(
                                'Overdue Payments',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentRose,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._overduePayments.map(
                                (p) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentRose.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Contract #${p.contractId} • ${p.type} (Due ${p.dueDate})',
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                      Text(
                                        '\$${p.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.accentRose,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            const Text(
                              'All Rental Contracts',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            if (_rentals.isEmpty)
                              const Text('No contracts found', style: TextStyle(color: AppTheme.textDim))
                            else
                              ..._rentals.map(
                                (c) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.borderDark),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.propertyTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            c.status,
                                            style: const TextStyle(
                                              color: AppTheme.accentCyan,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tenant: ${c.tenantName} • \$${c.rent.toStringAsFixed(0)}/mo',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                      Text(
                                        '${c.startDate} → ${c.endDate}',
                                        style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // TAB 4: COMPLAINTS
                      RefreshIndicator(
                        onRefresh: _loadAll,
                        child: _complaints.isEmpty
                            ? const Center(
                                child: Text('No complaints submitted', style: TextStyle(color: AppTheme.textDim)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _complaints.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final comp = _complaints[idx];
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceDark,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.borderDark),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                comp.propertyTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(Icons.edit_note, size: 16),
                                              label: Text(comp.status),
                                              onPressed: () => _showResolveComplaintDialog(comp),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Tenant: ${comp.tenantName ?? "Tenant"}',
                                          style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comp.description,
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                        ),
                                        if (comp.resolution != null && comp.resolution!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Resolution: ${comp.resolution}',
                                            style: const TextStyle(
                                              color: AppTheme.accentEmerald,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
        ),
      ],
    );
  }
}
