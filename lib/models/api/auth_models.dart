class AuthUser {
  final String token;
  final String role;
  final String email;
  final String displayName;
  final String? restaurantId;

  const AuthUser({
    required this.token,
    required this.role,
    required this.email,
    required this.displayName,
    this.restaurantId,
  });

  AuthUser copyWith({
    String? token,
    String? role,
    String? email,
    String? displayName,
    String? restaurantId,
  }) =>
      AuthUser(
        token: token ?? this.token,
        role: role ?? this.role,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        restaurantId: restaurantId ?? this.restaurantId,
      );
}

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? restaurantId;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.restaurantId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        displayName: (json['displayName'] ?? json['name'] ?? json['email'] ?? '').toString(),
        role: json['role']?.toString() ?? '',
        restaurantId: (json['restaurantId'] ??
                (json['restaurant'] is Map ? json['restaurant']['id'] : null))
            ?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'role': role,
        'restaurantId': restaurantId,
      };
}
