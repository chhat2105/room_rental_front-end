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
      date: json['date'] ?? '',
      time: json['time'] ?? '',
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

  ComplaintModel({
    required this.id,
    this.tenantId,
    this.tenantName,
    required this.propertyId,
    required this.propertyTitle,
    required this.description,
    required this.status,
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
