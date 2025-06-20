// lib/app/modules/UserFeed/bindings/user_feed_binding.dart
import 'package:get/get.dart';

import '../../../data/models/video_model.dart';
import '../controllers/user_feed_controller.dart';

class UserFeedBinding extends Bindings {
  @override
  void dependencies() {
    // Lấy arguments một cách an toàn
    final Map<String, dynamic> args = Get.arguments is Map<String, dynamic>
        ? Get.arguments as Map<String, dynamic>
        : {};


    final List<Video> initialVideos = (args['initialVideos'] is List)
        ? List<Video>.from(args['initialVideos'])
        : <Video>[];

    // Xử lý 'initialIndex' một cách an toàn
    final int initialIndex = args['initialIndex'] is int
        ? args['initialIndex'] as int
        : 0; // Mặc định là 0 nếu không có

    // Khởi tạo controller với dữ liệu đã được xử lý an toàn
    Get.lazyPut<UserFeedController>(() => UserFeedController(
      initialVideos: initialVideos,
      initialIndex: initialIndex,
    ));
  }
}