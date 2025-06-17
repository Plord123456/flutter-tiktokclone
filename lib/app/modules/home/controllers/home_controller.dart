import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import các model và service cần thiết
import '../../../../services/auth_service.dart';
import '../../../../services/follow_service.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/video_model.dart';

class HomeController extends GetxController {
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();
  final authService = Get.find<AuthService>();

  // --- State Variables ---
  final videoList = <Video>[].obs;
  // Map để cache các profile của user, giúp UI reactive
  final RxMap<String, Profile> userProfiles = <String, Profile>{}.obs;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMoreVideos = true.obs;
  final _videoPageSize = 5;

  String get currentUserId => authService.currentUserId;

  @override
  void onInit() {
    super.onInit();
    initialLoad();
  }

  Future<void> initialLoad() async {
    isLoading.value = true;
    try {
      await fetchVideos(refresh: true);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu ban đầu: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreVideos() async {
    if (isLoadingMore.value || !hasMoreVideos.value) return;
    isLoadingMore.value = true;
    try {
      await fetchVideos(refresh: false);
    } catch (e) {
      print('Lỗi khi tải thêm video: ${e.toString()}');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchVideos({required bool refresh}) async {
    if (refresh) {
      hasMoreVideos.value = true;
    }

    try {
      final from = refresh ? 0 : videoList.length;
      final to = from + _videoPageSize - 1;

      // ✅ FIX: Chỉ định rõ mối quan hệ cần dùng để join bảng `profiles`
      final response = await supabase.from('videos').select('''
        id, video_url, title, thumbnail_url, user_id, created_at,
        profiles!videos_user_id_fkey(id, username, avatar_url, full_name), 
        likes(user_id),
        comments_count:comments(count)
      ''').order('created_at', ascending: false).range(from, to);

      final List<Video> newVideos = [];
      final Map<String, Profile> newProfiles = {};

      for (final item in response) {
        final profileData = item['profiles'];
        if (profileData == null) continue;

        // Tạo và cache Profile object
        final profile = Profile.fromJson(profileData);
        newProfiles[profile.id] = profile;

        // Tạo Video object
        final video = Video.fromSupabase(
          item,
          currentUserId: currentUserId,
          isFollowed: followService.isFollowing(profile.id),
        );
        newVideos.add(video);
      }

      if (refresh) {
        videoList.assignAll(newVideos);
        userProfiles.assignAll(newProfiles);
      } else {
        videoList.addAll(newVideos);
        userProfiles.addAll(newProfiles);
      }

      if (newVideos.length < _videoPageSize) {
        hasMoreVideos.value = false;
      }

    } catch (e) {
      print('Lỗi khi tải videos: ${e.toString()}');
      if (refresh) rethrow;
    }
  }
  Future<void> toggleLike(String videoId) async {
    if (currentUserId.isEmpty) return;
    final video = videoList.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;

    final isCurrentlyLiked = video.isLikedByCurrentUser.value;
    // Optimistic UI update
    video.isLikedByCurrentUser.value = !isCurrentlyLiked;
    video.likeCount.value += isCurrentlyLiked ? -1 : 1;

    try {
      if (isCurrentlyLiked) {
        await supabase.from('likes').delete().match({'video_id': videoId, 'user_id': currentUserId});
      } else {
        await supabase.from('likes').insert({'video_id': videoId, 'user_id': currentUserId});
      }
    } catch (e) {
      // Rollback on error
      video.isLikedByCurrentUser.value = isCurrentlyLiked;
      video.likeCount.value += isCurrentlyLiked ? 1 : -1;
      Get.snackbar('Lỗi', 'Không thể cập nhật lượt thích.');
    }
  }

  void toggleFollow(String userId) {
    followService.toggleFollow(userId);
  }
}