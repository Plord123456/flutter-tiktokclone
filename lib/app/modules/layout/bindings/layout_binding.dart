import 'package:get/get.dart';
import 'package:tiktok_clone/app/modules/profile/controllers/profile_controller.dart';

import '../../../../services/media_service.dart';
import '../../UserFeed/controllers/user_feed_controller.dart';
import '../../chat_list/controllers/chat_list_controller.dart';
import '../../comment_sheet/comment_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../login/controllers/login_controller.dart';
import '../../video_user/controllers/video_user_controller.dart';
import '../controllers/layout_controller.dart';

class LayoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LayoutController>(
      () => LayoutController(),
    );

    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<VideoUserController>(() => VideoUserController());
    Get.lazyPut<ChatListController>(() => ChatListController());

  }
}
