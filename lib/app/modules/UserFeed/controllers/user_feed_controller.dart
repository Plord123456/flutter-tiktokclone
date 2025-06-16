import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/video_model.dart';
import '../../home/controllers/home_controller.dart';

class UserFeedController extends GetxController {
  // Dữ liệu được truyền vào từ trang Profile
  final String userId;
  final List<Video> initialVideos;
  final int initialIndex;

  UserFeedController({
    required this.userId,
    required this.initialVideos,
    required this.initialIndex,
  });

  final supabase = Supabase.instance.client;
  final HomeController homeController = Get.find<HomeController>(); // Tìm HomeController đã có

  late final PageController pageController;
  final RxList<Video> videos = <Video>[].obs;
  final count = 0.obs;

  // State cho việc tải thêm
  var isLoadingMore = false.obs;
  var hasMoreVideos = true.obs;
  var currentPage = 0;
  final pageSize = 12;
  @override
  void onInit() {
    super.onInit();
    // Khởi tạo danh sách video ban đầu
    videos.assignAll(initialVideos);
    // Khởi tạo PageController để bắt đầu từ đúng video đã được nhấn
    pageController = PageController(initialPage: initialIndex);
    // Tính toán trang hiện tại dựa trên số video đã có
    currentPage = (videos.length / pageSize).ceil();
  }

  @override
  void onReady() {
    super.onReady();
  }
  // user_feed_controller.dart (Tối ưu)
  Future<void> loadMoreVideos() async {
    if (isLoadingMore.value || !hasMoreVideos.value) return;
    isLoadingMore.value = true;
    try {
      final from = currentPage * pageSize;
      final to = from + pageSize - 1;
      final response = await supabase.rpc(
        'get_videos_for_user',
        params: {
          'p_profile_id': userId,
          'p_current_user_id': supabase.auth.currentUser?.id,
        },
      ).range(from, to);

      if (response.isNotEmpty) {
        final newVideos = (response as List)
            .map((json) => Video.fromJson(json))
            .toList();
        videos.addAll(newVideos);
        currentPage++;
      } else {
        hasMoreVideos.value = false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load more videos: ${e.toString()}');
    } finally {
      isLoadingMore.value = false;
    }
  }
  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
}
