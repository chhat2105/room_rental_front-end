import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';

class PropertyProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<PropertyModel> _properties = [];
  List<PropertyModel> _favorites = [];
  List<AmenityModel> _amenities = [];
  Set<int> _favoriteIds = {};

  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedType = 'ALL';
  double? _maxPrice;
  int? _bedrooms;

  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get favorites => _favorites;
  List<AmenityModel> get amenities => _amenities;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  double? get maxPrice => _maxPrice;
  int? get bedrooms => _bedrooms;

  bool isFavorite(int propertyId) => _favoriteIds.contains(propertyId);

  Future<void> init() async {
    await Future.wait([
      loadProperties(),
      loadAmenities(),
      loadFavorites(),
    ]);
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
  }

  void setSelectedType(String type) {
    _selectedType = type;
    loadProperties();
  }

  void setFilters({double? maxPrice, int? bedrooms}) {
    _maxPrice = maxPrice;
    _bedrooms = bedrooms;
    loadProperties();
  }

  Future<void> loadProperties() async {
    _isLoading = true;
    notifyListeners();
    try {
      _properties = await _api.getProperties(
        q: _searchQuery.isEmpty ? null : _searchQuery,
        type: _selectedType,
        maxPrice: _maxPrice,
        bedrooms: _bedrooms,
      );
    } catch (e) {
      debugPrint('Error loading properties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAmenities() async {
    try {
      _amenities = await _api.getAmenities();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading amenities: $e');
    }
  }

  Future<void> loadFavorites() async {
    if (_api.token == null) return;
    try {
      _favorites = await _api.getFavorites();
      _favoriteIds = _favorites.map((f) => f.id).toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite(int propertyId) async {
    final currentlyFav = _favoriteIds.contains(propertyId);
    if (currentlyFav) {
      _favoriteIds.remove(propertyId);
      _favorites.removeWhere((p) => p.id == propertyId);
      notifyListeners();
      try {
        await _api.removeFavorite(propertyId);
      } catch (_) {
        _favoriteIds.add(propertyId);
        notifyListeners();
      }
    } else {
      _favoriteIds.add(propertyId);
      notifyListeners();
      try {
        await _api.addFavorite(propertyId);
        await loadFavorites();
      } catch (_) {
        _favoriteIds.remove(propertyId);
        notifyListeners();
      }
    }
  }
}
