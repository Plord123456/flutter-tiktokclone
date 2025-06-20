import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/services/follow_service.dart';
import '../../../../services/auth_service.dart';
import '../../../data/models/video_model.dart';
import '../../home/controllers/home_controller.dart';

class VideoUserController extends GetxController {
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();
  final authService = Get.find<AuthService>();
  late final ScrollController scrollController;

  // --- State cho màn hình profile ---
  final Rx<String> profileUserId = ''.obs;
  final Rxn<Profile> userProfile = Rxn<Profile>();
  final RxList<Video> userVideos = <Video>[].obs;
  bool get isFollowing => followService.isFollowing(profileUserId.value);

  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreVideos = true.obs;
  final int _pageSize = 12;

  DateTime? _lastVideoTimestamp;

  String get currentUserId => authService.currentUserId;
  bool get isMyProfile => currentUserId == profileUserId.value;

  @override
  void onInit() {
    super.onInit();

    // Bạn đã làm rất tốt việc kiểm tra arguments ở đây!
    if (Get.arguments != null && Get.arguments is String) {
      profileUserId.value = Get.arguments as String;
      print("🚀 onInit: VideoUserController được khởi tạo với ID: ${profileUserId.value}");
      // Các logic sau đó của bạn đã đúng, giữ nguyên
      scrollController = ScrollController();
      scrollController.addListener(() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 300) {
          loadMoreUserVideos();
        }
      });
      fetchData();
    } else {
      // Phần xử lý lỗi này của bạn đã rất tốt
      print("LỖI: VideoUserController được gọi mà không có profileId hợp lệ.");
      isLoading.value = false;

      Get.snackbar(
        'Lỗi nghiêm trọng',
        'Không thể xác định người dùng. Vui lòng thử lại.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      Future.delayed(const Duration(seconds: 2), () => Get.back());
    }
  }
  @override
  void onClose() {
    print("❌ onClose: VideoUserController đang được dọn dẹp!");
    scrollController.dispose();
    super.onClose();
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

  Future<void> loadMoreUserVideos() async {
    await fetchUserVideos(isRefresh: false);
  }

  Future<void> fetchUserProfile() async {
    if (profileUserId.value.isEmpty) {
      userProfile.value = null;
      return;
    }
    try {
      final response = await supabase
          .from('profiles')
          .select('*, '
          'follower_count:follows!follower_id(count), '
          'following_count:follows!following_id(count), '
          'post_count:videos!videos_user_id_fkey(count)')
          .eq('id', profileUserId.value)
          .maybeSingle();

      userProfile.value = response == null ? null : Profile.fromJson(response, currentUserId:
      currentUserId);
    } catch (e) {
      print("Lỗi trong fetchUserProfile: $e");
      userProfile.value = null;
    }
  }

  Future<void> fetchUserVideos({required bool isRefresh}) async {
    if (isLoadingMore.value || (!isRefresh && !hasMoreVideos.value)) return;

    if (isRefresh) {
      hasMoreVideos.value = true;
      _lastVideoTimestamp = null;
    }

    if (!isRefresh) isLoadingMore.value = true;

    try {
      var query = supabase.from('videos').select('''
        id, video_url, title, thumbnail_url, created_at,
        profiles!videos_user_id_fkey(id, username, avatar_url, full_name),
        likes_count:likes(count), 
        comments_count:comments(count)
      ''');

      // ✅ BƯỚC 1: ÁP DỤNG TẤT CẢ CÁC BỘ LỌC (FILTERING)
      query = query.eq('user_id', profileUserId.value);

      if (!isRefresh && _lastVideoTimestamp != null) {
        query = query.lt('created_at', _lastVideoTimestamp!.toIso8601String());
      }

      // ✅ BƯỚC 2: ÁP DỤNG CÁC BIẾN ĐỔI (TRANSFORMING)
      final response = await query
          .order('created_at', ascending: false)
          .limit(_pageSize);

      final newVideos = response
          .map((json) => Video.fromSupabase(
        json,
        currentUserId: currentUserId,
        isFollowed: followService.isFollowing(profileUserId.value),
      ))
          .toList();

      if (isRefresh) {
        userVideos.assignAll(newVideos);
      } else {
        userVideos.addAll(newVideos);
      }

      if (newVideos.length < _pageSize) {
        hasMoreVideos.value = false;
      }
      if (newVideos.isNotEmpty) {
        _lastVideoTimestamp = newVideos.last.createdAt;
      }
    } catch (e) {
      print("Lỗi trong fetchUserVideos: $e");
    } finally {
      if (!isRefresh) isLoadingMore.value = false;
    }
  }

  void toggleFollow() {
    if (profileUserId.value.isNotEmpty && !isMyProfile) {
      followService.toggleFollow(profileUserId.value);
    }
  }

  Future<void> deleteVideo(String videoId, String videoUrl) async {
    if (!isMyProfile) {
      Get.snackbar('Lỗi', 'Bạn không có quyền xóa video này');
      return;
    }
    try {
      userVideos.removeWhere((video) => video.id == videoId);
      userProfile.value?.postCount.value--;
      await supabase.from('videos').delete().eq('id', videoId);
      final videoPath = Uri.parse(videoUrl).pathSegments.sublist(2).join('/');
      await supabase.storage.from('videos').remove([videoPath]);
      Get.snackbar('Thành công', 'Đã xóa video.');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa video, vui lòng thử lại.');
      fetchData();
    }

  }
}