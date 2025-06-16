import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/services/follow_service.dart';

class UserFeedController extends GetxController {
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>(); // Lấy follow service
  final RxList<Video> videos = <Video>[].obs;
  late PageController pageController;
  final int initialIndex;

  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreVideos = true.obs;
  final int _pageSize = 5;

  String get currentUserId => supabase.auth.currentUser?.id ?? '';

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

      // ✅ SỬA LỖI: Chỉ định rõ cách join với bảng profiles để tránh lỗi
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

      final newVideos = _mapVideoResponse(response, followService.followedUserIds);

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

  // ✅ SỬA LỖI: Sao chép logic map vào đây để controller tự hoạt động
  List<Video> _mapVideoResponse(List<Map<String, dynamic>> response, RxSet<String> followedUserIds) {
    return response.map((item) {
      final profile = item['profiles'];
      if (profile == null) return null;

      final likes = item['likes'] as List;
      final commentsCountList = item['comments_count'] as List;
      final commentsCount = commentsCountList.isNotEmpty ? commentsCountList.first['count'] ?? 0 : 0;
      final isLiked = likes.any((like) => like['user_id'] == currentUserId);

      return Video(
        id: item['id'],
        videoUrl: item['video_url'],
        title: item['title'] ?? '',
        thumbnailUrl: item['thumbnail_url'] ?? '',
        username: profile['username'] ?? 'Unknown',
        profilePhoto: profile['avatar_url'] ?? '',
        postedById: item['user_id'],
        initialLikeCount: likes.length,
        initialCommentCount: commentsCount,
        initialIsLiked: isLiked,
        initialIsFollowed: followedUserIds.contains(item['user_id']),
        createdAt: DateTime.tryParse(item['created_at']) ?? DateTime.now(),
      );
    }).whereType<Video>().toList();
  }
}
