import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/follow_service.dart';
import '../../../data/models/comments_model.dart'; // Đảm bảo import đúng
import '../../../data/models/profile_model.dart';
import '../../../data/models/video_model.dart';

class HomeController extends GetxController {
  final supabase = Supabase.instance.client;
  final Rxn<Profile> currentUser = Rxn<Profile>();
  final videoList = <Video>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  var canLoadMoreVideos = true.obs;
  final _videoPageSize = 5;
  final followService = Get.find<FollowService>();

  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    initialLoad();
  }

  Future<void> initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchCurrentUserProfile(),
        fetchVideos(refresh: true),
      ]);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCurrentUserProfile() async {
    if (currentUserId.isEmpty) return;
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUserId)
          .single();
      currentUser.value = Profile.fromJson(data);
    } catch (e) {
      print('Lỗi khi tải profile người dùng: $e');
    }
  }

  Future<void> fetchVideos({bool refresh = false}) async {
    if (refresh) {
      videoList.clear();
      canLoadMoreVideos.value = true;
    }

    if (isLoadingMore.value || !canLoadMoreVideos.value) return;

    if (!refresh) isLoadingMore.value = true;

    try {
      final from = videoList.length;
      final to = from + _videoPageSize - 1;

      // ✅ SỬA LỖI: Chỉ định rõ mối quan hệ cần dùng để join bảng `profiles`
      final response = await supabase
          .from('videos')
          .select('''
            id, video_url, title, thumbnail_url, user_id, created_at,
            profiles!videos_user_id_fkey(id, username, avatar_url),
            likes(user_id),
            comments_count:comments(count)
          ''')
          .order('created_at', ascending: false)
          .range(from, to);

      final followedUserIds = followService.followedUserIds;
      final newVideos = mapVideoResponse(response, followedUserIds);

      if (refresh) {
        videoList.assignAll(newVideos);
      } else {
        videoList.addAll(newVideos);
      }
      canLoadMoreVideos.value = newVideos.length >= _videoPageSize;

    } catch (e) {
      print('Lỗi khi tải videos: ${e.toString()}');
      if (refresh) rethrow;
    } finally {
      if (!refresh) isLoadingMore.value = false;
    }
  }

  // ✅ CẢI TIẾN: Chuyển hàm này thành public để các controller khác có thể dùng
  List<Video> mapVideoResponse(List<Map<String, dynamic>> response, RxSet<String> followedUserIds) {
    return response.map((item) {
      final profile = item['profiles'];
      if (profile == null) return null;

      final likes = item['likes'] as List;
      final commentsCountList = item['comments_count'] as List;
      final commentsCount = commentsCountList.isNotEmpty ? commentsCountList.first['count'] as int? ?? 0 : 0;
      final isLiked = likes.any((like) => like['user_id'] == currentUserId);

      // Tạo một map mới để truyền vào fromJson của Video model
      // để đảm bảo tất cả các trường cần thiết đều có mặt.
      final videoData = {
        ...item,
        // fromJson sẽ tìm các key này để khởi tạo Rx values
        'initialLikeCount': likes.length,
        'initialCommentCount': commentsCount,
        'initialIsLiked': isLiked,
        'initialIsFollowed': followedUserIds.contains(item['user_id']),
      };

      return Video.fromJson(videoData);
    }).whereType<Video>().toList();
  }

  Future<void> toggleLike(String videoId) async {
    if (currentUserId.isEmpty) return;
    final video = videoList.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;

    final isCurrentlyLiked = video.isLikedByCurrentUser.value;
    video.isLikedByCurrentUser.value = !isCurrentlyLiked;
    video.likeCount.value += isCurrentlyLiked ? -1 : 1;

    try {
      if (isCurrentlyLiked) {
        await supabase.from('likes').delete().match({'video_id': videoId, 'user_id': currentUserId});
      } else {
        await supabase.from('likes').insert({'video_id': videoId, 'user_id': currentUserId});
      }
    } catch (e) {
      video.isLikedByCurrentUser.value = isCurrentlyLiked;
      video.likeCount.value += isCurrentlyLiked ? 1 : -1;
      Get.snackbar('Lỗi', 'Không thể cập nhật lượt thích.');
    }
  }

  void toggleFollow(String userId) {
    followService.toggleFollow(userId);
  }
}
