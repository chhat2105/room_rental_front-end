import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_constants.dart';
import '../models/property_model.dart';
import '../models/extra_models.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'booking_dialog.dart';
import 'apply_dialog.dart';

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  PropertyModel? _property;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  int _activeImageIndex = 0;

  // Review submission
  int _newRating = 5;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final p = await ApiService().getProperty(widget.propertyId);
      final r = await ApiService().getPropertyReviews(widget.propertyId);
      if (mounted) {
        setState(() {
          _property = p;
          _reviews = r;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load property: $e')),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmittingReview = true);
    try {
      await ApiService().addReview(
        propertyId: widget.propertyId,
        rating: _newRating,
        comment: _commentCtrl.text.trim(),
      );
      _commentCtrl.clear();
      final r = await ApiService().getPropertyReviews(widget.propertyId);
      if (mounted) {
        setState(() => _reviews = r);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppTheme.accentEmerald, content: Text('Review posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property Details')),
        body: const Center(child: Text('Property not found or unavailable')),
      );
    }

    final p = _property!;
    final propProv = context.watch<PropertyProvider>();
    final isFav = propProv.isFavorite(p.id);
    final auth = context.watch<AuthProvider>();

    final images = p.images.isNotEmpty
        ? p.images.map((img) => ApiConstants.resolveImageUrl(img.url)).toList()
        : [ApiConstants.resolveImageUrl(null)];

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Sliver AppBar with Image Slider
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                        itemBuilder: (context, idx) {
                          return Image.network(
                            images[idx],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.surfaceDark,
                              child: const Icon(Icons.home_work_outlined, size: 64, color: AppTheme.textDim),
                            ),
                          );
                        },
                      ),
                      // Dot Indicators
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (idx) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _activeImageIndex == idx ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _activeImageIndex == idx ? AppTheme.primaryLight : Colors.white54,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppTheme.accentRose : Colors.white),
                    onPressed: () => propProv.toggleFavorite(p.id),
                  ),
                ],
              ),

              // Property Details Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type and Status pills
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              p.propertyType,
                              style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.status == 'PUBLISHED'
                                  ? AppTheme.accentEmerald.withValues(alpha: 0.2)
                                  : AppTheme.accentAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.status,
                              style: TextStyle(
                                color: p.status == 'PUBLISHED' ? AppTheme.accentEmerald : AppTheme.accentAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        p.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.25),
                      ),
                      const SizedBox(height: 8),

                      // Address
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppTheme.accentCyan),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.address,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Quick Stats Row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _QuickStat(icon: Icons.bed_outlined, title: '${p.totalBedrooms > 0 ? p.totalBedrooms : 1}', subtitle: 'Beds'),
                            _QuickStat(icon: Icons.bathtub_outlined, title: '${p.totalBathrooms > 0 ? p.totalBathrooms : 1}', subtitle: 'Baths'),
                            _QuickStat(icon: Icons.door_front_door_outlined, title: '${p.rooms.length}', subtitle: 'Rooms'),
                            _QuickStat(icon: Icons.verified_user_outlined, title: 'Verified', subtitle: 'Host'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Managed by Landlord Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Text(
                                p.landlordName?.isNotEmpty == true ? p.landlordName![0].toUpperCase() : 'L',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hosted by ${p.landlordName ?? "Verified Landlord"}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  ),
                                  const Text(
                                    'Professional Rental Manager • Quick Response',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      const Text('About Property', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        p.description?.isNotEmpty == true
                            ? p.description!
                            : 'Modern living space featuring contemporary finishes, abundant natural light, and convenient proximity to transport and amenities.',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.6),
                      ),
                      const SizedBox(height: 24),

                      // Amenities
                      if (p.amenities.isNotEmpty) ...[
                        const Text('Amenities & Perks', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.amenities.map((am) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 15, color: AppTheme.accentEmerald),
                                  const SizedBox(width: 6),
                                  Text(am.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Rooms Breakdown
                      if (p.rooms.isNotEmpty) ...[
                        Text('Available Units inside Property (${p.rooms.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: p.rooms.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final room = p.rooms[idx];
                            final isAvail = room.status == 'AVAILABLE';
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
                                        Row(
                                          children: [
                                            Text('Room #${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isAvail ? AppTheme.accentEmerald.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                room.status,
                                                style: TextStyle(color: isAvail ? AppTheme.accentEmerald : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${room.bedrooms} Bed • ${room.bathrooms} Bath ${room.size > 0 ? "• ${room.size}m²" : ""}',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${room.price.toStringAsFixed(0)} / month',
                                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isAvail)
                                    ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => ApplyDialog(property: p, initialRoom: room),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        backgroundColor: AppTheme.primary,
                                      ),
                                      child: const Text('Rent Room', style: TextStyle(fontSize: 12)),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Reviews & Ratings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tenant Reviews (${_reviews.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppTheme.accentAmber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                _reviews.isNotEmpty
                                    ? (_reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length).toStringAsFixed(1)
                                    : '5.0',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_reviews.isEmpty)
                        const Text('No reviews yet. Be the first to review!', style: TextStyle(color: AppTheme.textDim, fontSize: 13))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final rev = _reviews[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(rev.tenantName ?? 'Tenant', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (s) => Icon(
                                            Icons.star,
                                            size: 14,
                                            color: s < rev.rating ? AppTheme.accentAmber : Colors.white24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (rev.comment != null && rev.comment!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(rev.comment!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),

                      // Add review if authenticated tenant
                      if (auth.isAuthenticated && auth.isTenant) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (idx) {
                                  final starVal = idx + 1;
                                  return IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(Icons.star, color: starVal <= _newRating ? AppTheme.accentAmber : Colors.white24, size: 22),
                                    onPressed: () => setState(() => _newRating = starVal),
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _commentCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Share your feedback about the property...',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _isSubmittingReview ? null : _submitReview,
                                  child: _isSubmittingReview
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Post Review'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.95),
                border: const Border(top: BorderSide(color: AppTheme.borderDark)),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL RENT', style: TextStyle(color: AppTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('\$${p.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          const Text(' / mo', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Tour'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => BookingDialog(property: p),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Apply Now'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ApplyDialog(property: p),
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
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _QuickStat({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 22),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        Text(subtitle, style: const TextStyle(color: AppTheme.textDim, fontSize: 11)),
      ],
    );
  }
}
