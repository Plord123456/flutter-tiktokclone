import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';

import '../../../../services/follow_service.dart';
import '../../../data/models/video_model.dart';

class VideoUserController extends GetxController {
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();

  final Rx<String> profileUserId = ''.obs;
  final Rxn<Profile> userProfile = Rxn<Profile>();
  final RxList<Video> userVideos = <Video>[].obs;
  final RxBool isFollowing = false.obs;

  final RxBool isProfileLoading = true.obs;
  final RxBool isVideosLoading = true.obs;

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
      // Chạy song song để tăng tốc độ tải
      await Future.wait([
        fetchUserProfile(),
        fetchUserVideos(),
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
      userProfile.value = response != null ? Profile.fromJson(response) : null;
    } catch (e) {
      print("Lỗi trong fetchUserProfile: $e");
      userProfile.value = null;
    }
  }

  Future<void> fetchUserVideos() async {
    if (profileUserId.value.isEmpty) return;
    try {
      // ✅ SỬA LỖI: Chỉ định rõ cách join với bảng profiles để tránh lỗi
      final response = await supabase
          .from('videos')
          .select('*, profiles!videos_user_id_fkey(*)')
          .eq('user_id', profileUserId.value)
          .order('created_at', ascending: false);

      // Map dữ liệu một cách an toàn
      userVideos.value = response.map((e) {
        // Cần một hàm map an toàn hơn ở đây. Tạm thời giả định Video.fromJson có thể xử lý.
        // Để tối ưu, bạn nên tạo một hàm map chung giống như trong HomeController.
        return Video.fromJson(e);
      }).toList();

    } catch (e) {
      print("Lỗi trong fetchUserVideos: $e");
    }
  }

  void toggleFollow() {
    if (profileUserId.value.isNotEmpty) {
      followService.toggleFollow(profileUserId.value);
      isFollowing.value = followService.isFollowing(profileUserId.value);
    }
  }
}
