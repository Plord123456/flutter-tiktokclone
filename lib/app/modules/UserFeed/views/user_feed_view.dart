import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/video_player_item.dart';
import '../controllers/user_feed_controller.dart';

class UserFeedView extends GetView<UserFeedController> {
  const UserFeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Feed video cuộn dọc
          PageView.builder(
            controller: controller.pageController,
            scrollDirection: Axis.vertical,
            itemCount: controller.videos.length,
            onPageChanged: (index) {
              // Khi cuộn gần đến cuối, tải thêm video
              if (index >= controller.videos.length - 3) {
                controller.loadMoreVideos();
              }
            },
            itemBuilder: (context, index) {
              final video = controller.videos[index];
              return VideoPlayerItem(
                video: video,
              );
            },
          ),
          // Nút Back
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }
}