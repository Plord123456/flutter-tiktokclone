import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/data/models/video_model.dart';
import 'package:tiktok_clone/services/auth_service.dart';
import 'package:tiktok_clone/services/follow_service.dart';
import 'package:video_player/video_player.dart';

class HomeController extends GetxController {
  final supabase = Supabase.instance.client;
  final followService = Get.find<FollowService>();
  final authService = Get.find<AuthService>();

  // State cho việc tải video
  final videoList = <Video>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMoreVideos = true.obs;
  final _videoPageSize = 5;

  // State cho chức năng Like
  final RxSet<String> likedVideoIds = <String>{}.obs;
  final _likingInProgress = <String>{}.obs;
  String get currentUserId => authService.currentUserId;


  final PageController pageController = PageController();
  final RxInt currentVideoIndex = 0.obs;
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void onInit() {
    super.onInit();
    initialLoad();
    _setupPageListener(); // Thêm listener cho PageView

  }
  void _setupPageListener() {
    pageController.addListener(() {
      final newIndex = pageController.page?.round();
      if (newIndex != null && newIndex != currentVideoIndex.value) {
        // Dừng video cũ
        _videoControllers[currentVideoIndex.value]?.pause();

        // Cập nhật index và chạy video mới
        currentVideoIndex.value = newIndex;
        _playCurrentVideo();

        // Giải phóng các controller không cần thiết để tiết kiệm bộ nhớ
        _disposeUnusedControllers();
      }
    });
  }

  Future<void> initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchUserLikes(),
        fetchVideos(refresh: true),
      ]);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu: ${e.toString()}');
    } finally {
      isLoading.value = false;
      // Khởi tạo và chơi video đầu tiên sau khi tải xong
      if (videoList.isNotEmpty) {
        getControllerForIndex(0);
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
  VideoPlayerController? getControllerForIndex(int index) {
    if (!_videoControllers.containsKey(index)) {
      if (index < videoList.length) {
        final video = videoList[index];
        final controller = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl))
          ..initialize().then((_) {
            if (index == currentVideoIndex.value) {
              _playCurrentVideo();
            }
            update();
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
    // Giữ lại controller cho video hiện tại, video trước và video sau
    final aLiveIndexes = [
      currentVideoIndex.value - 1,
      currentVideoIndex.value,
      currentVideoIndex.value + 1,
    ];

    final keysToRemove = <int>[];
    _videoControllers.forEach((key, controller) {
      if (!aLiveIndexes.contains(key)) {
        controller.dispose();
        keysToRemove.add(key);
      }
    });
    keysToRemove.forEach(_videoControllers.remove);
  }
  @override
  void onClose() {
    pageController.dispose();
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    _videoControllers.clear();
    super.onClose();
  }
}