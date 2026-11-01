import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthController {
  final AuthRepository _repository;

  AuthController({required AuthRepository repository}) : _repository = repository;

  Stream<UserModel?> get authStateChanges => _repository.authStateChanges;
  UserModel? get currentUser => _repository.currentUser;
  bool get isAuthenticated => _repository.isAuthenticated;

  Future<UserModel> login({required String email, required String password}) async {
    return await _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _repository.signOut();
  }
}
