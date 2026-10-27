import 'package:flutter/material.dart';
import '../models/rental_model.dart';
import '../models/extra_models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TenantPortalScreen extends StatefulWidget {
  const TenantPortalScreen({super.key});

  @override
  State<TenantPortalScreen> createState() => _TenantPortalScreenState();
}

class _TenantPortalScreenState extends State<TenantPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  List<ApplicationModel> _applications = [];
  List<ContractModel> _contracts = [];
  Map<int, List<PaymentModel>> _contractPayments = {};
  List<ViewingModel> _viewings = [];
  List<ComplaintModel> _complaints = [];

  bool _isLoading = true;

  // New Ticket
  final TextEditingController _ticketDescCtrl = TextEditingController();
  int? _ticketPropId;
  bool _isSubmittingTicket = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ticketDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final apps = await _api.getMyApplications();
      final contracts = await _api.getMyContracts();
      final viewings = await _api.getMyViewings();
      final complaints = await _api.getMyComplaints();

      Map<int, List<PaymentModel>> paymentsMap = {};
      for (var c in contracts) {
        try {
          final pList = await _api.getContractPayments(c.id);
          paymentsMap[c.id] = pList;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _applications = apps;
          _contracts = contracts;
          _contractPayments = paymentsMap;
          _viewings = viewings;
          _complaints = complaints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelApplication(int id) async {
    try {
      await _api.cancelApplication(id);
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cancelViewing(int id) async {
    try {
      await _api.cancelViewing(id);
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
        );
      }
    }
  }

  void _showPaymentDialog(int paymentId, int contractId) {
    String selectedMethod = 'ABA_PAY';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PayOption(
                    title: 'ABA PAY / KHQR',
                    icon: Icons.account_balance,
                    isSelected: selectedMethod == 'ABA_PAY',
                    onTap: () => setDialogState(() => selectedMethod = 'ABA_PAY'),
                  ),
                  const SizedBox(height: 8),
                  _PayOption(
                    title: 'Wing Bank',
                    icon: Icons.send_to_mobile,
                    isSelected: selectedMethod == 'WING',
                    onTap: () => setDialogState(() => selectedMethod = 'WING'),
                  ),
                  const SizedBox(height: 8),
                  _PayOption(
                    title: 'Direct Bank Transfer',
                    icon: Icons.account_balance_wallet,
                    isSelected: selectedMethod == 'BANK_TRANSFER',
                    onTap: () => setDialogState(() => selectedMethod = 'BANK_TRANSFER'),
                  ),
                  const SizedBox(height: 8),
                  _PayOption(
                    title: 'Credit / Debit Card',
                    icon: Icons.credit_card,
                    isSelected: selectedMethod == 'CARD',
                    onTap: () => setDialogState(() => selectedMethod = 'CARD'),
                  ),
                  const SizedBox(height: 8),
                  _PayOption(
                    title: 'Cash Payment',
                    icon: Icons.payments,
                    isSelected: selectedMethod == 'CASH',
                    onTap: () => setDialogState(() => selectedMethod = 'CASH'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await _api.payRental(paymentId, selectedMethod);
                      _loadAll();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.accentEmerald,
                            content: Text('Paid successfully via ${selectedMethod.replaceAll('_', ' ')}!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Payment failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Confirm Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitTicket() async {
    if (_ticketPropId == null || _ticketDescCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmittingTicket = true);
    try {
      await _api.submitComplaint(_ticketPropId!, _ticketDescCtrl.text.trim());
      _ticketDescCtrl.clear();
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppTheme.accentEmerald, content: Text('Maintenance ticket sent to landlord!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingTicket = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Portal'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textMuted,
          isScrollable: true,
          tabs: [
            Tab(text: 'Applications (${_applications.length})'),
            Tab(text: 'Contracts (${_contracts.length})'),
            Tab(text: 'Tours (${_viewings.length})'),
            Tab(text: 'Support & Tickets (${_complaints.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: APPLICATIONS
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _applications.isEmpty
                      ? _emptyView(Icons.assignment_outlined, 'No rental applications submitted yet')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _applications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final app = _applications[idx];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(14),
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
                                          app.propertyTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      _StatusPill(status: app.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (app.roomId != null)
                                    Text('Selected Unit: Room #${app.roomId}', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('Lease Period: ${app.startDate} to ${app.endDate}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                  if (app.status == 'PENDING') ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton(
                                        onPressed: () => _cancelApplication(app.id),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.accentRose,
                                          side: const BorderSide(color: AppTheme.accentRose),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        ),
                                        child: const Text('Cancel Request', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // TAB 2: CONTRACTS & PAYMENTS
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _contracts.isEmpty
                      ? _emptyView(Icons.description_outlined, 'No active rental contracts')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _contracts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, idx) {
                            final c = _contracts[idx];
                            final payments = _contractPayments[c.id] ?? [];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(14),
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
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                        ),
                                      ),
                                      _StatusPill(status: c.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Period: ${c.startDate} to ${c.endDate}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text('\$${c.rent.toStringAsFixed(0)}/mo Rent', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                      const SizedBox(width: 16),
                                      Text('Deposit: \$${c.deposit.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(color: AppTheme.borderDark),
                                  const SizedBox(height: 8),
                                  const Text('Invoices & Due Dates', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  if (payments.isEmpty)
                                    const Text('No pending payments', style: TextStyle(color: AppTheme.textDim, fontSize: 12))
                                  else
                                    Column(
                                      children: payments.map((p) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.03),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppTheme.borderDark),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('${p.type} • Due: ${p.dueDate}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                                                  _StatusPill(status: p.status),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text('\$${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
                                                  if (p.status == 'PENDING') ...[
                                                    const SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () => _showPaymentDialog(p.id, c.id),
                                                      style: ElevatedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        backgroundColor: AppTheme.primary,
                                                      ),
                                                      child: const Text('Pay', style: TextStyle(fontSize: 12)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // TAB 3: TOURS / VIEWINGS
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _viewings.isEmpty
                      ? _emptyView(Icons.calendar_today_outlined, 'No tours or viewings requested')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _viewings.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final v = _viewings[idx];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v.propertyTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_month, size: 14, color: AppTheme.primaryLight),
                                            const SizedBox(width: 4),
                                            Text(v.date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.access_time, size: 14, color: AppTheme.accentCyan),
                                            const SizedBox(width: 4),
                                            Text(v.time, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _StatusPill(status: v.status),
                                      if (v.status == 'PENDING') ...[
                                        const SizedBox(height: 6),
                                        TextButton(
                                          onPressed: () => _cancelViewing(v.id),
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                          child: const Text('Cancel', style: TextStyle(color: AppTheme.accentRose, fontSize: 12)),
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

                // TAB 4: TICKETS & COMPLAINTS
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File a Ticket Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Report Maintenance Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                              const SizedBox(height: 12),
                              if (_contracts.isEmpty)
                                const Text('You need an active lease to submit a maintenance ticket.', style: TextStyle(color: AppTheme.textDim, fontSize: 13))
                              else ...[
                                DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(labelText: 'Rental Property'),
                                  dropdownColor: AppTheme.surfaceDark,
                                  items: _contracts.map((c) {
                                    return DropdownMenuItem<int>(
                                      value: c.propertyId,
                                      child: Text(c.propertyTitle, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _ticketPropId = val),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _ticketDescCtrl,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Issue Description',
                                    hintText: 'e.g. Broken water heater, window repair needed...',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmittingTicket ? null : _submitTicket,
                                    child: _isSubmittingTicket
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Send Ticket to Landlord'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Ticket History
                        const Text('Ticket History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 10),
                        if (_complaints.isEmpty)
                          const Text('No issues reported.', style: TextStyle(color: AppTheme.textDim, fontSize: 13))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                                        Text(comp.propertyTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                        _StatusPill(status: comp.status),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(comp.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _emptyView(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 54, color: AppTheme.textDim.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppTheme.textDim, fontSize: 14)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c = AppTheme.textMuted;
    if (status == 'APPROVED' || status == 'ACTIVE' || status == 'PAID' || status == 'RESOLVED') {
      c = AppTheme.accentEmerald;
    } else if (status == 'PENDING' || status == 'PENDING_PAYMENT' || status == 'IN_PROGRESS') {
      c = AppTheme.accentAmber;
    } else if (status == 'REJECTED' || status == 'CANCELLED' || status == 'CLOSED') {
      c = AppTheme.accentRose;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PayOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderDark),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryLight : AppTheme.textDim, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
