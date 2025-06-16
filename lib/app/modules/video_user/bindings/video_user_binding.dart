import 'package:get/get.dart';

import '../controllers/video_user_controller.dart';

class VideoUserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoUserController>(
      () => VideoUserController(),
    );
  }
}
