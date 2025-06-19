
import 'package:get/get.dart';
import 'package:tiktok_clone/app/modules/login/controllers/login_controller.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/chat_service.dart';
import 'package:tiktok_clone/services/follow_service.dart';

/// Lớp này sẽ chịu trách nhiệm khởi tạo tất cả các service và controller
/// cần thiết cho toàn bộ ứng dụng ngay từ đầu.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => FollowService(), fenix: true);
    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut(() => ChatService(), fenix: true);
  }
}