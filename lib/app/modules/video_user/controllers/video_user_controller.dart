import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/services/follow_service.dart';
import '../../../data/models/video_model.dart';
import '../../home/controllers/home_controller.dart';

class VideoUserController extends GetxController {
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();

  final Rx<String> profileUserId = ''.obs;
  final Rxn<Profile> userProfile = Rxn<Profile>();
  final RxList<Video> userVideos = <Video>[].obs;
  final RxBool isFollowing = false.obs;

  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreVideos = true.obs;
  final int _pageSize = 12;

  String get currentUserId => supabase.auth.currentUser?.id ?? '';
  bool get isMyProfile => currentUserId == profileUserId.value;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;
    profileUserId.value = arguments?['userId'] ?? currentUserId;

    followService.followedUserIds.listen((followedIds) {
      isFollowing.value = followedIds.contains(profileUserId.value);
    });

    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchUserProfile(),
        fetchUserVideos(isRefresh: true),
      ]);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu người dùng: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserProfile() async {
    if (profileUserId.value.isEmpty) return;
    try {
      final response = await supabase
          .from('profiles')
          .select('*, follower_count:follows!follower_id(count), following_count:follows!following_id(count), post_count:videos(count)')
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
    if (isLoading.value || isLoadingMore.value || !hasMoreVideos.value) return;

    isLoadingMore.value = true;

    try {
      final from = userVideos.length;
      final to = from + _pageSize - 1;

      // ✅ SỬA LỖI: Chỉ định rõ cách join với bảng profiles
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

      // ✅ SỬA LỖI: Tái sử dụng logic map từ HomeController
      final homeController = Get.find<HomeController>();
      final newVideos = homeController.mapVideoResponse(response, followService.followedUserIds);

      if (newVideos.length < _pageSize) {
        hasMoreVideos.value = false;
      }

      userVideos.addAll(newVideos);

    } catch (e) {
      print("Lỗi trong fetchUserVideos: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  void toggleFollow() {
    if (profileUserId.value.isNotEmpty && !isMyProfile) {
      followService.toggleFollow(profileUserId.value);
    }
  }

  Future<void> deleteVideo(String videoId, String videoUrl) async {
    if (videoId.isEmpty || videoUrl.isEmpty) {
      Get.snackbar('Lỗi', 'ID video hoặc URL không hợp lệ');
      return;
    }
    if (isMyProfile) {
      try {
        await supabase.from('videos').delete().eq('id', videoId);
        userVideos.removeWhere((video) => video.id == videoId);
        Get.snackbar('Thành công', 'Đã xóa video');
      } catch (e) {
        Get.snackbar('Lỗi', 'Không thể xóa video: ${e.toString()}');
      }
    } else {
      Get.snackbar('Lỗi', 'Bạn không có quyền xóa video này');
    }
  }
}
