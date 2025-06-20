import 'package:get/get.dart';

import '../controllers/user_feed_controller.dart';

class UserFeedBinding extends Bindings {
  @override
  void dependencies() {
    final Map<String, dynamic> args = Get.arguments is Map<String, dynamic>
        ? Get.arguments as Map<String, dynamic>
        : {};

    Get.lazyPut<UserFeedController>(() => UserFeedController(
      initialVideos: args['initialVideos'],
      initialIndex: args['initialIndex'],
    ));
  }
}
