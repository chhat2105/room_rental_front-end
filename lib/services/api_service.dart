import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../models/user_model.dart';
import '../models/property_model.dart';
import '../models/rental_model.dart';
import '../models/extra_models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  String? get token => _token;

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('access_token', token);
    } else {
      await prefs.remove('access_token');
      await prefs.remove('cached_user');
    }
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toJson()));
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('cached_user');
    if (userStr != null) {
      try {
        return UserModel.fromJson(jsonDecode(userStr));
      } catch (_) {}
    }
    return null;
  }

  Map<String, String> _headers({bool isJson = true}) {
    final map = <String, String>{};
    if (isJson) {
      map['Content-Type'] = 'application/json';
      map['Accept'] = 'application/json';
    }
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  // ---------------- AUTH ----------------
  Future<AuthResponse> login(String username, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body);
      final authRes = AuthResponse.fromJson(json);
      await setToken(authRes.accessToken);
      if (authRes.user != null) {
        await saveUser(authRes.user!);
      }
      return authRes;
    } else {
      final err = _parseError(res.body);
      throw Exception(err.isNotEmpty ? err : 'Login failed (${res.statusCode})');
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
        'role': role,
        'profile': '',
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final err = _parseError(res.body);
      throw Exception(err.isNotEmpty ? err : 'Registration failed');
    }
  }

  Future<void> logout([int? userId]) async {
    try {
      if (userId != null && _token != null) {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}');
        await http.post(
          url,
          headers: _headers(),
          body: jsonEncode({'userId': userId}),
        );
      }
    } catch (_) {}
    await setToken(null);
  }

  // ---------------- PROPERTIES ----------------
  Future<List<PropertyModel>> getProperties({
    String? q,
    String? type,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int page = 0,
    int size = 20,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (type != null && type != 'ALL') query['type'] = type;
    if (minPrice != null) query['minPrice'] = minPrice.toString();
    if (maxPrice != null) query['maxPrice'] = maxPrice.toString();
    if (bedrooms != null) query['bedrooms'] = bedrooms.toString();

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.properties}').replace(queryParameters: query);
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      // Spring Data Page returns content in "content"
      if (json is Map && json['content'] != null) {
        return (json['content'] as List)
            .map((item) => PropertyModel.fromJson(item))
            .toList();
      } else if (json is List) {
        return json.map((item) => PropertyModel.fromJson(item)).toList();
      }
      return [];
    } else {
      throw Exception(_parseError(res.body));
    }
  }

  Future<PropertyModel> getProperty(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.properties}/$id');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception(_parseError(res.body));
    }
  }

  Future<List<AmenityModel>> getAmenities() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.amenities}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((a) => AmenityModel.fromJson(a)).toList();
    }
    return [];
  }

  // ---------------- LANDLORD PROPERTIES ----------------
  Future<List<PropertyModel>> getMyProperties() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((item) => PropertyModel.fromJson(item)).toList();
    } else {
      throw Exception(_parseError(res.body));
    }
  }

  Future<PropertyModel> createProperty({
    required String title,
    required String description,
    required String propertyType,
    required String address,
    required double price,
    List<int> amenityIds = const [],
    double latitude = 11.5564,
    double longitude = 104.9282,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'propertyType': propertyType,
        'address': address,
        'price': price,
        'amenityIds': amenityIds,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception(_parseError(res.body));
    }
  }

  Future<PropertyModel> updateProperty(int id, {
    required String title,
    required String description,
    required String propertyType,
    required String address,
    required double price,
    List<int> amenityIds = const [],
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$id');
    final res = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'propertyType': propertyType,
        'address': address,
        'price': price,
        'amenityIds': amenityIds,
      }),
    );

    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception(_parseError(res.body));
    }
  }

  Future<void> deleteProperty(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$id');
    final res = await http.delete(url, headers: _headers());
    if (res.statusCode >= 300) {
      throw Exception(_parseError(res.body));
    }
  }

  Future<PropertyModel> publishProperty(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$id/publish');
    final res = await http.post(url, headers: _headers());
    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<PropertyModel> unpublishProperty(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$id/unpublish');
    final res = await http.post(url, headers: _headers());
    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  // Room management
  Future<RoomModel> addRoom(int propertyId, {
    required String roomNumber,
    required double price,
    int bedrooms = 1,
    int bathrooms = 1,
    double size = 25.0,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$propertyId/rooms');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'roomNumber': roomNumber,
        'price': price,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'size': size,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return RoomModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> deleteRoom(int roomId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/rooms/$roomId');
    final res = await http.delete(url, headers: _headers());
    if (res.statusCode >= 300) {
      throw Exception(_parseError(res.body));
    }
  }

  // Photos
  Future<void> addPropertyImageUrl(int propertyId, String imageUrl) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$propertyId/images/url');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'imageUrl': imageUrl}),
    );
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<void> removePropertyImage(int propertyId, int imageId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$propertyId/images/$imageId');
    final res = await http.delete(url, headers: _headers());
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  // ---------------- VIEWINGS ----------------
  Future<void> requestViewing({
    required int propertyId,
    required String date,
    required String time,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewings}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'propertyId': propertyId,
        'date': date,
        'time': time,
      }),
    );
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ViewingModel>> getMyViewings() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myViewings}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((v) => ViewingModel.fromJson(v)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> cancelViewing(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewings}/$id/cancel');
    final res = await http.post(url, headers: _headers());
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ViewingModel>> getIncomingViewings() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.incomingViewings}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((v) => ViewingModel.fromJson(v)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> approveViewing(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewings}/$id/approve');
    final res = await http.post(url, headers: _headers());
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<void> rejectViewing(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewings}/$id/reject');
    final res = await http.post(url, headers: _headers());
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  // ---------------- RENTALS & CONTRACTS ----------------
  Future<void> applyRental({
    required int propertyId,
    int? roomId,
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'propertyId': propertyId,
        'roomId': roomId,
        'startDate': startDate,
        'endDate': endDate,
      }),
    );
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ApplicationModel>> getMyApplications() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myApplications}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((a) => ApplicationModel.fromJson(a)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> cancelApplication(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}/$id/cancel');
    final res = await http.post(url, headers: _headers());
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ApplicationModel>> getIncomingApplications() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.incomingApplications}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((a) => ApplicationModel.fromJson(a)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> approveApplication(int id, double deposit) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}/$id/approve');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'deposit': deposit}),
    );
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<void> rejectApplication(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}/$id/reject');
    final res = await http.post(url, headers: _headers());
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ContractModel>> getMyContracts() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myContracts}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ContractModel.fromJson(c)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<ContractModel>> getLandlordContracts() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordContracts}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ContractModel.fromJson(c)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<PaymentModel>> getContractPayments(int contractId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/rentals/contracts/$contractId/payments');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((p) => PaymentModel.fromJson(p)).toList();
    }
    return [];
  }

  Future<void> payRental(int paymentId, String method) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/rentals/payments/$paymentId/pay');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'method': method}),
    );
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  // ---------------- FAVORITES ----------------
  Future<List<PropertyModel>> getFavorites() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.favorites}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((item) => PropertyModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> addFavorite(int propertyId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.favorites}/$propertyId');
    await http.post(url, headers: _headers());
  }

  Future<void> removeFavorite(int propertyId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.favorites}/$propertyId');
    await http.delete(url, headers: _headers());
  }

  // ---------------- REVIEWS ----------------
  Future<List<ReviewModel>> getPropertyReviews(int propertyId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviews}/property/$propertyId');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((r) => ReviewModel.fromJson(r)).toList();
    }
    return [];
  }

  Future<void> addReview({required int propertyId, required int rating, String? comment}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviews}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'propertyId': propertyId,
        'rating': rating,
        'comment': comment ?? '',
      }),
    );
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  // ---------------- COMPLAINTS ----------------
  Future<List<ComplaintModel>> getMyComplaints() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myComplaints}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ComplaintModel.fromJson(c)).toList();
    }
    return [];
  }

  Future<List<ComplaintModel>> getIncomingComplaints() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.incomingComplaints}');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ComplaintModel.fromJson(c)).toList();
    }
    return [];
  }

  Future<void> submitComplaint(int propertyId, String description) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.complaints}');
    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'propertyId': propertyId, 'description': description}),
    );
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<void> updateComplaintStatus(int id, String status) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/complaints/$id/status?status=$status');
    final res = await http.patch(url, headers: _headers());
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  String _parseError(String body) {
    try {
      final map = jsonDecode(body);
      if (map is Map) {
        return map['message'] ?? map['error'] ?? map['data'] ?? '';
      }
    } catch (_) {}
    return body;
  }
}
