import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/app/modules/home/controllers/home_controller.dart';
import 'package:tiktok_clone/services/follow_service.dart';

class UserFeedController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxList<Video> videos = <Video>[].obs;
  late PageController pageController;
  final int initialIndex;

  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreVideos = true.obs;
  final int _pageSize = 5;

  UserFeedController({required List<Video> initialVideos, required this.initialIndex}) {
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
    if (videos.isEmpty || isLoadingMore.value || !hasMoreVideos.value) return;

    isLoadingMore.value = true;

    try {
      final lastVideoCreatedAt = videos.last.createdAt;
      final userId = videos.first.postedById;

      // ✅ SỬA LỖI: Chỉ định rõ cách join với bảng profiles
      final response = await supabase
          .from('videos')
          .select('''
            id, video_url, title, thumbnail_url, user_id, created_at,
            profiles!videos_user_id_fkey(id, username, avatar_url),
            likes(user_id),
            comments_count:comments(count)
          ''')
          .eq('user_id', userId)
          .lt('created_at', lastVideoCreatedAt.toIso8601String())
          .order('created_at', ascending: true)
          .limit(_pageSize);

      // ✅ SỬA LỖI: Tái sử dụng logic map từ HomeController
      final homeController = Get.find<HomeController>();
      final newVideos = homeController.mapVideoResponse(response, Get.find<FollowService>().followedUserIds);

      if (newVideos.length < _pageSize) {
        hasMoreVideos.value = false;
      }

      videos.addAll(newVideos);
    } catch (e) {
      print('Failed to load more videos: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }
}
