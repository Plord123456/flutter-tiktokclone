import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';

import '../../home/controllers/home_controller.dart';

class UserFeedController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxList<Video> videos = <Video>[].obs;
  late PageController pageController;
  final int initialIndex;

  UserFeedController({required List<Video> initialVideos, required this.initialIndex, required userId}) {
    videos.assignAll(initialVideos);
  }

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: initialIndex);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> loadMoreVideos() async {
    if (videos.isEmpty) return;
    try {
      final lastVideoId = videos.last.id;
      final userId = videos.first.postedById;

      // ✅ SỬA LỖI: Chỉ định rõ cách join với bảng profiles để tránh lỗi
      final response = await supabase
          .from('videos')
          .select('*, profiles!videos_user_id_fkey(*)')
          .eq('user_id', userId)
          .lt('id', lastVideoId) // Tải các video cũ hơn
          .order('created_at', ascending: true)
          .limit(5);

      final homeController = Get.find<HomeController>();
      final newVideos = homeController. _mapVideoResponse(response, homeController.followService.followedUserIds);

      videos.addAll(newVideos);
    } catch (e) {
      print('Failed to load more videos: $e');
    }
  }
}
