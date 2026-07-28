class ApiRestaurantUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;

  ApiRestaurantUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  factory ApiRestaurantUser.fromJson(Map<String, dynamic> json) {
    final isActive = json['isActive'];
    final status = json['status']?.toString();
    return ApiRestaurantUser(
      id: json['id']?.toString() ?? '',
      name: (json['displayName'] ?? json['name'] ?? '').toString(),
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: status != null && status.isNotEmpty
          ? status
          : (isActive is bool ? (isActive ? 'active' : 'inactive') : ''),
    );
  }
}
