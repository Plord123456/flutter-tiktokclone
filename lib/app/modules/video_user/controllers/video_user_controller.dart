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
  final RxList<Video> userVideos = <Video>[].obs; // Giữ tên này để rõ ràng
  final RxBool isFollowing = false.obs;

  final RxBool isLoading = true.obs; // Một biến loading chính

  // ✅ SỬA LỖI: Thêm các biến còn thiếu để quản lý tải thêm video
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreVideos = true.obs;
  final int _pageSize = 12; // Tăng pagesize cho grid view

  String get currentUserId => supabase.auth.currentUser?.id ?? '';
  bool get isMyProfile => currentUserId == profileUserId.value;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;
    profileUserId.value = arguments?['userId'] ?? currentUserId;

    // Lắng nghe thay đổi trạng thái follow từ service
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
    // Ngăn việc gọi API trùng lặp
    if (isLoading.value || isLoadingMore.value || !hasMoreVideos.value) return;

    isLoadingMore.value = true;

    try {
      final from = userVideos.length;
      final to = from + _pageSize - 1;

      // ✅ SỬA LỖI: Chỉ định rõ cách join với bảng profiles để tránh lỗi
      final response = await supabase
          .from('videos')
          .select('id, thumbnail_url, user_id, video_url, title, created_at, profiles!inner(id, username, avatar_url)')
          .eq('user_id', profileUserId.value)
          .order('created_at', ascending: false)
          .range(from, to);

      // Không cần map phức tạp ở đây vì chúng ta không cần thông tin like/follow trong grid
      final newVideos = response.map((e) => Video.fromJson(e)).toList();

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
    // Logic xóa video
  }
}
