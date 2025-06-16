
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/auth_service.dart';

class LoginController extends GetxController {
  final authService = Get.find<AuthService>();

  User? get user => authService.currentUser;

  get isReady => null;

  // Không cần onInit, onClose hay StreamSubscription nữa.

  Future<void> login() async {
    await authService.loginWithGoogle();
  }

  Future<void> logout() async {
    await authService.signOut();
    // Điều hướng về trang login sẽ được AuthMiddleware xử lý tự động.
  }
}