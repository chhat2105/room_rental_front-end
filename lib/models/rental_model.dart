class ApplicationModel {
  final int id;
  final int? tenantId;
  final String? tenantName;
  final int propertyId;
  final String propertyTitle;
  final int? roomId;
  final String startDate;
  final String endDate;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'

  ApplicationModel({
    required this.id,
    this.tenantId,
    this.tenantName,
    required this.propertyId,
    required this.propertyTitle,
    this.roomId,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tenantId: (json['tenantId'] as num?)?.toInt(),
      tenantName: json['tenantName'],
      propertyId: (json['propertyId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      roomId: (json['roomId'] as num?)?.toInt(),
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? 'PENDING',
    );
  }
}

class ContractModel {
  final int id;
  final int? applicationId;
  final int propertyId;
  final String propertyTitle;
  final int? tenantId;
  final String tenantName;
  final double rent;
  final double deposit;
  final String startDate;
  final String endDate;
  final String status; // 'PENDING_PAYMENT', 'ACTIVE', 'COMPLETED', 'CANCELLED'

  ContractModel({
    required this.id,
    this.applicationId,
    required this.propertyId,
    required this.propertyTitle,
    this.tenantId,
    required this.tenantName,
    required this.rent,
    required this.deposit,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      applicationId: (json['applicationId'] as num?)?.toInt(),
      propertyId: (json['propertyId'] as num?)?.toInt() ?? 0,
      propertyTitle: json['propertyTitle'] ?? '',
      tenantId: (json['tenantId'] as num?)?.toInt(),
      tenantName: json['tenantName'] ?? '',
      rent: (json['rent'] as num?)?.toDouble() ?? 0.0,
      deposit: (json['deposit'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? 'PENDING_PAYMENT',
    );
  }
}

class PaymentModel {
  final int id;
  final int? contractId;
  final String type; // 'DEPOSIT', 'RENT'
  final double amount;
  final String dueDate;
  final String? paymentDate;
  final String? paymentMethod; // 'CASH', 'BANK_TRANSFER', 'ABA_PAY', 'WING', 'CARD'
  final String status; // 'PENDING', 'PAID', 'OVERDUE', 'CANCELLED'

  PaymentModel({
    required this.id,
    this.contractId,
    required this.type,
    required this.amount,
    required this.dueDate,
    this.paymentDate,
    this.paymentMethod,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      contractId: (json['contractId'] as num?)?.toInt(),
      type: json['type'] ?? 'RENT',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] ?? '',
      paymentDate: json['paymentDate'],
      paymentMethod: json['paymentMethod'],
      status: json['status'] ?? 'PENDING',
    );
  }
}
