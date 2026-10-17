class RoleModel {
  final int? id;
  final String name;
  final String displayName;
  final String? description;
  final bool isSystem;
  final String createdAt;
  final List<String> permissions;

  RoleModel({
    this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.isSystem = false,
    String? createdAt,
    this.permissions = const [],
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  RoleModel copyWith({
    int? id,
    String? name,
    String? displayName,
    String? description,
    bool? isSystem,
    String? createdAt,
    List<String>? permissions,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'displayName': displayName,
      'description': description,
      'isSystem': isSystem ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory RoleModel.fromMap(Map<String, dynamic> map, {List<String> permissions = const []}) {
    return RoleModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      description: map['description'] as String?,
      isSystem: (map['isSystem'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      permissions: permissions,
    );
  }
}
