import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property_model.dart';
import '../models/rental_model.dart';
import '../models/extra_models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../config/api_constants.dart';
import 'messages_screen.dart';
import 'property_detail_screen.dart';

class LandlordPortalScreen extends StatefulWidget {
  const LandlordPortalScreen({super.key});

  @override
  State<LandlordPortalScreen> createState() => _LandlordPortalScreenState();
}

class _LandlordPortalScreenState extends State<LandlordPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  LandlordDashboardModel? _dashboard;
  List<PropertyModel> _properties = [];
  List<ApplicationModel> _applications = [];
  List<ContractModel> _contracts = [];
  List<PaymentModel> _payments = [];
  List<ViewingModel> _viewings = [];
  List<ComplaintModel> _complaints = [];
  List<AmenityModel> _allAmenities = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      final results = await Future.wait([
        _api.getMyProperties(),
        _api.getIncomingApplications(),
        _api.getLandlordContracts(),
        _api.getLandlordPayments(),
        _api.getIncomingViewings(),
        _api.getIncomingComplaints(),
        _api.getAmenities(),
      ]);

      LandlordDashboardModel? dash;
      try {
        dash = await _api.getLandlordDashboard();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _properties = results[0] as List<PropertyModel>;
          _applications = results[1] as List<ApplicationModel>;
          _contracts = results[2] as List<ContractModel>;
          _payments = results[3] as List<PaymentModel>;
          _viewings = results[4] as List<ViewingModel>;
          _complaints = results[5] as List<ComplaintModel>;
          _allAmenities = results[6] as List<AmenityModel>;
          _dashboard = dash;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Add / Edit Property Modal ---
  void _showPropertyDialog({PropertyModel? existing}) {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    XFile? pickedImage;
    final newAmenityCtrl = TextEditingController();
    String propType = existing?.propertyType ?? 'APARTMENT';
    bool furnished = existing?.furnished ?? false;
    List<int> selectedAmenities =
        existing != null ? existing.amenities.map((a) => a.id).toList() : [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Edit Property' : 'Add New Property',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Property Title'),
                    ),
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
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Base Rent Price (\$/mo)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    if (!isEdit) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: Text(
                          pickedImage == null
                              ? 'Choose cover photo (optional)'
                              : 'Selected: ${pickedImage!.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          final f = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (f != null) setDialogState(() => pickedImage = f);
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Furnished', style: TextStyle(fontSize: 14)),
                      value: furnished,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (val) => setDialogState(() => furnished = val),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amenities:',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('New Amenity', style: TextStyle(fontSize: 11)),
                          onPressed: () async {
                            final name = await showDialog<String>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppTheme.surfaceDark,
                                title: const Text('Create Amenity', style: TextStyle(fontSize: 16)),
                                content: TextField(
                                  controller: newAmenityCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Amenity Name (e.g. Wi-Fi, Pool)',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(c, newAmenityCtrl.text.trim()),
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            );
                            if (name != null && name.isNotEmpty) {
                              try {
                                final created = await _api.createAmenity(name);
                                newAmenityCtrl.clear();
                                setDialogState(() {
                                  _allAmenities.add(created);
                                  selectedAmenities.add(created.id);
                                });
                              } catch (_) {}
                            }
                          },
                        ),
                      ],
                    ),
                    if (_allAmenities.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _allAmenities.map((am) {
                          final isSelected = selectedAmenities.contains(am.id);
                          return FilterChip(
                            label: Text(
                              am.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      if (isEdit) {
                        await _api.updateProperty(
                          existing.id,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          propertyType: propType,
                          address: addressCtrl.text.trim(),
                          price: double.tryParse(priceCtrl.text) ?? existing.price,
                          furnished: furnished,
                          amenityIds: selectedAmenities,
                        );
                      } else {
                        final created = await _api.createProperty(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          propertyType: propType,
                          address: addressCtrl.text.trim(),
                          price: double.tryParse(priceCtrl.text) ?? 200,
                          furnished: furnished,
                          amenityIds: selectedAmenities,
                        );
                        if (pickedImage != null) {
                          await _api.addPropertyImageFile(
                            created.id,
                            await pickedImage!.readAsBytes(),
                            pickedImage!.name,
                          );
                        }
                      }
                      _loadAll();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.accentEmerald,
                            content: Text(
                              isEdit
                                  ? 'Property updated!'
                                  : 'Property created successfully!',
                            ),
                          ),
                        );
                      }
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
                  child: Text(isEdit ? 'Save Changes' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Manage Rooms Modal ---
  void _showManageRoomsDialog(PropertyModel p) {
    final roomNoCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: p.price.toStringAsFixed(0));
    final bedsCtrl = TextEditingController(text: '1');
    final bathsCtrl = TextEditingController(text: '1');
    final sizeCtrl = TextEditingController(text: '25');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text('Rooms in ${p.title}', style: const TextStyle(fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.rooms.isNotEmpty) ...[
                    const Text(
                      'Existing Rooms',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...p.rooms.map(
                      (r) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Room #${r.roomNumber} • \$${r.price.toStringAsFixed(0)} (${r.status})',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            if (r.status == 'AVAILABLE')
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.accentRose,
                                  size: 18,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  try {
                                    await _api.deleteRoom(r.id);
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
                      ),
                    ),
                    const Divider(color: AppTheme.borderDark, height: 20),
                  ],
                  const Text(
                    'Add New Room',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: roomNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Room Number / Code (e.g. 101, A2)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monthly Rent (\$)'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bedsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Beds'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: bathsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Baths'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sizeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Size (m²)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
                      const SnackBar(
                        backgroundColor: AppTheme.accentEmerald,
                        content: Text('Room added!'),
                      ),
                    );
                  }
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
              child: const Text('Add Room'),
            ),
          ],
        );
      },
    );
  }

  // --- Manage Photos Modal ---
  void _showManagePhotosDialog(PropertyModel p) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text('Photos for ${p.title}', style: const TextStyle(fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.images.isNotEmpty) ...[
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: p.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final img = p.images[idx];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ApiConstants.resolveImageUrl(img.url),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(width: 80, height: 80, color: Colors.white12),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await _api.removePropertyImage(p.id, img.id);
                                      _loadAll();
                                    } catch (_) {}
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: AppTheme.accentRose,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Choose image file'),
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (picked == null) return;
                        final bytes = await picked.readAsBytes();
                        if (ctx.mounted) Navigator.pop(ctx);
                        try {
                          await _api.addPropertyImageFile(p.id, bytes, picked.name);
                          _loadAll();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppTheme.accentEmerald,
                                content: Text('Photo uploaded!'),
                              ),
                            );
                          }
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
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
              labelText: 'Security Deposit (\$) - Leave blank for 1 month rent',
              hintText: 'e.g. 250',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final dep = double.tryParse(depositCtrl.text.trim());
                  await _api.approveApplication(app.id, dep);
                  _loadAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTheme.accentEmerald,
                        content: Text('Application approved and contract generated!'),
                      ),
                    );
                  }
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.add_business_rounded, color: AppTheme.accentEmerald),
            tooltip: 'Add Property',
            onPressed: () => _showPropertyDialog(),
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
            Tab(text: 'Contracts (${_contracts.length})'),
            Tab(text: 'Tours (${_viewings.length})'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceDark,
                      border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _DashStat(
                            'Revenue (Mo)',
                            '\$${_dashboard!.revenueThisMonth.toStringAsFixed(0)}',
                            AppTheme.accentEmerald,
                          ),
                          const SizedBox(width: 18),
                          _DashStat(
                            'Published',
                            '${_dashboard!.publishedProperties}/${_dashboard!.totalProperties}',
                            AppTheme.primaryLight,
                          ),
                          const SizedBox(width: 18),
                          _DashStat(
                            'Active Leases',
                            '${_dashboard!.activeContracts}',
                            AppTheme.accentCyan,
                          ),
                          const SizedBox(width: 18),
                          _DashStat(
                            'Pending Apps',
                            '${_dashboard!.pendingApplications}',
                            AppTheme.accentAmber,
                          ),
                          const SizedBox(width: 18),
                          _DashStat(
                            'Overdue',
                            '${_dashboard!.overduePayments}',
                            AppTheme.accentRose,
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
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
                                    const Icon(
                                      Icons.home_work_outlined,
                                      size: 54,
                                      color: AppTheme.textDim,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No properties listed yet',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text('List Property'),
                                      onPressed: () => _showPropertyDialog(),
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
                                  final canUnpublish =
                                      p.status == 'PUBLISHED' || p.status == 'PENDING_REVIEW';

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
                                              builder: (_) =>
                                                  PropertyDetailScreen(propertyId: p.id),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: Image.network(
                                                  imgUrl,
                                                  width: 72,
                                                  height: 72,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    width: 72,
                                                    height: 72,
                                                    color: Colors.white12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            p.title,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 15,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: p.status == 'PUBLISHED'
                                                                ? AppTheme.accentEmerald
                                                                    .withValues(alpha: 0.2)
                                                                : AppTheme.accentAmber
                                                                    .withValues(alpha: 0.2),
                                                            borderRadius:
                                                                BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            p.status,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: p.status == 'PUBLISHED'
                                                                  ? AppTheme.accentEmerald
                                                                  : AppTheme.accentAmber,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      p.address,
                                                      style: const TextStyle(
                                                        color: AppTheme.textMuted,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '\$${p.price.toStringAsFixed(0)}/mo • ${p.rooms.length} Rooms${p.furnished ? " • Furnished" : ""}',
                                                      style: const TextStyle(
                                                        color: AppTheme.primaryLight,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (p.rejectionReason != null &&
                                            p.rejectionReason!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Admin Note: ${p.rejectionReason}',
                                            style: const TextStyle(
                                              color: AppTheme.accentRose,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        const Divider(color: AppTheme.borderDark, height: 1),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(
                                                Icons.add_photo_alternate_outlined,
                                                size: 16,
                                              ),
                                              label: Text(
                                                'Photos (${p.images.length})',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              onPressed: () => _showManagePhotosDialog(p),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(
                                                Icons.meeting_room_outlined,
                                                size: 16,
                                              ),
                                              label: Text(
                                                'Rooms (${p.rooms.length})',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              onPressed: () => _showManageRoomsDialog(p),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                                color: AppTheme.textMuted,
                                              ),
                                              tooltip: 'Edit Property',
                                              onPressed: () => _showPropertyDialog(existing: p),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: AppTheme.accentRose,
                                              ),
                                              tooltip: 'Delete Property',
                                              onPressed: () async {
                                                try {
                                                  await _api.deleteProperty(p.id);
                                                  _loadAll();
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                            OutlinedButton(
                                              onPressed: () async {
                                                try {
                                                  if (canUnpublish) {
                                                    await _api.unpublishProperty(p.id);
                                                  } else {
                                                    await _api.publishProperty(p.id);
                                                  }
                                                  _loadAll();
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        backgroundColor: AppTheme.accentRose,
                                                        content: Text(
                                                          e.toString().replaceAll('Exception: ', ''),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                              ),
                                              child: Text(
                                                canUnpublish ? 'Unpublish' : 'Publish',
                                                style: const TextStyle(fontSize: 12),
                                              ),
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
                            ? const Center(
                                child: Text(
                                  'No tenant applications pending',
                                  style: TextStyle(color: AppTheme.textDim),
                                ),
                              )
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
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              app.status,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppTheme.primaryLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tenant: ${app.tenantName ?? "Tenant"}${app.roomId != null ? " • Room #${app.roomId}" : ""}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Duration: ${app.startDate} to ${app.endDate}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (app.tenantId != null)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.chat_bubble_outline,
                                                  size: 18,
                                                  color: AppTheme.accentCyan,
                                                ),
                                                tooltip: 'Message Tenant',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ChatScreen(
                                                        otherUserId: app.tenantId!,
                                                        otherUserName:
                                                            app.tenantName ?? 'Tenant',
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            if (app.status == 'PENDING') ...[
                                              OutlinedButton(
                                                onPressed: () async {
                                                  await _api.rejectApplication(app.id);
                                                  _loadAll();
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppTheme.accentRose,
                                                ),
                                                child: const Text('Reject'),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () => _showApproveAppDialog(app),
                                                child: const Text('Approve'),
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

                      // TAB 3: CONTRACTS & PAYMENTS
                      RefreshIndicator(
                        onRefresh: _loadAll,
                        child: _contracts.isEmpty
                            ? const Center(
                                child: Text(
                                  'No rental contracts yet',
                                  style: TextStyle(color: AppTheme.textDim),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _contracts.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final c = _contracts[idx];
                                  final contractPayments = _payments
                                      .where((p) => p.contractId == c.id)
                                      .toList();
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
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              c.status,
                                              style: const TextStyle(
                                                color: AppTheme.accentEmerald,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tenant: ${c.tenantName}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Lease: ${c.startDate} to ${c.endDate} • \$${c.rent.toStringAsFixed(0)}/mo',
                                          style: const TextStyle(
                                            color: AppTheme.textDim,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (contractPayments.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            'Payments: ${contractPayments.where((p) => p.status == "PAID").length}/${contractPayments.length} Paid',
                                            style: const TextStyle(
                                              color: AppTheme.accentCyan,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        if (c.status == 'ACTIVE' ||
                                            c.status == 'PENDING_PAYMENT') ...[
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.accentRose,
                                                side: const BorderSide(
                                                  color: AppTheme.accentRose,
                                                ),
                                              ),
                                              onPressed: () async {
                                                await _api.endContract(c.id);
                                                _loadAll();
                                              },
                                              child: const Text(
                                                'End Contract',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // TAB 4: TOURS
                      RefreshIndicator(
                        onRefresh: _loadAll,
                        child: _viewings.isEmpty
                            ? const Center(
                                child: Text(
                                  'No viewing tour requests',
                                  style: TextStyle(color: AppTheme.textDim),
                                ),
                              )
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
                                              Text(
                                                v.propertyTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Tenant: ${v.tenantName ?? "Guest"}',
                                                style: const TextStyle(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'Date: ${v.date} at ${v.time}',
                                                style: const TextStyle(
                                                  color: AppTheme.accentCyan,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (v.status == 'PENDING')
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check_circle,
                                                  color: AppTheme.accentEmerald,
                                                ),
                                                onPressed: () async {
                                                  await _api.approveViewing(v.id);
                                                  _loadAll();
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.cancel,
                                                  color: AppTheme.accentRose,
                                                ),
                                                onPressed: () async {
                                                  await _api.rejectViewing(v.id);
                                                  _loadAll();
                                                },
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            v.status,
                                            style: const TextStyle(
                                              color: AppTheme.textDim,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // TAB 5: COMPLAINTS
                      RefreshIndicator(
                        onRefresh: _loadAll,
                        child: _complaints.isEmpty
                            ? const Center(
                                child: Text(
                                  'No complaints submitted by tenants',
                                  style: TextStyle(color: AppTheme.textDim),
                                ),
                              )
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
                                            Expanded(
                                              child: Text(
                                                comp.propertyTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            DropdownButton<String>(
                                              value: comp.status,
                                              dropdownColor: AppTheme.surfaceDark,
                                              underline: const SizedBox(),
                                              items: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED']
                                                  .map(
                                                    (s) => DropdownMenuItem(
                                                      value: s,
                                                      child: Text(
                                                        s,
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (newStatus) async {
                                                if (newStatus != null) {
                                                  await _api.updateComplaintStatus(
                                                    comp.id,
                                                    newStatus,
                                                  );
                                                  _loadAll();
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'From: ${comp.tenantName ?? "Tenant"}',
                                          style: const TextStyle(
                                            color: AppTheme.textDim,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          comp.description,
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
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

class _DashStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DashStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
        ),
      ],
    );
  }
}
