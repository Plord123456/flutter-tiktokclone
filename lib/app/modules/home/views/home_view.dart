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
            scrollDirection: Axis.vertical,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: controller.videoList.length,
            itemBuilder: (context, index) {
              final video = controller.videoList[index];
              return VideoPlayerItem(video: video );
              },
            onPageChanged: (index) {
              // Tải thêm video khi người dùng cuộn gần đến cuối
              if (index == controller.videoList.length - 2) {
                controller.loadMoreVideos();
              }
            },
          );
        },
      ),
    );
  }
}
