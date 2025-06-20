import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import '../../../data/models/video_model.dart';

class UserFeedController extends GetxController {
  //--- STATE & DEPENDENCIES ---
  final List<Video> initialVideos;
  final int initialIndex;

  // Controller cho PageView để lướt video
  late PageController pageController;

  // State cho danh sách video và vị trí video hiện tại
  final RxList<Video> videos = <Video>[].obs;
  final RxInt currentVideoIndex = 0.obs;

  // Nơi lưu trữ và quản lý các trình phát video
  final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};

  // Constructor nhận dữ liệu từ màn hình trước
  UserFeedController({required this.initialVideos, required this.initialIndex});

  //--- VÒNG ĐỜI CONTROLLER ---

  @override
  void onInit() {
    super.onInit();
    // 1. Gán dữ liệu video ban đầu
    videos.assignAll(initialVideos);
    currentVideoIndex.value = initialIndex;

    // 2. Khởi tạo PageController tại đúng vị trí video
    pageController = PageController(initialPage: initialIndex);

    // 3. Khởi tạo trước một vài video player để trải nghiệm mượt mà
    _initializeControllerForIndex(initialIndex);
    if (initialIndex + 1 < videos.length) {
      _initializeControllerForIndex(initialIndex + 1);
    }
  }

  @override
  void onClose() {
    print("UserFeedController: Dọn dẹp tất cả tài nguyên.");
    pageController.dispose();
    // Gọi onPause để đảm bảo tất cả video player được giải phóng
    onPause();
    super.onClose();
  }

  //--- LOGIC QUẢN LÝ VIDEO ---

  /// Hàm này sẽ được kết nối với thuộc tính `onPageChanged` của PageView
  void onPageChanged(int index) {
    // Dừng video cũ vừa lướt qua
    final oldController = _videoControllers[currentVideoIndex.value];
    if (oldController != null && oldController.value.isPlaying) {
      oldController.pause();
    }

    // Cập nhật index và chạy video mới
    currentVideoIndex.value = index;
    final newController = _videoControllers[index];
    if (newController != null && newController.value.isInitialized) {
      newController.play();
    } else {
      _initializeControllerForIndex(index);
    }

    // Tải trước video kế tiếp và dọn dẹp video ở xa để tiết kiệm bộ nhớ
    _initializeControllerForIndex(index + 1);
    _disposeControllerIfExist(index - 2);
  }

  /// Lấy video player cho một vị trí cụ thể trong list
  CachedVideoPlayerPlusController? getControllerForIndex(int index) {
    return _videoControllers[index];
  }

  /// Khởi tạo một video player mới
  Future<void> _initializeControllerForIndex(int index) async {
    // Tránh khởi tạo thừa hoặc index không hợp lệ
    if (index < 0 || index >= videos.length || _videoControllers.containsKey(index)) {
      return;
    }

    final video = videos[index];
    final controller = CachedVideoPlayerPlusController.networkUrl(Uri.parse(video.videoUrl));
    _videoControllers[index] = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);
      // Nếu đây là video đang hiển thị thì cho nó chạy
      if (currentVideoIndex.value == index) {
        controller.play();
      }
      // Cập nhật UI để hiển thị video player
      update();
    } catch (e) {
      print("Lỗi khởi tạo video tại index $index: $e");
      _videoControllers.remove(index);
    }
  }

  /// Dọn dẹp một video player cụ thể
  void _disposeControllerIfExist(int index) {
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
    }
  }

  //--- LOGIC PAUSE/RESUME KHI ĐIỀU HƯỚNG ---

  /// Dọn dẹp TOÀN BỘ video khi rời khỏi màn hình này
  void onPause() {
    print("UserFeedController: Dọn dẹp tất cả video players.");
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    _videoControllers.clear();
  }

  /// Tái tạo video khi quay lại màn hình này
  void onResume() {
    print("UserFeedController: Tái tạo video players.");
    _initializeControllerForIndex(currentVideoIndex.value);
    _initializeControllerForIndex(currentVideoIndex.value + 1);
  }
}