/// Core rental data models for RentWise

/// Rental property information
class RentalProperty {
  final String id;
  final String userId;
  final String name;
  final String address;
  final String unit;
  final String landlordName;
  final String landlordEmail;
  final String landlordPhone;
  final double monthlyRent;
  final int leaseTermMonths;
  final DateTime leaseStartDate;
  final DateTime leaseEndDate;
  final List<String> amenities;
  final String propertyType; // 'apartment', 'house', 'condo', etc.
  final String status; // 'active', 'upcoming', 'ended'
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentalProperty({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.unit,
    required this.landlordName,
    required this.landlordEmail,
    required this.landlordPhone,
    required this.monthlyRent,
    required this.leaseTermMonths,
    required this.leaseStartDate,
    required this.leaseEndDate,
    required this.amenities,
    required this.propertyType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RentalProperty.fromJson(Map<String, dynamic> json) {
    return RentalProperty(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      unit: json['unit'] as String,
      landlordName: json['landlordName'] as String,
      landlordEmail: json['landlordEmail'] as String,
      landlordPhone: json['landlordPhone'] as String,
      monthlyRent: (json['monthlyRent'] as num).toDouble(),
      leaseTermMonths: json['leaseTermMonths'] as int,
      leaseStartDate: DateTime.parse(json['leaseStartDate'] as String),
      leaseEndDate: DateTime.parse(json['leaseEndDate'] as String),
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      propertyType: json['propertyType'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'address': address,
      'unit': unit,
      'landlordName': landlordName,
      'landlordEmail': landlordEmail,
      'landlordPhone': landlordPhone,
      'monthlyRent': monthlyRent,
      'leaseTermMonths': leaseTermMonths,
      'leaseStartDate': leaseStartDate.toIso8601String(),
      'leaseEndDate': leaseEndDate.toIso8601String(),
      'amenities': amenities,
      'propertyType': propertyType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  RentalProperty copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    String? unit,
    String? landlordName,
    String? landlordEmail,
    String? landlordPhone,
    double? monthlyRent,
    int? leaseTermMonths,
    DateTime? leaseStartDate,
    DateTime? leaseEndDate,
    List<String>? amenities,
    String? propertyType,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RentalProperty(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      unit: unit ?? this.unit,
      landlordName: landlordName ?? this.landlordName,
      landlordEmail: landlordEmail ?? this.landlordEmail,
      landlordPhone: landlordPhone ?? this.landlordPhone,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      leaseTermMonths: leaseTermMonths ?? this.leaseTermMonths,
      leaseStartDate: leaseStartDate ?? this.leaseStartDate,
      leaseEndDate: leaseEndDate ?? this.leaseEndDate,
      amenities: amenities ?? this.amenities,
      propertyType: propertyType ?? this.propertyType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate days until lease expires
  int get daysUntilLeaseExpires {
    final now = DateTime.now();
    return leaseEndDate.difference(now).inDays;
  }

  /// Check if lease is expiring soon (within 90 days)
  bool get isLeaseExpiringSoon => daysUntilLeaseExpires <= 90 && daysUntilLeaseExpires > 0;

  /// Check if lease has expired
  bool get isLeaseExpired => daysUntilLeaseExpires < 0;

  /// Get lease status description
  String get leaseStatusDescription {
    if (isLeaseExpired) return 'Lease Expired';
    if (isLeaseExpiringSoon) return 'Expires in ${daysUntilLeaseExpires} days';
    return 'Active Lease';
  }

  /// Get lease progress (0.0 to 1.0)
  double get leaseProgress {
    final totalDays = leaseEndDate.difference(leaseStartDate).inDays;
    final elapsedDays = DateTime.now().difference(leaseStartDate).inDays;
    return (elapsedDays / totalDays).clamp(0.0, 1.0);
  }
}

/// Rent payment information
class RentPayment {
  final String id;
  final String propertyId;
  final String userId;
  final double amount;
  final double lateFee;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // 'pending', 'paid', 'overdue', 'failed'
  final String paymentMethod;
  final String? transactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentPayment({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.amount,
    required this.lateFee,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RentPayment.fromJson(Map<String, dynamic> json) {
    return RentPayment(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      lateFee: (json['lateFee'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      transactionId: json['transactionId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'amount': amount,
      'lateFee': lateFee,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Calculate total amount including late fees
  double get totalAmount => amount + lateFee;

  /// Check if payment is overdue
  bool get isOverdue {
    final now = DateTime.now();
    return status != 'paid' && dueDate.isBefore(now);
  }

  /// Get days overdue
  int get daysOverdue {
    if (!isOverdue) return 0;
    final now = DateTime.now();
    return now.difference(dueDate).inDays;
  }

  /// Check if payment is due soon (within 3 days)
  bool get isDueSoon {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    return daysUntilDue <= 3 && daysUntilDue >= 0 && status != 'paid';
  }
}

/// Maintenance request for property repairs
class MaintenanceRequest {
  final String id;
  final String propertyId;
  final String userId;
  final String title;
  final String description;
  final String category; // 'plumbing', 'electrical', 'structural', etc.
  final String priority; // 'low', 'medium', 'high', 'emergency'
  final String status; // 'submitted', 'acknowledged', 'in_progress', 'completed', 'cancelled'
  final List<String> photoUrls;
  final DateTime submittedAt;
  final DateTime? acknowledgedAt;
  final DateTime? completedAt;
  final String? landlordResponse;
  final DateTime? estimatedCompletion;
  final String? assignedTo;
  final double? estimatedCost;
  final DateTime updatedAt;

  const MaintenanceRequest({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.photoUrls,
    required this.submittedAt,
    this.acknowledgedAt,
    this.completedAt,
    this.landlordResponse,
    this.estimatedCompletion,
    this.assignedTo,
    this.estimatedCost,
    required this.updatedAt,
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      landlordResponse: json['landlordResponse'] as String?,
      estimatedCompletion: json['estimatedCompletion'] != null
          ? DateTime.parse(json['estimatedCompletion'] as String)
          : null,
      assignedTo: json['assignedTo'] as String?,
      estimatedCost: json['estimatedCost'] != null
          ? (json['estimatedCost'] as num).toDouble()
          : null,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'photoUrls': photoUrls,
      'submittedAt': submittedAt.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'landlordResponse': landlordResponse,
      'estimatedCompletion': estimatedCompletion?.toIso8601String(),
      'assignedTo': assignedTo,
      'estimatedCost': estimatedCost,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get priority color
  Color get priorityColor {
    switch (priority) {
      case 'emergency':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get status color
  Color get statusColor {
    switch (status) {
      case 'submitted':
        return Colors.grey;
      case 'acknowledged':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Check if request is active
  bool get isActive => !['completed', 'cancelled'].contains(status);

  /// Get days since submission
  int get daysSinceSubmission {
    return DateTime.now().difference(submittedAt).inDays;
  }

  /// Check if overdue on estimated completion
  bool get isOverdue {
    if (estimatedCompletion == null) return false;
    return DateTime.now().isAfter(estimatedCompletion!) && status != 'completed';
  }
}

/// Document storage for lease agreements and receipts
class RentalDocument {
  final String id;
  final String propertyId;
  final String userId;
  final String name;
  final String type; // 'lease', 'receipt', 'insurance', etc.
  final String fileUrl;
  final String? extractedText;
  final Map<String, dynamic> metadata;
  final DateTime uploadedAt;
  final DateTime? expiresAt;
  final bool isEncrypted;

  const RentalDocument({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.name,
    required this.type,
    required this.fileUrl,
    this.extractedText,
    required this.metadata,
    required this.uploadedAt,
    this.expiresAt,
    required this.isEncrypted,
  });

  factory RentalDocument.fromJson(Map<String, dynamic> json) {
    return RentalDocument(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      fileUrl: json['fileUrl'] as String,
      extractedText: json['extractedText'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'name': name,
      'type': type,
      'fileUrl': fileUrl,
      'extractedText': extractedText,
      'metadata': metadata,
      'uploadedAt': uploadedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isEncrypted': isEncrypted,
    };
  }

  /// Check if document is expiring soon
  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final daysUntilExpiry = expiresAt!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  /// Check if document has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Communication thread with landlord
class LandlordMessage {
  final String id;
  final String propertyId;
  final String userId;
  final String senderId;
  final String senderType; // 'tenant', 'landlord'
  final String subject;
  final String message;
  final List<String> attachmentUrls;
  final bool isRead;
  final DateTime sentAt;
  final String? threadId; // For grouping related messages

  const LandlordMessage({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.senderId,
    required this.senderType,
    required this.subject,
    required this.message,
    required this.attachmentUrls,
    required this.isRead,
    required this.sentAt,
    this.threadId,
  });

  factory LandlordMessage.fromJson(Map<String, dynamic> json) {
    return LandlordMessage(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      userId: json['userId'] as String,
      senderId: json['senderId'] as String,
      senderType: json['senderType'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      isRead: json['isRead'] as bool? ?? false,
      sentAt: DateTime.parse(json['sentAt'] as String),
      threadId: json['threadId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'senderId': senderId,
      'senderType': senderType,
      'subject': subject,
      'message': message,
      'attachmentUrls': attachmentUrls,
      'isRead': isRead,
      'sentAt': sentAt.toIso8601String(),
      'threadId': threadId,
    };
  }

  /// Check if message is from tenant
  bool get isFromTenant => senderType == 'tenant';

  /// Check if message is from landlord
  bool get isFromLandlord => senderType == 'landlord';
}
