// Trong file app/modules/login/controllers/login_controller.dart

import 'package:get/get.dart';
import 'package:tiktok_clone/services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService authService = Get.find<AuthService>();

  // ✅ BƯỚC 1: THÊM BIẾN TRẠNG THÁI LOADING
  final isLoading = false.obs;

  // ✅ BƯỚC 2: TẠO HÀM RIÊNG ĐỂ XỬ LÝ VIỆC ĐĂNG NHẬP
  Future<void> signInWithGoogle() async {
    // Bắt đầu quá trình, hiển thị loading
    isLoading.value = true;
    try {
      // Gọi đến AuthService để thực hiện đăng nhập
      await authService.loginWithGoogle();
      // AuthService sẽ tự động điều hướng nếu thành công
    } catch (e) {
      // Nếu có lỗi, hiển thị thông báo
      Get.snackbar('Lỗi Đăng Nhập', e.toString());
    } finally {
      // Luôn tắt loading sau khi quá trình kết thúc (dù thành công hay thất bại)
      isLoading.value = false;
    }
  }
}