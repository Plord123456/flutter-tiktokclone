// lib/app/modules/home/controllers/home_controller.dart

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/follow_service.dart';

class HomeController extends GetxController {
  // --- PHẦN LOGIC TẢI DATA VÀ LIKE (Đã rất tốt) ---
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();
  final authService = Get.find<AuthService>();

  final videoList = <Video>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMoreVideos = true.obs;
  final _videoPageSize = 5;

  final RxSet<String> likedVideoIds = <String>{}.obs;
  final _likingInProgress = <String>{}.obs;
  String get currentUserId => authService.currentUserId;
  // --- KẾT THÚC PHẦN LOGIC TẢI DATA ---


  // --- PHẦN QUẢN LÝ VIDEO PLAYER (ĐÃ ĐƯỢC DỌN DẸP) ---
  final PageController pageController = PageController();
  final RxInt currentVideoIndex = 0.obs;
  final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};

  @override
  void onInit() {
    super.onInit();
    initialLoad();
    pageController.addListener(_onPageScroll);
  }

  // onInit sẽ gọi hàm này
  Future<void> initialLoad() async {
    isLoading.value = true;
    try {
      // Tải song song likes và video, rất hiệu quả!
      await Future.wait([_fetchUserLikes(), fetchVideos(refresh: true)]);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu: ${e.toString()}');
    } finally {
      isLoading.value = false;
      // Sau khi có danh sách video, chủ động khởi tạo controller cho 2 video đầu tiên
      if (videoList.isNotEmpty) {
        _initializeControllerForIndex(0);
        if (videoList.length > 1) {
          _initializeControllerForIndex(1);
        }
      }
    }
  }

  // Hàm này sẽ được gọi từ PageView trong file home_view.dart
  void onPageChanged(int index) {
    // 1. Dừng video ở trang cũ
    final oldController = _videoControllers[currentVideoIndex.value];
    if (oldController != null && oldController.value.isPlaying) {
      oldController.pause();
    }

    // 2. Cập nhật trang hiện tại
    currentVideoIndex.value = index;

    // 3. Chạy video ở trang mới
    final newController = _videoControllers[index];
    if (newController != null && newController.value.isInitialized) {
      newController.play();
    } else {
      // Nếu controller chưa sẵn sàng, khởi tạo nó
      _initializeControllerForIndex(index);
    }

    // 4. Tối ưu: Tải trước video tiếp theo và dọn dẹp video ở xa
    _initializeControllerForIndex(index + 1);
    _disposeControllerIfExist(index - 2);
  }

  Future<void> _initializeControllerForIndex(int index) async {
    // Điều kiện để tránh khởi tạo thừa hoặc lỗi
    if (index < 0 || index >= videoList.length || _videoControllers.containsKey(index)) {
      return;
    }

    final video = videoList[index];
    final controller = CachedVideoPlayerPlusController.networkUrl(Uri.parse(video.videoUrl));
    _videoControllers[index] = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);

      // Chỉ play nếu đây là video đang hiển thị
      if (currentVideoIndex.value == index) {
        controller.play();
      }

      // Cập nhật UI cho VideoPlayerItem tương ứng
      update([video.id]);
    } catch (e) {
      print("Lỗi khởi tạo video tại index $index: $e");
      _videoControllers.remove(index);
    }
  }

  // Hàm getter ĐÚNG: Chỉ lấy, không tạo mới.
  CachedVideoPlayerPlusController? getControllerForIndex(int index) {
    return _videoControllers[index];
  }

  void _disposeControllerIfExist(int index) {
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
    }
  }

  @override
  void onClose() {
    pageController.removeListener(_onPageScroll);
    pageController.dispose();
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    _videoControllers.clear();
    super.onClose();
  }

  void _onPageScroll() {
    final newIndex = pageController.page?.round();

    if (newIndex != null && newIndex != currentVideoIndex.value) {
      final oldController = _videoControllers[currentVideoIndex.value];
      if (oldController != null && oldController.value.isPlaying) {
        oldController.pause();
      }
      currentVideoIndex.value = newIndex;

      final newController = _videoControllers[newIndex];
      if (newController != null && newController.value.isInitialized) {
        newController.play();
      } else {
        _initializeControllerForIndex(newIndex);
      }

      _initializeControllerForIndex(newIndex + 1);
      _disposeControllerIfExist(newIndex - 2);
    }
  }
  Future<void> fetchVideos({required bool refresh}) async {
    try {
      final from = refresh ? 0 : videoList.length;
      final to = from + _videoPageSize - 1;

      final response = await supabase.from('videos').select('''
        *,
        profiles!videos_user_id_fkey(*),
        likes_count:likes(count),
        comments_count:comments(count)
      ''').order('created_at', ascending: false).range(from, to);

      final newVideos = response.map((item) => Video.fromSupabase(
        item,
        currentUserId: currentUserId,
        isFollowed: followService.isFollowing(item['user_id']),
        isLiked: likedVideoIds.contains(item['id']),
      )).toList();

      if (refresh) {
        videoList.assignAll(newVideos);
      } else {
        videoList.addAll(newVideos);
      }
      if (newVideos.length < _videoPageSize) {
        hasMoreVideos.value = false;
      }
    } catch (e) {
      print('Lỗi khi tải videos: ${e.toString()}');
      if (refresh) rethrow;
    }
  }

  Future<void> _fetchUserLikes() async {
    if (currentUserId.isEmpty) return;
    try {
      final response = await supabase
          .from('likes')
          .select('video_id')
          .eq('user_id', currentUserId);

      final ids = response.map((item) => item['video_id'] as String).toSet();
      likedVideoIds.assignAll(ids);
    } catch (e) {
      print('Lỗi khi tải danh sách likes: $e');
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


  void onPause() {
    print("HomeController: Dọn dẹp tất cả video players.");
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    _videoControllers.clear();
  }

  void onResume() {
    print("HomeController: Tái tạo video players.");
    // Khởi tạo lại video ở trang hiện tại và trang kế tiếp để lướt mượt hơn
    _initializeControllerForIndex(currentVideoIndex.value);
    _initializeControllerForIndex(currentVideoIndex.value + 1);
  }  void pauseCurrentVideo() {
    final currentController = _videoControllers[currentVideoIndex.value];
    if (currentController != null && currentController.value.isPlaying) {
      currentController.pause();
    }
  }

  void resumeCurrentVideo() {
    final currentController = _videoControllers[currentVideoIndex.value];
    if (currentController != null &&
        currentController.value.isInitialized &&
        !currentController.value.isPlaying) {
      currentController.play();
    }
  }
  void toggleLike(String videoId) async {
    if (_likingInProgress.contains(videoId)) return;
    final video = videoList.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;

    _likingInProgress.add(videoId);
    final isCurrentlyLiked = video.isLikedByCurrentUser.value;

    video.isLikedByCurrentUser.toggle();
    video.likeCount.value += isCurrentlyLiked ? -1 : 1;
    if (isCurrentlyLiked) {
      likedVideoIds.remove(videoId);
    } else {
      likedVideoIds.add(videoId);
    }

    try {
      if (isCurrentlyLiked) {
        await supabase.from('likes').delete().match({'video_id': videoId, 'user_id': currentUserId});
      } else {
        await supabase.from('likes').insert({'video_id': videoId, 'user_id': currentUserId});
      }
    } catch (e) {
      video.isLikedByCurrentUser.toggle();
      video.likeCount.value += isCurrentlyLiked ? 1 : -1;
      if (isCurrentlyLiked) {
        likedVideoIds.add(videoId);
      } else {
        likedVideoIds.remove(videoId);
      }
      print('Lỗi khi toggle like: $e');
    } finally {
      _likingInProgress.remove(videoId);
    }
  }

  void toggleFollow(String userIdToFollow) {
    followService.toggleFollow(userIdToFollow);
  }
}