class UserModel {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profile;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profile,
    required this.roles,
  });

  String get fullName {
    if (firstName != null && firstName!.isNotEmpty) {
      return '$firstName ${lastName ?? ''}'.trim();
    }
    return username;
  }

  bool get isLandlord => roles.any((r) => r.toUpperCase().contains('LANDLORD'));
  bool get isTenant => !isLandlord;
  bool get isAdmin => roles.any((r) => r.toUpperCase().contains('ADMIN'));

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json['roles'] != null && json['roles'] is List) {
      for (var r in json['roles']) {
        if (r is Map && r['name'] != null) {
          parsedRoles.add(r['name'].toString());
        } else if (r is String) {
          parsedRoles.add(r);
        }
      }
    } else if (json['role'] != null) {
      parsedRoles.add(json['role'].toString());
    }

    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      profile: json['profile'],
      roles: parsedRoles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profile': profile,
      'roles': roles,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final UserModel? user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresIn,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
