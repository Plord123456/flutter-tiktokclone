import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/video_player_item.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
            () {
          if (controller.isLoading.value && controller.videoList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.videoList.isEmpty) {
            return const Center(child: Text('Không có video nào để hiển thị.'));
          }
          return PageView.builder(
            controller: controller.pageController,
            scrollDirection: Axis.vertical,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: controller.videoList.length,
            onPageChanged: (index) {
              controller.onPageChanged(index);
              final isEnd = index >= controller.videoList.length - 2;
              if (isEnd && controller.hasMoreVideos.value && !controller.isLoadingMore.value) {
                controller.loadMoreVideos();
              }
            },
            itemBuilder: (context, index) {
              final video = controller.videoList[index];
              final videoPlayerController = controller.getControllerForIndex(index);
              if (videoPlayerController != null) {
                return VideoPlayerItem(
                  video: video,
                  videoPlayerController: videoPlayerController,
                  index: index,
                );
              }
              // Fallback, có thể hiện một placeholder
              return Container(color: Colors.black);
            },
          );
        },
      ),
    );
  }
}
