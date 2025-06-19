import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/follow_service.dart';

class HomeController extends GetxController {
  // Services
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();
  final authService = Get.find<AuthService>();

  // State cho việc tải dữ liệu
  final videoList = <Video>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMoreVideos = true.obs;
  final _videoPageSize = 5;

  // State cho chức năng Like
  final RxSet<String> likedVideoIds = <String>{}.obs;
  final _likingInProgress = <String>{}.obs;
  String get currentUserId => authService.currentUserId;

  // STATE ĐỂ QUẢN LÝ VIDEO PLAYER
  final PageController pageController = PageController();
  final RxInt currentVideoIndex = 0.obs;
  final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};

  @override
  void onInit() {
    super.onInit();
    initialLoad();
    _setupPageListener();
  }

  void _setupPageListener() {
    pageController.addListener(() {
      final newIndex = pageController.page?.round();
      if (newIndex != null && newIndex != currentVideoIndex.value) {
        _videoControllers[currentVideoIndex.value]?.pause();
        currentVideoIndex.value = newIndex;
        _playCurrentVideo();
        _disposeUnusedControllers();
      }
    });
  }

  Future<void> initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([_fetchUserLikes(), fetchVideos(refresh: true)]);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu: ${e.toString()}');
    } finally {
      isLoading.value = false;
      if (videoList.isNotEmpty) {
        getControllerForIndex(0);
        if (videoList.length > 1) getControllerForIndex(1);
      }
    }
  }

  // Hàm mới: Tải tất cả ID video đã thích một lần duy nhất
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

  Future<void> fetchVideos({required bool refresh}) async {
    try {
      final from = refresh ? 0 : videoList.length;
      final to = from + _videoPageSize - 1;

      // ✅ CÂU LỆNH SELECT RẤT GỌN VÀ HIỆU QUẢ
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
        // Kiểm tra trạng thái like từ Set đã tải sẵn
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

  void toggleLike(String videoId) async {
    if (_likingInProgress.contains(videoId)) return;
    final video = videoList.firstWhereOrNull((v) => v.id == videoId);
    if (video == null) return;

    _likingInProgress.add(videoId);
    final isCurrentlyLiked = video.isLikedByCurrentUser.value;

    // Cập nhật UI ngay lập tức
    video.isLikedByCurrentUser.toggle();
    video.likeCount.value += isCurrentlyLiked ? -1 : 1;
    // Cập nhật Set ở local
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
      // Khôi phục trạng thái nếu có lỗi
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
  // CÁC HÀM QUẢN LÝ VIDEO PLAYER ĐƯỢC CẬP NHẬT
  CachedVideoPlayerPlusController? getControllerForIndex(int index) {
    if (!_videoControllers.containsKey(index)) {
      if (index >= 0 && index < videoList.length) {
        final video = videoList[index];
        // THAY ĐỔI: TẠO ĐÚNG LOẠI CONTROLLER
        final controller = CachedVideoPlayerPlusController.networkUrl(Uri.parse(video.videoUrl))
          ..initialize().then((_) {
            if (index == currentVideoIndex.value) _playCurrentVideo();
            update([video.id]);
          });
        _videoControllers[index] = controller;
      }
    }
    return _videoControllers[index];
  }

  void _playCurrentVideo() {
    final controller = _videoControllers[currentVideoIndex.value];
    if (controller != null && controller.value.isInitialized) {
      controller.play();
      controller.setLooping(true);
    }
  }

  void _disposeUnusedControllers() {
    final activeIndexes = [
      currentVideoIndex.value - 1,
      currentVideoIndex.value,
      currentVideoIndex.value + 1,
    ];
    final keysToRemove = <int>[];
    _videoControllers.forEach((key, controller) {
      if (!activeIndexes.contains(key)) {
        controller.dispose();
        keysToRemove.add(key);
      }
    });
    keysToRemove.forEach(_videoControllers.remove);
    print('Disposed controllers. Remaining: ${_videoControllers.length}');
  }

  @override
  void onClose() {
    pageController.dispose();
    _videoControllers.forEach((key, controller) {
      controller?.dispose();
    });
    _videoControllers.clear();
    super.onClose();
  }
}
