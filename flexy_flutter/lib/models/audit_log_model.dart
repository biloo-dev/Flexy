class AuditLogModel {
  final int? id;
  final int? userId;
  final String? userFullName;
  final String action;
  final String resource;
  final String? resourceId;
  final String status; // 'SUCCESS' or 'DENIED'
  final String? reason;
  final String createdAt;

  AuditLogModel({
    this.id,
    this.userId,
    this.userFullName,
    required this.action,
    required this.resource,
    this.resourceId,
    required this.status,
    this.reason,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isSuccess => status == 'SUCCESS';
  bool get isDenied => status == 'DENIED';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'action': action,
      'resource': resource,
      'resourceId': resourceId,
      'status': status,
      'reason': reason,
      'createdAt': createdAt,
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      userFullName: map['userFullName'] as String?,
      action: map['action'] as String? ?? '',
      resource: map['resource'] as String? ?? '',
      resourceId: map['resourceId'] as String?,
      status: map['status'] as String? ?? 'SUCCESS',
      reason: map['reason'] as String?,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
