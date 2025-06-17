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

  /// ✅ HÀM LOADMOREVIDEOS ĐÃ ĐƯỢC HOÀN THIỆN

  Future<void> loadMoreVideos() async {
    // 1. Các điều kiện kiểm tra vẫn giữ nguyên ở ngoài
    if (videos.isEmpty || isLoadingMore.value || !hasMoreVideos.value) {
      return;
    }

    // 2. Toàn bộ logic gọi API và CẬP NHẬT STATE phải nằm bên trong callback này
    // Nó sẽ trì hoãn việc thực thi cho đến khi frame hiện tại được vẽ xong.
    Future.delayed(Duration.zero, () async {

      // Kiểm tra lại lần nữa bên trong callback cho an toàn
      if (isLoadingMore.value) return;

      isLoadingMore.value = true;

      try {
        final lastVideo = videos.last;
        final userId = lastVideo.author.id;

        final response = await supabase
            .from('videos')
            .select('''
            id, video_url, title, thumbnail_url, created_at,
            profiles!videos_user_id_fkey(id, username, avatar_url, full_name),
            likes(user_id),
            comments_count:comments(count)
          ''')
            .eq('user_id', userId)
            .lt('created_at', lastVideo.createdAt.toIso8601String())
            .order('created_at', ascending: false)
            .limit(_pageSize);

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
    });
  }
}