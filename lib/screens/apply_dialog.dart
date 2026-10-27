import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ApplyDialog extends StatefulWidget {
  final PropertyModel property;
  final RoomModel? initialRoom;

  const ApplyDialog({super.key, required this.property, this.initialRoom});

  @override
  State<ApplyDialog> createState() => _ApplyDialogState();
}

class _ApplyDialogState extends State<ApplyDialog> {
  late int? _selectedRoomId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 3));
  DateTime _endDate = DateTime.now().add(const Duration(days: 180));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.initialRoom?.id ??
        (widget.property.rooms.isNotEmpty ? widget.property.rooms.first.id : null);
  }

  double get currentPrice {
    if (_selectedRoomId != null) {
      final r = widget.property.rooms.where((room) => room.id == _selectedRoomId).firstOrNull;
      if (r != null) return r.price;
    }
    return widget.property.price;
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit a rental application')),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      await ApiService().applyRental(
        propertyId: widget.property.id,
        roomId: _selectedRoomId,
        startDate: startStr,
        endDate: endStr,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.accentEmerald,
            content: Text('Rental application submitted to landlord!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_outlined, color: AppTheme.accentEmerald, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Apply for Rental', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pricing Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.property.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.property.address,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Text(
                    '\$${currentPrice.toStringAsFixed(0)}/mo',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.accentEmerald, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Room selector if rooms exist
            if (widget.property.rooms.isNotEmpty) ...[
              const Text('Select Room / Unit', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedRoomId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    items: widget.property.rooms.map((r) {
                      return DropdownMenuItem<int>(
                        value: r.id,
                        enabled: r.status == 'AVAILABLE',
                        child: Text(
                          'Room #${r.roomNumber} - \$${r.price.toStringAsFixed(0)}/mo (${r.status})',
                          style: TextStyle(
                            color: r.status == 'AVAILABLE' ? AppTheme.textMain : AppTheme.textDim,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoomId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Move-in Start Date
            const Text('Move-In Date', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) => Theme(data: Theme.of(context), child: child!),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM d, yyyy').format(_startDate), style: const TextStyle(color: AppTheme.textMain)),
                    const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lease End Date
            const Text('Lease End Date', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate.add(const Duration(days: 30)),
                  lastDate: _startDate.add(const Duration(days: 730)),
                  builder: (context, child) => Theme(data: Theme.of(context), child: child!),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM d, yyyy').format(_endDate), style: const TextStyle(color: AppTheme.textMain)),
                    const Icon(Icons.event_repeat, size: 16, color: AppTheme.accentCyan),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentEmerald),
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Application'),
        ),
      ],
    );
  }
}
