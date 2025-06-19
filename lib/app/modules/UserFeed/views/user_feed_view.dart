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
      body: PageView.builder(
        controller: controller.pageController,
        scrollDirection: Axis.vertical,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: controller.videos.length,
        itemBuilder: (context, index) {
          final video = controller.videos[index];
          // VideoPlayerItem chịu trách nhiệm hiển thị từng video
          return VideoPlayerItem(video: video, index:index, );
        },
        // ✅ ĐÂY LÀ PHẦN SỬA LỖI QUAN TRỌNG NHẤT
        onPageChanged: (index) {
          // Điều kiện để tải thêm video (khi người dùng lướt gần đến cuối)
          if (index >= controller.videos.length - 2 && controller.hasMoreVideos.value) {

            // Dùng addPostFrameCallback để gọi hàm loadMoreVideos MỘT CÁCH AN TOÀN
            // Nó sẽ thực thi sau khi frame hiện tại đã được vẽ xong.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Thêm một lần kiểm tra nữa để chắc chắn không gọi nhiều lần khi không cần thiết
              if (!controller.isLoadingMore.value) {
                controller.loadMoreVideos();
              }
            });
          }
        },
      ),
    );
  }
}