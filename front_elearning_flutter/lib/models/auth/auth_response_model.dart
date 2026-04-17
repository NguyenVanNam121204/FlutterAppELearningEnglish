import '../user/user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel? user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = (json['data'] as Map<String, dynamic>?) ?? json;
    final userJson = payload['user'] as Map<String, dynamic>?;

    return AuthResponseModel(
      accessToken: (payload['accessToken'] ?? payload['AccessToken'] ?? '')
          .toString(),
      refreshToken: (payload['refreshToken'] ?? payload['RefreshToken'] ?? '')
          .toString(),
      user: userJson == null ? null : UserModel.fromJson(userJson),
    );
  }
}
