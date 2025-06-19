import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
// Trong file app/modules/login/views/login_view.dart

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ BỌC TOÀN BỘ SCAFFOLD TRONG OBX
    return Obx(() => Stack(
      children: [
        // Giao diện gốc của bạn
        Scaffold(
          appBar: AppBar(
            title: const Text('Đăng nhập'),
          ),
          body: Center(
            child: ElevatedButton(
              // ✅ GỌI ĐÚNG HÀM TRONG LOGINCONTROLLER
              onPressed: controller.isLoading.value ? null : controller.signInWithGoogle,
              child: const Text('Đăng nhập với Google'),
            ),
          ),
        ),

        // ✅ LỚP PHỦ LOADING
        // Nếu đang tải thì hiển thị, không thì ẩn đi
        if (controller.isLoading.value)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5), // Lớp mờ
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    ));
  }
}