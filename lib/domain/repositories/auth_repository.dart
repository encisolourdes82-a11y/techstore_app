// lib/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<bool> login(String username, String password);
}