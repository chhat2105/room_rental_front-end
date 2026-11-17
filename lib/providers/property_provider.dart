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
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedType = 'ALL';
  double? _minPrice;
  double? _maxPrice;
  int? _bedrooms;
  bool? _furnished;
  List<int> _selectedAmenityIds = [];

  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get favorites => _favorites;
  List<AmenityModel> get amenities => _amenities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  int? get bedrooms => _bedrooms;
  bool? get furnished => _furnished;
  List<int> get selectedAmenityIds => _selectedAmenityIds;

  bool isFavorite(int propertyId) => _favoriteIds.contains(propertyId);

  Future<void> init() async {
    await _api.init();
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

  void setFilters({
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    bool? furnished,
    List<int>? amenityIds,
  }) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _bedrooms = bedrooms;
    _furnished = furnished;
    _selectedAmenityIds = amenityIds ?? [];
    loadProperties();
  }

  Future<void> loadProperties() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _properties = await _api.getProperties(
        q: _searchQuery.isEmpty ? null : _searchQuery,
        type: _selectedType,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        bedrooms: _bedrooms,
        furnished: _furnished,
        amenityIds: _selectedAmenityIds.isEmpty ? null : _selectedAmenityIds,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    if (_api.token == null) {
      _favorites = [];
      _favoriteIds = {};
      notifyListeners();
      return;
    }
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
