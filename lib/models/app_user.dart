/// User roles available in StepQuest
enum UserRole {
  user('Utilisateur'),
  admin('Administrateur');

  final String label;
  const UserRole(this.label);

  static UserRole fromString(String val) {
    if (val.toLowerCase().contains('admin')) {
      return UserRole.admin;
    }
    return UserRole.user;
  }
}

/// Account status
enum UserStatus {
  active('Actif'),
  suspended('Suspendu');

  final String label;
  const UserStatus(this.label);

  static UserStatus fromString(String val) {
    if (val.toLowerCase().contains('suspend')) {
      return UserStatus.suspended;
    }
    return UserStatus.active;
  }
}

/// Core AppUser model
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool biometricFingerprintEnabled;
  final bool biometricFaceEnabled;

  // Additional profile fields seen in the UI mockups
  final int? heightCm;
  final double? weightKg;
  final DateTime? birthDate;
  final int level;
  final String? deviceInfo;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    required this.createdAt,
    this.lastLoginAt,
    this.biometricFingerprintEnabled = false,
    this.biometricFaceEnabled = false,
    this.heightCm,
    this.weightKg,
    this.birthDate,
    this.level = 1,
    this.deviceInfo,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isActive => status == UserStatus.active;
  bool get isSuspended => status == UserStatus.suspended;

  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? biometricFingerprintEnabled,
    bool? biometricFaceEnabled,
    int? heightCm,
    double? weightKg,
    DateTime? birthDate,
    int? level,
    String? deviceInfo,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      biometricFingerprintEnabled:
          biometricFingerprintEnabled ?? this.biometricFingerprintEnabled,
      biometricFaceEnabled: biometricFaceEnabled ?? this.biometricFaceEnabled,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      birthDate: birthDate ?? this.birthDate,
      level: level ?? this.level,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'biometricFingerprintEnabled': biometricFingerprintEnabled,
      'biometricFaceEnabled': biometricFaceEnabled,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'birthDate': birthDate?.toIso8601String(),
      'level': level,
      'deviceInfo': deviceInfo,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      role: UserRole.fromString(map['role'] as String? ?? 'user'),
      status: UserStatus.fromString(map['status'] as String? ?? 'active'),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.tryParse(map['lastLoginAt'] as String)
          : null,
      biometricFingerprintEnabled:
          map['biometricFingerprintEnabled'] as bool? ?? false,
      biometricFaceEnabled: map['biometricFaceEnabled'] as bool? ?? false,
      heightCm: map['heightCm'] as int?,
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      birthDate: map['birthDate'] != null
          ? DateTime.tryParse(map['birthDate'] as String)
          : null,
      level: map['level'] as int? ?? 1,
      deviceInfo: map['deviceInfo'] as String?,
    );
  }
}

