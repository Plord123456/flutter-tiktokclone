import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/follow_service.dart';

class UserFeedController extends GetxController {
  //--- Dependencies ---
  final supabase = Supabase.instance.client;
  final authService = Get.find<AuthService>();
  final followService = Get.find<FollowService>();

  //--- Dữ liệu nhận từ màn hình trước ---
  final List<Video> initialVideos;
  final int initialIndex;

  //--- State (Trạng thái) của Controller ---
  final RxList<Video> videos = <Video>[].obs;
  final RxInt currentVideoIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreVideos = true.obs;

  //--- Các controller và biến nội bộ ---
  late PageController pageController;
  final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};
  final int _pageSize = 5;

  //--- Getters ---
  String get currentUserId => authService.currentUserId;

  //--- Constructor ---
  UserFeedController({
    required this.initialVideos,
    required this.initialIndex,
  });

  //--- Vòng đời (Lifecycle) ---
  @override
  void onInit() {
    super.onInit();
    print("🚀 onInit: UserFeedController được khởi tạo.");
    videos.assignAll(initialVideos);
    currentVideoIndex.value = initialIndex;
    pageController = PageController(initialPage: initialIndex);
    isLoading.value = false;

    // Khởi tạo các video đầu tiên
    _initializeControllerForIndex(initialIndex);
    if (initialIndex + 1 < videos.length) {
      _initializeControllerForIndex(initialIndex + 1);
    }
  }

  @override
  void onClose() {
    print("❌ onClose: UserFeedController đang được dọn dẹp! -- RẤT QUAN TRỌNG");
    pageController.dispose();
    onPause(); // Gọi onPause để đảm bảo tất cả video players được giải phóng
    super.onClose();
  }
  //--- Logic chính ---

  void onPageChanged(int index) {
    final oldController = _videoControllers[currentVideoIndex.value];
    if (oldController != null && oldController.value.isPlaying) {
      oldController.pause();
    }
    currentVideoIndex.value = index;
    final newController = _videoControllers[index];
    if (newController != null && newController.value.isInitialized) {
      newController.play();
    } else {
      _initializeControllerForIndex(index);
    }
    _initializeControllerForIndex(index + 1);
    _disposeControllerIfExist(index - 2);
  }

  Future<void> loadMoreVideos() async {
    if (isLoadingMore.value || !hasMoreVideos.value) return;
    isLoadingMore.value = true;
    try {
      final lastVideo = videos.last;
      final userId = lastVideo.author.id;
      final response = await supabase.from('videos').select('''
        id, video_url, title, thumbnail_url, created_at,
        profiles!videos_user_id_fkey(id, username, avatar_url, full_name),
        likes_count:likes(count),
        comments_count:comments(count)
      ''').eq('user_id', userId)
          .lt('created_at', lastVideo.createdAt.toIso8601String())
          .order('created_at', ascending: false)
          .limit(_pageSize);
      final newVideos = response
          .map((json) => Video.fromSupabase(json,
          currentUserId: currentUserId,
          isFollowed: followService.isFollowing(userId)))
          .toList();
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

  //--- Các hàm phụ trợ ---

  CachedVideoPlayerPlusController? getControllerForIndex(int index) {
    return _videoControllers[index];
  }

  Future<void> _initializeControllerForIndex(int index) async {
    if (index < 0 || index >= videos.length || _videoControllers.containsKey(index)) {
      return;
    }
    final video = videos[index];
    final controller = CachedVideoPlayerPlusController.networkUrl(Uri.parse(video.videoUrl));
    _videoControllers[index] = controller;
    try {
      await controller.initialize();
      controller.setLooping(true);
      if (currentVideoIndex.value == index) {
        controller.play();
      }
      update();
    } catch (e) {
      print("Lỗi khởi tạo video tại index $index: $e");
      _videoControllers.remove(index);
    }
  }

  void _disposeControllerIfExist(int index) {
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
    }
  }

  //--- Logic Pause/Resume khi điều hướng (quan trọng cho các app phức tạp) ---

  void onPause() {
    print("UserFeedController: Dọn dẹp tất cả video players.");
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    _videoControllers.clear();
  }

  void onResume() {
    print("UserFeedController: Tái tạo video players.");
    _initializeControllerForIndex(currentVideoIndex.value);
    _initializeControllerForIndex(currentVideoIndex.value + 1);
  }
}