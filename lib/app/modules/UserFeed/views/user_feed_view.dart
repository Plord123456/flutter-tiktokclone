import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_clone/widgets/video_player_item.dart';

import '../controllers/user_feed_controller.dart';

class UserFeedView extends GetView<UserFeedController> {
  const UserFeedView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      // ✅ BƯỚC 1: Bọc PageView trong một Obx
      // Obx sẽ lắng nghe sự thay đổi của controller.videos và tự động cập nhật UI
      body: Obx(
            () {
          // Hiển thị vòng xoay nếu đang tải và chưa có video nào
          if (controller.videos.isEmpty && controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }
          // Hiển thị thông báo nếu không có video nào
          if (controller.videos.isEmpty) {
            return const Center(child: Text('Người dùng này chưa có video nào.'));
          }

          return PageView.builder(
            controller: controller.pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.videos.length,
            // ✅ BƯỚC 2: Cập nhật lại hàm onPageChanged
            onPageChanged: (index) {
              // 1. Gọi hàm onPageChanged của controller để xử lý play/pause
              controller.onPageChanged(index);

              // 2. Kiểm tra và tải thêm video nếu cần
              final isEnd = index >= controller.videos.length - 2;
              if (isEnd && controller.hasMoreVideos.value && !controller.isLoadingMore.value) {
                controller.loadMoreVideos();
              }
            },
            itemBuilder: (context, index) {
              final video = controller.videos[index];
              // VideoPlayerItem sẽ hiển thị từng video
              return VideoPlayerItem(video: video, index: index);
            },
          );
        },
      ),
    );
  }
}