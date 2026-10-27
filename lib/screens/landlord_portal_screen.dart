import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../models/rental_model.dart';
import '../models/extra_models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../config/api_constants.dart';

class LandlordPortalScreen extends StatefulWidget {
  const LandlordPortalScreen({super.key});

  @override
  State<LandlordPortalScreen> createState() => _LandlordPortalScreenState();
}

class _LandlordPortalScreenState extends State<LandlordPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  List<PropertyModel> _properties = [];
  List<ApplicationModel> _applications = [];
  List<ViewingModel> _viewings = [];
  List<ComplaintModel> _complaints = [];
  List<AmenityModel> _allAmenities = [];

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
      final p = await _api.getMyProperties();
      final a = await _api.getIncomingApplications();
      final v = await _api.getIncomingViewings();
      final c = await _api.getIncomingComplaints();
      final am = await _api.getAmenities();

      if (mounted) {
        setState(() {
          _properties = p;
          _applications = a;
          _viewings = v;
          _complaints = c;
          _allAmenities = am;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Add Property Modal ---
  void _showAddPropertyDialog() {
    final titleCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String propType = 'APARTMENT';
    List<int> selectedAmenities = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add New Property', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Property Title')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: propType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      dropdownColor: AppTheme.surfaceDark,
                      items: ['APARTMENT', 'ROOM', 'STUDIO', 'CONDO', 'HOUSE', 'VILLA', 'SHOPHOUSE']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => propType = val ?? 'APARTMENT'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Base Rent Price (\$/mo)')),
                    const SizedBox(height: 10),
                    TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 14),
                    if (_allAmenities.isNotEmpty) ...[
                      const Align(alignment: Alignment.centerLeft, child: Text('Amenities:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _allAmenities.map((am) {
                          final isSelected = selectedAmenities.contains(am.id);
                          return FilterChip(
                            label: Text(am.name, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textMuted)),
                            selected: isSelected,
                            selectedColor: AppTheme.primary,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedAmenities.add(am.id);
                                } else {
                                  selectedAmenities.remove(am.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      await _api.createProperty(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        propertyType: propType,
                        address: addressCtrl.text.trim(),
                        price: double.tryParse(priceCtrl.text) ?? 200,
                        amenityIds: selectedAmenities,
                      );
                      _loadAll();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: AppTheme.accentEmerald, content: Text('Property created successfully!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Add Room Modal ---
  void _showAddRoomDialog(PropertyModel p) {
    final roomNoCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final bedsCtrl = TextEditingController(text: '1');
    final bathsCtrl = TextEditingController(text: '1');
    final sizeCtrl = TextEditingController(text: '25');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text('Add Room to ${p.title}', style: const TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: roomNoCtrl, decoration: const InputDecoration(labelText: 'Room Number / Code (e.g. 101, A2)')),
                const SizedBox(height: 10),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Rent (\$)')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: bedsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Beds'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: bathsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Baths'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: sizeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Size (m²)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (roomNoCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _api.addRoom(
                    p.id,
                    roomNumber: roomNoCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text) ?? 150,
                    bedrooms: int.tryParse(bedsCtrl.text) ?? 1,
                    bathrooms: int.tryParse(bathsCtrl.text) ?? 1,
                    size: double.tryParse(sizeCtrl.text) ?? 20,
                  );
                  _loadAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: AppTheme.accentEmerald, content: Text('Room added!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Add Room'),
            ),
          ],
        );
      },
    );
  }

  // --- Add Image URL Modal ---
  void _showAddImageDialog(PropertyModel p) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Add Photo by URL'),
          content: TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Image Web URL',
              hintText: 'https://images.unsplash.com/...',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (urlCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _api.addPropertyImageUrl(p.id, urlCtrl.text.trim());
                  _loadAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: AppTheme.accentEmerald, content: Text('Photo added!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Add Photo'),
            ),
          ],
        );
      },
    );
  }

  // --- Approve Application Modal ---
  void _showApproveAppDialog(ApplicationModel app) {
    final depositCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text('Approve for ${app.tenantName ?? "Tenant"}'),
          content: TextField(
            controller: depositCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Required Security Deposit (\$) - Optional',
              hintText: 'e.g. 250',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final dep = double.tryParse(depositCtrl.text) ?? 0.0;
                  await _api.approveApplication(app.id, dep);
                  _loadAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: AppTheme.accentEmerald, content: Text('Application approved and contract generated!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landlord Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded, color: AppTheme.accentEmerald),
            tooltip: 'Add Property',
            onPressed: _showAddPropertyDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textMuted,
          isScrollable: true,
          tabs: [
            Tab(text: 'Properties (${_properties.length})'),
            Tab(text: 'Applications (${_applications.length})'),
            Tab(text: 'Tours (${_viewings.length})'),
            Tab(text: 'Complaints (${_complaints.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: PROPERTIES
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _properties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.home_work_outlined, size: 54, color: AppTheme.textDim),
                              const SizedBox(height: 12),
                              const Text('No properties listed yet', style: TextStyle(color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('List Property'),
                                onPressed: _showAddPropertyDialog,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _properties.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, idx) {
                            final p = _properties[idx];
                            final imgUrl = ApiConstants.resolveImageUrl(p.primaryImageUrl);
                            final isPublished = p.status == 'PUBLISHED';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imgUrl,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.white12),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                            const SizedBox(height: 4),
                                            Text(p.address, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Text('\$${p.price.toStringAsFixed(0)}/mo • ${p.rooms.length} Rooms', style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(color: AppTheme.borderDark, height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                                        label: Text('Photo (${p.images.length})', style: const TextStyle(fontSize: 12)),
                                        onPressed: () => _showAddImageDialog(p),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.meeting_room_outlined, size: 16),
                                        label: Text('Rooms (${p.rooms.length})', style: const TextStyle(fontSize: 12)),
                                        onPressed: () => _showAddRoomDialog(p),
                                      ),
                                      OutlinedButton(
                                        onPressed: () async {
                                          try {
                                            if (isPublished) {
                                              await _api.unpublishProperty(p.id);
                                            } else {
                                              await _api.publishProperty(p.id);
                                            }
                                            _loadAll();
                                          } catch (e) {
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                        child: Text(isPublished ? 'Unpublish' : 'Publish', style: const TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // TAB 2: APPLICATIONS
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _applications.isEmpty
                      ? const Center(child: Text('No tenant applications pending', style: TextStyle(color: AppTheme.textDim)))
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
                                      Text(app.propertyTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                      Text(app.status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryLight)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Tenant: ${app.tenantName ?? "Tenant"}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                  Text('Duration: ${app.startDate} to ${app.endDate}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                  if (app.status == 'PENDING') ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () async {
                                            await _api.rejectApplication(app.id);
                                            _loadAll();
                                          },
                                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentRose),
                                          child: const Text('Reject'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _showApproveAppDialog(app),
                                          child: const Text('Approve'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // TAB 3: TOURS
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _viewings.isEmpty
                      ? const Center(child: Text('No viewing tour requests', style: TextStyle(color: AppTheme.textDim)))
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
                                        Text(v.propertyTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text('Tenant: ${v.tenantName ?? "Guest"}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                        Text('Date: ${v.date} at ${v.time}', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (v.status == 'PENDING')
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: AppTheme.accentEmerald),
                                          onPressed: () async {
                                            await _api.approveViewing(v.id);
                                            _loadAll();
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: AppTheme.accentRose),
                                          onPressed: () async {
                                            await _api.rejectViewing(v.id);
                                            _loadAll();
                                          },
                                        ),
                                      ],
                                    )
                                  else
                                    Text(v.status, style: const TextStyle(color: AppTheme.textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // TAB 4: COMPLAINTS
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: _complaints.isEmpty
                      ? const Center(child: Text('No complaints submitted by tenants', style: TextStyle(color: AppTheme.textDim)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _complaints.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final comp = _complaints[idx];
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
                                      Text(comp.propertyTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      DropdownButton<String>(
                                        value: comp.status,
                                        dropdownColor: AppTheme.surfaceDark,
                                        underline: const SizedBox(),
                                        items: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED']
                                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                                            .toList(),
                                        onChanged: (newStatus) async {
                                          if (newStatus != null) {
                                            await _api.updateComplaintStatus(comp.id, newStatus);
                                            _loadAll();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  Text('From: ${comp.tenantName ?? "Tenant"}', style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text(comp.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
