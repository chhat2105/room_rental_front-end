import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_constants.dart';
import '../providers/property_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'key': 'ALL', 'label': 'All Properties'},
    {'key': 'ROOM', 'label': 'Rooms'},
    {'key': 'STUDIO', 'label': 'Studios'},
    {'key': 'APARTMENT', 'label': 'Apartments'},
    {'key': 'CONDO', 'label': 'Condos'},
    {'key': 'HOUSE', 'label': 'Houses'},
    {'key': 'VILLA', 'label': 'Villas'},
    {'key': 'SHOPHOUSE', 'label': 'Shophouses'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showServerConfigDialog() {
    final propProv = context.read<PropertyProvider>();
    final ctrl = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Backend Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect to room_rental_back-end (Spring Boot):',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://localhost:1212',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Port 1212 (Default)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://localhost:1212',
                ),
                ActionChip(
                  label: const Text('LAN IP (10.10.1.64:1212)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://10.10.1.64:1212',
                ),
                ActionChip(
                  label: const Text('Android Emu (1212)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://10.0.2.2:1212',
                ),
                ActionChip(
                  label: const Text('Port 8080 (Docker)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://localhost:8080',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService().setCustomBaseUrl(null);
              if (ctx.mounted) Navigator.pop(ctx);
              propProv.init();
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService().setCustomBaseUrl(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              propProv.init();
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    final propProv = context.read<PropertyProvider>();
    double tempMaxPrice = propProv.maxPrice ?? 1500;
    int? tempBeds = propProv.bedrooms;
    bool? tempFurnished = propProv.furnished;
    List<int> tempAmenities = List<int>.from(propProv.selectedAmenityIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Properties',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          propProv.setFilters(
                            minPrice: null,
                            maxPrice: null,
                            bedrooms: null,
                            furnished: null,
                            amenityIds: [],
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: AppTheme.accentRose),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Max Monthly Rent',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      ),
                      Text(
                        '\$${tempMaxPrice.toInt()}/mo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: tempMaxPrice,
                    min: 50,
                    max: 3000,
                    divisions: 59,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.borderDark,
                    onChanged: (val) => setModalState(() => tempMaxPrice = val),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bedrooms',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [null, 1, 2, 3, 4].map((beds) {
                      final isSelected = tempBeds == beds;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(beds == null ? 'Any' : '$beds+'),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            setModalState(() => tempBeds = selected ? beds : null);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Furnished Only',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                    value: tempFurnished == true,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (val) =>
                        setModalState(() => tempFurnished = val ? true : null),
                  ),
                  if (propProv.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Must Have Amenities',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: propProv.amenities.map((am) {
                        final selected = tempAmenities.contains(am.id);
                        return FilterChip(
                          label: Text(am.name, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          selectedColor: AppTheme.primary,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                tempAmenities.add(am.id);
                              } else {
                                tempAmenities.remove(am.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        propProv.setFilters(
                          maxPrice: tempMaxPrice,
                          bedrooms: tempBeds,
                          furnished: tempFurnished,
                          amenityIds: tempAmenities,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propProv = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accentCyan],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'RentHub',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilterModal,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => propProv.loadProperties(),
        color: AppTheme.primary,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search location, area, or keywords...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryLight),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                            propProv.setSearchQuery('');
                            propProv.loadProperties();
                          },
                        )
                      : null,
                ),
                onSubmitted: (val) {
                  propProv.setSearchQuery(val.trim());
                  propProv.loadProperties();
                },
              ),
            ),

            // Horizontal Category Chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = propProv.selectedType == cat['key'];
                  return ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.borderDark,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => propProv.setSelectedType(cat['key']!),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Properties List
            Expanded(
              child: propProv.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : propProv.errorMessage != null && propProv.properties.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_off_rounded,
                                  size: 56,
                                  color: AppTheme.accentAmber,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Cannot reach room_rental_back-end',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Current URL: ${ApiConstants.baseUrl}',
                                  style: const TextStyle(
                                    color: AppTheme.accentCyan,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.settings_ethernet, size: 16),
                                      label: const Text('Change Port / IP'),
                                      onPressed: _showServerConfigDialog,
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Retry'),
                                      onPressed: () => propProv.init(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : propProv.properties.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: AppTheme.textDim.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No published properties found',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Try adjusting filters or list & verify a property',
                                    style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: propProv.properties.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, idx) {
                                return PropertyCard(property: propProv.properties[idx]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
