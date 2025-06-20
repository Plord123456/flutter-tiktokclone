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
      body: Obx(
            () {
          if (controller.videos.isEmpty && controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.videos.isEmpty) {
            return const Center(child: Text('Người dùng này chưa có video nào.'));
          }
          return PageView.builder(
            controller: controller.pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: controller.videos.length,
            onPageChanged: (index) {
              controller.onPageChanged(index);
              final isEnd = index >= controller.videos.length - 2;
              if (isEnd && controller.hasMoreVideos.value && !controller.isLoadingMore.value) {
                controller.loadMoreVideos();
              }
            },
            itemBuilder: (context, index) {
              final video = controller.videos[index];
              final videoPlayerController = controller.getControllerForIndex(index);
              if (videoPlayerController != null) {
                return VideoPlayerItem(
                  video: video,
                  videoPlayerController: videoPlayerController,
                  index: index,
                );
              }
              return Container(color: Colors.black);
            },
          );
        },
      ),
    );
  }
}