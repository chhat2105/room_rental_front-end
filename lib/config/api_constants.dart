import 'package:flutter/foundation.dart';

class ApiConstants {
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _customBaseUrl = null;
    } else {
      String cleaned = url.trim();
      if (cleaned.endsWith('/')) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
      _customBaseUrl = cleaned;
    }
  }

  static String? get customBaseUrl => _customBaseUrl;

  // Candidate URLs to auto-discover the running Spring Boot backend across
  // Web, Windows Desktop, Android Emulator (10.0.2.2), and Physical Device on LAN.
  static List<String> get candidateBaseUrls {
    if (kIsWeb) {
      return [
        'http://localhost:1212',
        'http://127.0.0.1:1212',
        'http://localhost:8080',
        'http://localhost:9091',
      ];
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return [
        'http://10.0.2.2:1212',
        'http://localhost:1212',
        'http://10.10.1.64:1212',
        'http://10.0.2.2:8080',
        'http://10.10.1.64:8080',
      ];
    }
    return [
      'http://localhost:1212',
      'http://127.0.0.1:1212',
      'http://10.10.1.64:1212',
      'http://localhost:8080',
      'http://localhost:9091',
    ];
  }

  // If running on Android emulator, localhost is 10.0.2.2.
  // On Web, Windows desktop, iOS, or real device, it connects to localhost or custom LAN IP.
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:1212';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:1212';
    }
    return 'http://localhost:1212';
  }

  // Auth & User endpoints (matches AuthController & UserController)
  static const String login = '/api/auth/token';
  static const String logout = '/api/auth/logout';
  static const String refresh = '/api/auth/refresh';
  static const String users = '/api/users'; // POST to register, GET /{id}/profile

  // Properties & Amenities endpoints
  static const String properties = '/api/properties';
  static const String amenities = '/api/amenities';

  // Landlord endpoints
  static const String landlordProperties = '/api/landlord/properties';
  static const String landlordDashboard = '/api/landlord/dashboard';

  // Tenant dashboard endpoint
  static const String tenantHome = '/api/tenant/home';

  // Viewing endpoints
  static const String viewings = '/api/viewings';
  static const String myViewings = '/api/viewings/my';
  static const String incomingViewings = '/api/viewings/incoming';

  // Rentals, Contracts & Payments endpoints
  static const String applications = '/api/rentals/applications';
  static const String myApplications = '/api/rentals/applications/my';
  static const String incomingApplications = '/api/rentals/applications/incoming';
  static const String contracts = '/api/rentals/contracts';
  static const String myContracts = '/api/rentals/contracts/my';
  static const String landlordContracts = '/api/rentals/contracts/landlord';
  static const String expiringContracts = '/api/rentals/contracts/expiring';
  static const String payments = '/api/rentals/payments';
  static const String landlordPayments = '/api/rentals/payments/landlord';

  // Favorites
  static const String favorites = '/api/favorites';

  // Reviews
  static const String reviews = '/api/reviews';

  // Messages / Chat
  static const String messages = '/api/messages';
  static const String messageContacts = '/api/messages/contacts';

  // Complaints
  static const String complaints = '/api/complaints';
  static const String myComplaints = '/api/complaints/my';
  static const String incomingComplaints = '/api/complaints/incoming';

  // Admin endpoints
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminUsers = '/api/admin/users';
  static const String adminProperties = '/api/admin/properties';
  static const String adminRentals = '/api/admin/rentals';
  static const String adminOverduePayments = '/api/admin/payments/overdue';
  static const String adminComplaints = '/api/admin/complaints';

  // Helper for full image URLs
  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (!path.startsWith('/')) {
      return '$baseUrl/$path';
    }
    return '$baseUrl$path';
  }
}
