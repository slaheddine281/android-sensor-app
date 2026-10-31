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

  // Reconnaissance Faciale (vecteur de descripteur 128 floats + photo)
  final String? faceEmbedding;
  final String? facePhotoUrl;

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
    this.faceEmbedding,
    this.facePhotoUrl,
    this.heightCm,
    this.weightKg,
    this.birthDate,
    this.level = 1,
    this.deviceInfo,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isActive => status == UserStatus.active;
  bool get isSuspended => status == UserStatus.suspended;
  bool get hasFaceRegistered =>
      faceEmbedding != null && faceEmbedding!.trim().isNotEmpty;

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
    String? faceEmbedding,
    String? facePhotoUrl,
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
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      facePhotoUrl: facePhotoUrl ?? this.facePhotoUrl,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      birthDate: birthDate ?? this.birthDate,
      level: level ?? this.level,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  Map<String, dynamic> toMap({bool snakeCase = true}) {
    if (snakeCase) {
      return {
        'id': id,
        'full_name': fullName,
        'email': email,
        'avatar_url': avatarUrl,
        'role': role.name,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
        'biometric_fingerprint_enabled': biometricFingerprintEnabled,
        'biometric_face_enabled': biometricFaceEnabled,
        'face_embedding': faceEmbedding,
        'face_photo_url': facePhotoUrl,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'birth_date': birthDate?.toIso8601String(),
        'level': level,
        'device_info': deviceInfo,
      };
    }
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
      'faceEmbedding': faceEmbedding,
      'facePhotoUrl': facePhotoUrl,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'birthDate': birthDate?.toIso8601String(),
      'level': level,
      'deviceInfo': deviceInfo,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      fullName: (map['full_name'] ?? map['fullName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      avatarUrl: (map['avatar_url'] ?? map['avatarUrl']) as String?,
      role: UserRole.fromString((map['role'] ?? 'user').toString()),
      status: UserStatus.fromString((map['status'] ?? 'active').toString()),
      createdAt: DateTime.tryParse(
              (map['created_at'] ?? map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      lastLoginAt: (map['last_login_at'] ?? map['lastLoginAt']) != null
          ? DateTime.tryParse(
              (map['last_login_at'] ?? map['lastLoginAt']).toString())
          : null,
      biometricFingerprintEnabled: (map['biometric_fingerprint_enabled'] ??
              map['biometricFingerprintEnabled']) as bool? ??
          false,
      biometricFaceEnabled: (map['biometric_face_enabled'] ??
              map['biometricFaceEnabled']) as bool? ??
          false,
      faceEmbedding: (map['face_embedding'] ?? map['faceEmbedding']) as String?,
      facePhotoUrl: (map['face_photo_url'] ?? map['facePhotoUrl']) as String?,
      heightCm: (map['height_cm'] ?? map['heightCm']) as int?,
      weightKg: ((map['weight_kg'] ?? map['weightKg']) as num?)?.toDouble(),
      birthDate: (map['birth_date'] ?? map['birthDate']) != null
          ? DateTime.tryParse(
              (map['birth_date'] ?? map['birthDate']).toString())
          : null,
      level: (map['level'] as int?) ?? 1,
      deviceInfo: (map['device_info'] ?? map['deviceInfo']) as String?,
    );
  }
}
