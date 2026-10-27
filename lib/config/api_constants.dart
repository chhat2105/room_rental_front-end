import 'package:flutter/foundation.dart';

class ApiConstants {
  // If running on Android emulator, localhost is 10.0.2.2.
  // On Web, Windows desktop, iOS, or real device, it connects to localhost or LAN IP.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:1212';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:1212';
    }
    return 'http://localhost:1212';
  }

  // Auth endpoints
  static const String login = '/api/auth/token';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String refresh = '/api/auth/refresh';

  // Properties endpoints
  static const String properties = '/api/properties';
  static const String amenities = '/api/amenities';

  // Landlord endpoints
  static const String landlordProperties = '/api/landlord/properties';

  // Viewing endpoints
  static const String viewings = '/api/viewings';
  static const String myViewings = '/api/viewings/my';
  static const String incomingViewings = '/api/viewings/incoming';

  // Rentals endpoints
  static const String applications = '/api/rentals/applications';
  static const String myApplications = '/api/rentals/applications/my';
  static const String incomingApplications = '/api/rentals/applications/incoming';
  static const String myContracts = '/api/rentals/contracts/my';
  static const String landlordContracts = '/api/rentals/contracts/landlord';

  // Favorites
  static const String favorites = '/api/favorites';

  // Reviews
  static const String reviews = '/api/reviews';

  // Complaints
  static const String complaints = '/api/complaints';
  static const String myComplaints = '/api/complaints/my';
  static const String incomingComplaints = '/api/complaints/incoming';

  // Helper for full image URLs
  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$baseUrl$path';
  }
}
