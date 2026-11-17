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
  String? _refreshToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    final savedUrl = prefs.getString('custom_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      ApiConstants.setCustomBaseUrl(savedUrl);
    }
    await autoDiscoverBackend();
  }

  Future<void> autoDiscoverBackend() async {
    if (await _canReach(ApiConstants.baseUrl)) {
      return;
    }
    for (final candidate in ApiConstants.candidateBaseUrls) {
      if (candidate == ApiConstants.baseUrl) continue;
      if (await _canReach(candidate)) {
        await setCustomBaseUrl(candidate);
        return;
      }
    }
  }

  Future<bool> _canReach(String base) async {
    try {
      final url = Uri.parse('$base${ApiConstants.amenities}');
      final res = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(milliseconds: 2500));
      return res.statusCode >= 200 && res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  Future<void> setCustomBaseUrl(String? url) async {
    ApiConstants.setCustomBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove('custom_base_url');
    } else {
      await prefs.setString('custom_base_url', ApiConstants.customBaseUrl!);
    }
  }

  Future<void> setTokens({String? accessToken, String? refreshToken}) async {
    _token = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      await prefs.setString('access_token', accessToken);
    } else {
      await prefs.remove('access_token');
      await prefs.remove('cached_user');
    }
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    } else if (accessToken == null) {
      await prefs.remove('refresh_token');
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

  Future<http.Response> _sendWithRefresh(Future<http.Response> Function() requestFn) async {
    http.Response res = await requestFn();
    if (res.statusCode == 401 && _refreshToken != null && _refreshToken!.isNotEmpty) {
      final refreshed = await tryRefreshToken();
      if (refreshed) {
        res = await requestFn();
      }
    }
    return res;
  }

  Future<bool> tryRefreshToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refresh}');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body);
        final authRes = AuthResponse.fromJson(json);
        await setTokens(
          accessToken: authRes.accessToken,
          refreshToken: authRes.refreshToken ?? _refreshToken,
        );
        if (authRes.user != null) {
          await saveUser(authRes.user!);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ---------------- AUTH & USERS ----------------
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
      await setTokens(
        accessToken: authRes.accessToken,
        refreshToken: authRes.refreshToken,
      );
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
    String? profile,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.users}');
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
        'profile': profile ?? '',
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
    await setTokens(accessToken: null, refreshToken: null);
  }

  Future<UserProfileModel> getUserProfile(int userId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.users}/$userId/profile');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      return UserProfileModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  // ---------------- DASHBOARDS ----------------
  Future<TenantHomeModel> getTenantHome() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tenantHome}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      return TenantHomeModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<LandlordDashboardModel> getLandlordDashboard() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordDashboard}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      return LandlordDashboardModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  // ---------------- PROPERTIES & AMENITIES ----------------
  Future<List<PropertyModel>> getProperties({
    String? q,
    String? type,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    bool? furnished,
    List<int>? amenityIds,
    double? lat,
    double? lng,
    double? radiusKm,
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
    if (furnished != null) query['furnished'] = furnished.toString();
    if (amenityIds != null && amenityIds.isNotEmpty) {
      query['amenityIds'] = amenityIds.join(',');
    }
    if (lat != null) query['lat'] = lat.toString();
    if (lng != null) query['lng'] = lng.toString();
    if (radiusKm != null) query['radiusKm'] = radiusKm.toString();

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.properties}')
        .replace(queryParameters: query);
    final res = await http.get(url, headers: _headers());

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
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
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
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

  Future<AmenityModel> createAmenity(String name) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.amenities}');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({'name': name}),
        ));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return AmenityModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  // ---------------- LANDLORD PROPERTIES ----------------
  Future<List<PropertyModel>> getMyProperties() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
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
    bool furnished = false,
    List<int> amenityIds = const [],
    double latitude = 11.5564,
    double longitude = 104.9282,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'title': title,
            'description': description,
            'propertyType': propertyType,
            'address': address,
            'price': price,
            'furnished': furnished,
            'amenityIds': amenityIds,
            'latitude': latitude,
            'longitude': longitude,
          }),
        ));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception(_parseError(res.body));
    }
  }

  Future<PropertyModel> updateProperty(
    int id, {
    required String title,
    required String description,
    required String propertyType,
    required String address,
    required double price,
    bool furnished = false,
    List<int> amenityIds = const [],
    double? latitude,
    double? longitude,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$id');
    final res = await _sendWithRefresh(() => http.put(
          url,
          headers: _headers(),
          body: jsonEncode({
            'title': title,
            'description': description,
            'propertyType': propertyType,
            'address': address,
            'price': price,
            'furnished': furnished,
            'amenityIds': amenityIds,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          }),
        ));

    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception(_parseError(res.body));
    }
  }

  Future<void> deleteProperty(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$id');
    final res = await _sendWithRefresh(() => http.delete(url, headers: _headers()));
    if (res.statusCode >= 300) {
      throw Exception(_parseError(res.body));
    }
  }

  Future<PropertyModel> publishProperty(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$id/publish');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<PropertyModel> unpublishProperty(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$id/unpublish');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  // Room management
  Future<RoomModel> addRoom(
    int propertyId, {
    required String roomNumber,
    required double price,
    int bedrooms = 1,
    int bathrooms = 1,
    double size = 25.0,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$propertyId/rooms');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'roomNumber': roomNumber,
            'price': price,
            'bedrooms': bedrooms,
            'bathrooms': bathrooms,
            'size': size,
          }),
        ));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return RoomModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<RoomModel> updateRoom(
    int roomId, {
    required String roomNumber,
    required double price,
    int bedrooms = 1,
    int bathrooms = 1,
    double size = 25.0,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/rooms/$roomId');
    final res = await _sendWithRefresh(() => http.put(
          url,
          headers: _headers(),
          body: jsonEncode({
            'roomNumber': roomNumber,
            'price': price,
            'bedrooms': bedrooms,
            'bathrooms': bathrooms,
            'size': size,
          }),
        ));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return RoomModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> deleteRoom(int roomId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/rooms/$roomId');
    final res = await _sendWithRefresh(() => http.delete(url, headers: _headers()));
    if (res.statusCode >= 300) {
      throw Exception(_parseError(res.body));
    }
  }

  // Photos
  Future<PropertyModel> addPropertyImageUrl(int propertyId, String imageUrl) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$propertyId/images/url');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({'imageUrl': imageUrl}),
        ));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<PropertyModel> addPropertyImageFile(
    int propertyId,
    List<int> bytes,
    String filename,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$propertyId/images');
    Future<http.Response> send() async {
      final req = http.MultipartRequest('POST', url);
      if (_token != null && _token!.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $_token';
      }
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      return http.Response.fromStream(await req.send());
    }

    final res = await _sendWithRefresh(send);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<PropertyModel> removePropertyImage(int propertyId, int imageId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordProperties}/$propertyId/images/$imageId');
    final res = await _sendWithRefresh(() => http.delete(url, headers: _headers()));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  // ---------------- VIEWINGS ----------------
  Future<void> requestViewing({
    required int propertyId,
    required String date,
    required String time,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewings}');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'propertyId': propertyId,
            'date': date,
            'time': time,
          }),
        ));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ViewingModel>> getMyViewings() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myViewings}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((v) => ViewingModel.fromJson(v)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> cancelViewing(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewings}/$id/cancel');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ViewingModel>> getIncomingViewings() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.incomingViewings}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((v) => ViewingModel.fromJson(v)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> approveViewing(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewings}/$id/approve');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<void> rejectViewing(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewings}/$id/reject');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  // ---------------- RENTALS, CONTRACTS & PAYMENTS ----------------
  Future<void> applyRental({
    required int propertyId,
    int? roomId,
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'propertyId': propertyId,
            'roomId': roomId,
            'startDate': startDate,
            'endDate': endDate,
          }),
        ));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ApplicationModel>> getMyApplications() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myApplications}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((a) => ApplicationModel.fromJson(a)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> cancelApplication(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}/$id/cancel');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ApplicationModel>> getIncomingApplications() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.incomingApplications}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((a) => ApplicationModel.fromJson(a)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<ContractModel> approveApplication(int id, [double? deposit]) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}/$id/approve');
    final bodyMap = <String, dynamic>{};
    if (deposit != null && deposit > 0) {
      bodyMap['deposit'] = deposit;
    }
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode(bodyMap),
        ));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ContractModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<void> rejectApplication(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.applications}/$id/reject');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<List<ContractModel>> getMyContracts() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myContracts}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ContractModel.fromJson(c)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<ContractModel>> getLandlordContracts() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordContracts}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ContractModel.fromJson(c)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<ContractModel>> getExpiringContracts({int days = 30}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.expiringContracts}?days=$days');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ContractModel.fromJson(c)).toList();
    }
    return [];
  }

  Future<ContractModel> renewContract(int contractId, int months) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.contracts}/$contractId/renew');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({'months': months}),
        ));
    if (res.statusCode == 200) {
      return ContractModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<ContractModel> endContract(int contractId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.contracts}/$contractId/end');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode == 200) {
      return ContractModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<ContractModel> moveInContract(int contractId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.contracts}/$contractId/move-in');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode == 200) {
      return ContractModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<PaymentModel>> getContractPayments(int contractId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.contracts}/$contractId/payments');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((p) => PaymentModel.fromJson(p)).toList();
    }
    return [];
  }

  Future<List<PaymentModel>> getLandlordPayments({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landlordPayments}$query');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((p) => PaymentModel.fromJson(p)).toList();
    }
    return [];
  }

  Future<void> payRental(int paymentId, String method) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payments}/$paymentId/pay');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({'method': method}),
        ));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  // ---------------- FAVORITES ----------------
  Future<List<PropertyModel>> getFavorites() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.favorites}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((item) => PropertyModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> addFavorite(int propertyId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.favorites}/$propertyId');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<void> removeFavorite(int propertyId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.favorites}/$propertyId');
    final res = await _sendWithRefresh(() => http.delete(url, headers: _headers()));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
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
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'propertyId': propertyId,
            'rating': rating,
            'comment': comment ?? '',
          }),
        ));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  // ---------------- MESSAGES / CHAT ----------------
  Future<List<ContactModel>> getContacts() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.messageContacts}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ContactModel.fromJson(c)).toList();
    }
    return [];
  }

  Future<List<ChatMessageModel>> getConversation(int otherUserId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.messages}/with/$otherUserId');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((m) => ChatMessageModel.fromJson(m)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<ChatMessageModel> sendMessage(int receiverId, String message) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.messages}');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'receiverId': receiverId,
            'message': message,
          }),
        ));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ChatMessageModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  // ---------------- COMPLAINTS ----------------
  Future<List<ComplaintModel>> getMyComplaints() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myComplaints}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ComplaintModel.fromJson(c)).toList();
    }
    return [];
  }

  Future<List<ComplaintModel>> getIncomingComplaints() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.incomingComplaints}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ComplaintModel.fromJson(c)).toList();
    }
    return [];
  }

  Future<void> submitComplaint(int propertyId, String description) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.complaints}');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({'propertyId': propertyId, 'description': description}),
        ));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  Future<void> updateComplaintStatus(int id, String status) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.complaints}/$id/status?status=$status');
    final res = await _sendWithRefresh(() => http.patch(url, headers: _headers()));
    if (res.statusCode >= 300) throw Exception(_parseError(res.body));
  }

  // ---------------- ADMIN ----------------
  Future<AdminDashboardModel> getAdminDashboard() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminDashboard}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      return AdminDashboardModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<AdminUserModel>> getAdminUsers({int page = 0, int size = 50}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminUsers}?page=$page&size=$size');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      if (json is Map && json['content'] != null) {
        return (json['content'] as List).map((u) => AdminUserModel.fromJson(u)).toList();
      } else if (json is List) {
        return json.map((u) => AdminUserModel.fromJson(u)).toList();
      }
    }
    throw Exception(_parseError(res.body));
  }

  Future<AdminUserModel> setAdminUserEnabled(int userId, bool enabled) async {
    final action = enabled ? 'enable' : 'disable';
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminUsers}/$userId/$action');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode == 200) {
      return AdminUserModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<PropertyModel>> getAdminProperties({String? status, int page = 0, int size = 50}) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminProperties}')
        .replace(queryParameters: query);
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      if (json is Map && json['content'] != null) {
        return (json['content'] as List).map((p) => PropertyModel.fromJson(p)).toList();
      } else if (json is List) {
        return json.map((p) => PropertyModel.fromJson(p)).toList();
      }
    }
    throw Exception(_parseError(res.body));
  }

  Future<PropertyModel> verifyProperty(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminProperties}/$id/verify');
    final res = await _sendWithRefresh(() => http.post(url, headers: _headers()));
    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<PropertyModel> rejectProperty(int id, String reason) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminProperties}/$id/reject');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({'reason': reason}),
        ));
    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<PropertyModel> takeDownProperty(int id, String reason) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminProperties}/$id/take-down');
    final res = await _sendWithRefresh(() => http.post(
          url,
          headers: _headers(),
          body: jsonEncode({'reason': reason}),
        ));
    if (res.statusCode == 200) {
      return PropertyModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<ContractModel>> getAdminRentals({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminRentals}$query');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ContractModel.fromJson(c)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<PaymentModel>> getAdminOverduePayments() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminOverduePayments}');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((p) => PaymentModel.fromJson(p)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<List<ComplaintModel>> getAdminComplaints({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminComplaints}$query');
    final res = await _sendWithRefresh(() => http.get(url, headers: _headers()));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((c) => ComplaintModel.fromJson(c)).toList();
    }
    throw Exception(_parseError(res.body));
  }

  Future<ComplaintModel> resolveAdminComplaint(
    int id, {
    required String status,
    String? resolution,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminComplaints}/$id');
    final res = await _sendWithRefresh(() => http.patch(
          url,
          headers: _headers(),
          body: jsonEncode({
            'status': status,
            'resolution': resolution ?? '',
          }),
        ));
    if (res.statusCode == 200) {
      return ComplaintModel.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseError(res.body));
  }

  String _parseError(String body) {
    try {
      final map = jsonDecode(body);
      if (map is Map) {
        if (map['data'] is String && (map['data'] as String).isNotEmpty) {
          return map['data'];
        }
        return (map['message'] ?? map['error'] ?? map['data'] ?? '').toString();
      }
    } catch (_) {}
    return body;
  }
}
