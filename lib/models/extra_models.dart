import 'property_model.dart';
import 'rental_model.dart';

class ViewingModel {
  final int id;
  final int? tenantId;
  final String? tenantName;
  final int propertyId;
  final String propertyTitle;
  final String date;
  final String time;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'

  ViewingModel({
    required this.id,
    this.tenantId,
    this.tenantName,
    required this.propertyId,
    required this.propertyTitle,
    required this.date,
    required this.time,
    required this.status,
  });

  factory ViewingModel.fromJson(Map<String, dynamic> json) {
    return ViewingModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tenantId: (json['tenantId'] as num?)?.toInt(),
      tenantName: json['tenantName'],
      propertyId: (json['propertyId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: json['status'] ?? 'PENDING',
    );
  }
}

class ComplaintModel {
  final int id;
  final int? tenantId;
  final String? tenantName;
  final int propertyId;
  final String propertyTitle;
  final String description;
  final String status; // 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'
  final String? resolution;

  ComplaintModel({
    required this.id,
    this.tenantId,
    this.tenantName,
    required this.propertyId,
    required this.propertyTitle,
    required this.description,
    required this.status,
    this.resolution,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tenantId: (json['tenantId'] as num?)?.toInt(),
      tenantName: json['tenantName'],
      propertyId: (json['propertyId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'OPEN',
      resolution: json['resolution'],
    );
  }
}

class ReviewModel {
  final int id;
  final int? tenantId;
  final String? tenantName;
  final int propertyId;
  final int rating;
  final String? comment;

  ReviewModel({
    required this.id,
    this.tenantId,
    this.tenantName,
    required this.propertyId,
    required this.rating,
    this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tenantId: (json['tenantId'] as num?)?.toInt(),
      tenantName: json['tenantName'],
      propertyId: (json['propertyId'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'],
    );
  }
}

class ChatMessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final String? createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      receiverId: (json['receiverId'] as num?)?.toInt() ?? 0,
      message: json['message'] ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class ContactModel {
  final int id;
  final String name;

  ContactModel({required this.id, required this.name});

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class TenantHomeModel {
  final List<PropertyModel> latestProperties;
  final int favoritesCount;
  final List<ContractModel> activeContracts;
  final List<ViewingModel> upcomingViewings;
  final List<PaymentModel> duePayments;

  TenantHomeModel({
    required this.latestProperties,
    required this.favoritesCount,
    required this.activeContracts,
    required this.upcomingViewings,
    required this.duePayments,
  });

  factory TenantHomeModel.fromJson(Map<String, dynamic> json) {
    return TenantHomeModel(
      latestProperties: (json['latestProperties'] as List? ?? [])
          .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      favoritesCount: (json['favoritesCount'] as num?)?.toInt() ?? 0,
      activeContracts: (json['activeContracts'] as List? ?? [])
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingViewings: (json['upcomingViewings'] as List? ?? [])
          .map((e) => ViewingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      duePayments: (json['duePayments'] as List? ?? [])
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LandlordDashboardModel {
  final int totalProperties;
  final int publishedProperties;
  final int pendingReview;
  final int pendingApplications;
  final int pendingViewings;
  final int activeContracts;
  final int expiringIn30Days;
  final int overduePayments;
  final int openComplaints;
  final double revenueThisMonth;

  LandlordDashboardModel({
    required this.totalProperties,
    required this.publishedProperties,
    required this.pendingReview,
    required this.pendingApplications,
    required this.pendingViewings,
    required this.activeContracts,
    required this.expiringIn30Days,
    required this.overduePayments,
    required this.openComplaints,
    required this.revenueThisMonth,
  });

  factory LandlordDashboardModel.fromJson(Map<String, dynamic> json) {
    return LandlordDashboardModel(
      totalProperties: (json['totalProperties'] as num?)?.toInt() ?? 0,
      publishedProperties: (json['publishedProperties'] as num?)?.toInt() ?? 0,
      pendingReview: (json['pendingReview'] as num?)?.toInt() ?? 0,
      pendingApplications: (json['pendingApplications'] as num?)?.toInt() ?? 0,
      pendingViewings: (json['pendingViewings'] as num?)?.toInt() ?? 0,
      activeContracts: (json['activeContracts'] as num?)?.toInt() ?? 0,
      expiringIn30Days: (json['expiringIn30Days'] as num?)?.toInt() ?? 0,
      overduePayments: (json['overduePayments'] as num?)?.toInt() ?? 0,
      openComplaints: (json['openComplaints'] as num?)?.toInt() ?? 0,
      revenueThisMonth: (json['revenueThisMonth'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminDashboardModel {
  final int totalUsers;
  final int pendingListings;
  final int publishedListings;
  final int activeRentals;
  final int overduePayments;
  final int openComplaints;

  AdminDashboardModel({
    required this.totalUsers,
    required this.pendingListings,
    required this.publishedListings,
    required this.activeRentals,
    required this.overduePayments,
    required this.openComplaints,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      pendingListings: (json['pendingListings'] as num?)?.toInt() ?? 0,
      publishedListings: (json['publishedListings'] as num?)?.toInt() ?? 0,
      activeRentals: (json['activeRentals'] as num?)?.toInt() ?? 0,
      overduePayments: (json['overduePayments'] as num?)?.toInt() ?? 0,
      openComplaints: (json['openComplaints'] as num?)?.toInt() ?? 0,
    );
  }
}
