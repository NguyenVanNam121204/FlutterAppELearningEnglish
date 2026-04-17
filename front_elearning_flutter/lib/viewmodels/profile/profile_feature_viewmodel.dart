import '../../core/result/result.dart';
import '../../models/user/user_model.dart';
import '../../repositories/profile/profile_repository.dart';

class ProfileFeatureViewModel {
  ProfileFeatureViewModel(this._repository);

  final ProfileRepository _repository;

  Future<Result<UserModel>> profile() async {
    return _repository.profile();
  }

  Future<Result<UserModel>> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    return _repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );
  }

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<Result<UserModel>> updateAvatar({
    required String filePath,
    required String fileName,
  }) async {
    return _repository.updateAvatar(filePath: filePath, fileName: fileName);
  }
}
