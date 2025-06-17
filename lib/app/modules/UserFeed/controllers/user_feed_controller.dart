import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/follow_service.dart';

class UserFeedController extends GetxController {
  final supabase = Supabase.instance.client;
  final authService = Get.find<AuthService>();
  final followService = Get.find<FollowService>();

  final RxList<Video> videos = <Video>[].obs;
  late PageController pageController;
  final int initialIndex;

  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreVideos = true.obs;
  final int _pageSize = 5;

  String get currentUserId => authService.currentUserId;

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

  /// ✅ HÀM LOADMOREVIDEOS ĐÃ ĐƯỢC VIẾT LẠI HOÀN TOÀN VÀ CHÍNH XÁC
  Future<void> loadMoreVideos() async {
    if (videos.isEmpty || isLoadingMore.value || !hasMoreVideos.value) return;

    isLoadingMore.value = true;

    try {
      final lastVideo = videos.last;
      // Lấy userId từ author của video
      final userId = lastVideo.author.id;

      final response = await supabase
          .from('videos')
          .select('''
            id, video_url, title, thumbnail_url, created_at,
            profiles!inner(id, username, avatar_url, full_name),
            likes(user_id),
            comments_count:comments(count)
          ''')
          .eq('user_id', userId)
          .lt('created_at', lastVideo.createdAt.toIso8601String())
          .order('created_at', ascending: false) // Lấy các video mới hơn trước
          .limit(_pageSize);

      // ✅ TỰ MAP DỮ LIỆU, KHÔNG DÙNG HOMECONTROLLER
      final newVideos = response.map((json) => Video.fromSupabase(
          json,
          currentUserId: currentUserId,
          isFollowed: followService.isFollowing(userId)
      )).toList();

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