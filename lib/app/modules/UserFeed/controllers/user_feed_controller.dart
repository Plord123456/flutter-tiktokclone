import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/services/follow_service.dart';
import '../../../data/models/video_model.dart';

class VideoUserController extends GetxController {
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();

  final Rx<String> profileUserId = ''.obs;
  final Rxn<Profile> userProfile = Rxn<Profile>();
  final RxList<Video> userVideos = <Video>[].obs; // Đổi tên để rõ ràng hơn
  final RxBool isFollowing = false.obs;

  final RxBool isProfileLoading = true.obs;
  final RxBool isVideosLoading = true.obs;

  // ✅ SỬA LỖI: Thêm các biến còn thiếu để quản lý tải thêm
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreVideos = true.obs;
  final int _pageSize = 10;

  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;
    profileUserId.value = arguments?['userId'] ?? currentUserId;
    isFollowing.value = followService.isFollowing(profileUserId.value);
    fetchData();
  }

  Future<void> fetchData() async {
    isProfileLoading.value = true;
    isVideosLoading.value = true;
    try {
      await Future.wait([
        fetchUserProfile(),
        fetchUserVideos(isRefresh: true), // Gọi với isRefresh
      ]);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu người dùng: ${e.toString()}');
    } finally {
      isProfileLoading.value = false;
      isVideosLoading.value = false;
    }
  }

  Future<void> fetchUserProfile() async {
    if (profileUserId.value.isEmpty) return;
    try {
      final response = await supabase
          .from('profiles')
          .select('*, follower_count:follows!follower_id(count), following_count:follows!following_id(count)')
          .eq('id', profileUserId.value)
          .single();
      userProfile.value = Profile.fromJson(response);
    } catch (e) {
      print("Lỗi trong fetchUserProfile: $e");
    }
  }

  Future<void> fetchUserVideos({bool isRefresh = false}) async {
    if (isRefresh) {
      userVideos.clear();
      hasMoreVideos.value = true;
    }
    if (!hasMoreVideos.value || isLoadingMore.value) return;

    if (isRefresh) isVideosLoading.value = true;
    isLoadingMore.value = true;

    try {
      final from = isRefresh ? 0 : userVideos.length;
      final to = from + _pageSize -1;

      // ✅ SỬA LỖI: Chỉ định rõ cách join với bảng profiles để tránh lỗi
      final response = await supabase
          .from('videos')
          .select('''
            id, video_url, title, thumbnail_url, user_id, created_at,
            profiles!videos_user_id_fkey(id, username, avatar_url),
            likes(user_id),
            comments_count:comments(count)
          ''')
          .eq('user_id', profileUserId.value)
          .order('created_at', ascending: false)
          .range(from, to);

      final newVideos = _mapVideoResponse(response, followService.followedUserIds);

      if (newVideos.length < _pageSize) {
        hasMoreVideos.value = false;
      }

      if(isRefresh){
        userVideos.assignAll(newVideos);
      } else {
        userVideos.addAll(newVideos);
      }

    } catch (e) {
      print("Lỗi trong fetchUserVideos: $e");
    } finally {
      if (isRefresh) isVideosLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ✅ SỬA LỖI: Sao chép logic map vào đây để controller tự hoạt động
  List<Video> _mapVideoResponse(List<Map<String, dynamic>> response, Set<String> followedUserIds) {
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
      );
    }).whereType<Video>().toList();
  }

  void toggleFollow() {
    if (profileUserId.value.isNotEmpty) {
      followService.toggleFollow(profileUserId.value);
      isFollowing.value = followService.isFollowing(profileUserId.value);
    }
  }
}
