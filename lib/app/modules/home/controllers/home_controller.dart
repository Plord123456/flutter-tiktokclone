import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/follow_service.dart';

class HomeController extends GetxController {
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();
  final authService = Get.find<AuthService>();
  final _likingInProgress = <String>{}.obs;
  final videoList = <Video>[].obs;
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

      // ✅ FIX: Chỉ định rõ mối quan hệ join để tránh lỗi
      final response = await supabase.from('videos').select('''
        id, video_url, title, thumbnail_url, user_id, created_at,
        profiles!videos_user_id_fkey(*), 
        likes(user_id),
        comments_count:comments(count)
      ''').order('created_at', ascending: false).range(from, to);

      final List<Video> newVideos = [];
      final Map<String, Profile> newProfiles = {};

      for (final item in response) {
        final profileData = item['profiles'];
        if (profileData == null) continue;

        final profile = Profile.fromJson(profileData);
        newProfiles[profile.id] = profile;

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

  void toggleLike(String videoId) async {
    // Nếu video đã đang được xử lý, không làm gì cả
    if (_likingInProgress.contains(videoId)) return;

    final video = videoList.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;

    // Thêm video vào danh sách đang xử lý
    _likingInProgress.add(videoId);

    final isCurrentlyLiked = video.isLikedByCurrentUser.value;
    video.isLikedByCurrentUser.toggle();
    video.likeCount.value += isCurrentlyLiked ? -1 : 1;

    try {
      if (isCurrentlyLiked) {
        await supabase.from('likes').delete().match({'video_id': videoId, 'user_id': currentUserId});
      } else {
        await supabase.from('likes').insert({'video_id': videoId, 'user_id': currentUserId});
      }
    } catch (e) {
      // Khôi phục trạng thái nếu có lỗi
      video.isLikedByCurrentUser.toggle();
      video.likeCount.value += isCurrentlyLiked ? 1 : -1;
      // In ra lỗi để debug
      print('Lỗi khi toggle like: $e');
    } finally {
      // Luôn xóa video khỏi danh sách đang xử lý sau khi hoàn tất
      _likingInProgress.remove(videoId);
    }
  }

  void toggleFollow(String userIdToFollow) {
    followService.toggleFollow(userIdToFollow);
  }
}