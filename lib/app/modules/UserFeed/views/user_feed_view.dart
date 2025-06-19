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
          return VideoPlayerItem(video: video, index:index);
        },
        onPageChanged: (index) {
          if (index >= controller.videos.length - 2 && controller.hasMoreVideos.value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
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