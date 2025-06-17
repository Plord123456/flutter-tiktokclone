import 'package:get/get.dart';

import '../controllers/user_feed_controller.dart';

class UserFeedBinding extends Bindings {
  @override
  void dependencies() {
    final Map<String, dynamic> args = Get.arguments;

    Get.lazyPut<UserFeedController>(() => UserFeedController(

      initialVideos: args['initialVideos'],
      initialIndex: args['initialIndex'],
    ));
  }
}
