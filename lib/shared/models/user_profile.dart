class UserProfile {
  final String id;
  final String email;
  final String nama;
  final String role; // 'Admin', 'Staff Gudang', 'Manager'
  final String status; // 'active', 'inactive'

  UserProfile({
    required this.id,
    required this.email,
    required this.nama,
    required this.role,
    this.status = 'active',
  });

  bool get isAdmin => role == 'Admin';
  bool get isStaff => role == 'Staff Gudang';
  bool get isManager => role == 'Manager';
  bool get canManageUsers => isAdmin;
  bool get canCreateTransaction => isAdmin || isStaff;
  bool get canApprove => isAdmin || isManager;
  bool get canManageMasterData => isAdmin;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      nama: json['nama'] as String? ?? 'Pengguna',
      role: json['role'] as String? ?? 'Staff Gudang',
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nama': nama,
      'role': role,
      'status': status,
    };
  }

  UserProfile copyWith({
    String? email,
    String? nama,
    String? role,
    String? status,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      nama: nama ?? this.nama,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }
}

