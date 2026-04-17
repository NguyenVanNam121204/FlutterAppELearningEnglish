class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.role,
    this.roles = const [],
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? role;
  final List<String> roles;
  final String? avatarUrl;

  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    final combined = '$f $l'.trim();
    if (combined.isNotEmpty) return combined;
    return email;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstName'] ?? json['FirstName'] ?? '').toString();
    final lastName = (json['lastName'] ?? json['LastName'] ?? '').toString();
    final fullName = '$firstName $lastName'.trim();
    final displayName = (json['displayName'] ?? json['DisplayName'] ?? '')
        .toString();

    return UserModel(
      id: (json['id'] ?? json['Id'] ?? json['userId'] ?? json['UserId'] ?? '')
          .toString(),
      fullName: fullName.isEmpty
          ? (displayName.isEmpty
                ? (json['fullName'] ?? json['FullName'] ?? '').toString()
                : displayName)
          : fullName,
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      firstName: firstName.isEmpty ? null : firstName,
      lastName: lastName.isEmpty ? null : lastName,
      phoneNumber: (json['phoneNumber'] ?? json['PhoneNumber'])?.toString(),
      role: (json['role'] ?? json['Role'])?.toString(),
      roles: _parseRoles(json['roles'] ?? json['Roles']),
      avatarUrl:
          (json['avatarUrl'] ??
                  json['AvatarUrl'] ??
                  json['profilePictureUrl'] ??
                  json['ProfilePictureUrl'])
              ?.toString(),
    );
  }

  static List<String> _parseRoles(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) {
            if (e is String) return e;
            if (e is Map<String, dynamic>) {
              return (e['name'] ?? e['Name'] ?? '').toString();
            }
            return e.toString();
          })
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw];
    }
    return const [];
  }
}
