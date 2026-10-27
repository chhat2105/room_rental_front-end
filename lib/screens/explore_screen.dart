import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
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
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    final propProv = context.read<PropertyProvider>();
    double tempPrice = propProv.maxPrice ?? 1500;
    int? tempBeds = propProv.bedrooms;

    showModalBottomSheet(
      context: context,
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
                      const Text('Filter Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                      TextButton(
                        onPressed: () {
                          propProv.setFilters(maxPrice: null, bedrooms: null);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset', style: TextStyle(color: AppTheme.accentRose)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Monthly Rent', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                      Text('\$${tempPrice.toInt()}/mo', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    ],
                  ),
                  Slider(
                    value: tempPrice,
                    min: 50,
                    max: 3000,
                    divisions: 59,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.borderDark,
                    onChanged: (val) => setModalState(() => tempPrice = val),
                  ),
                  const SizedBox(height: 16),
                  const Text('Bedrooms', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
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
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            setModalState(() => tempBeds = selected ? beds : null);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        propProv.setFilters(maxPrice: tempPrice, bedrooms: tempBeds);
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
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accentCyan]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('RentHub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
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
                decoration: InputDecoration(
                  hintText: 'Search location, area, or keywords...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryLight),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
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
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.borderDark,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMain,
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
                  : propProv.properties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textDim.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text('No properties match your search', style: TextStyle(color: AppTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Try adjusting filters or searching for different areas', style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
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
