import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_constants.dart';
import '../models/property_model.dart';
import '../providers/property_provider.dart';
import '../theme/app_theme.dart';
import '../screens/property_detail_screen.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final propProv = context.watch<PropertyProvider>();
    final isFav = propProv.isFavorite(property.id);
    final imageUrl = ApiConstants.resolveImageUrl(property.primaryImageUrl);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(propertyId: property.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A0F172A),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Badges Stack
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.home_work_outlined, size: 48, color: AppTheme.textDim),
                      ),
                    ),
                  ),
                ),

                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Type Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.propertyType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Favorite Heart Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppTheme.accentRose : Colors.white,
                    ),
                    onPressed: () {
                      propProv.toggleFavorite(property.id);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                // Status Badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: property.status == 'PUBLISHED'
                          ? AppTheme.accentEmerald.withValues(alpha: 0.9)
                          : AppTheme.accentAmber.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      property.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.accentCyan),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Beds / Baths / Rooms
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.bed_outlined,
                        label: '${property.totalBedrooms > 0 ? property.totalBedrooms : 1} Beds',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.bathtub_outlined,
                        label: '${property.totalBathrooms > 0 ? property.totalBathrooms : 1} Baths',
                      ),
                      if (property.rooms.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.meeting_room_outlined,
                          label: '${property.availableRoomsCount}/${property.rooms.length} Avail',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppTheme.borderDark, height: 1),
                  const SizedBox(height: 12),
                  // Price and View button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MONTHLY RENT',
                            style: TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '\$${property.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppTheme.textMain,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                ' / mo',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PropertyDetailScreen(propertyId: property.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Row(
                          children: [
                            Text('View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
