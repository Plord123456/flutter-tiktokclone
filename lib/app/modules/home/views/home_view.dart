import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/video_player_item.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value && controller.videoList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.videoList.length,
          onPageChanged: (index) {
            if (index == controller.videoList.length - 2 && controller.canLoadMoreVideos.value) {
              controller.loadMoreVideos();
            }
          },
          itemBuilder: (context, index) {
            final video = controller.videoList[index];
            return VideoPlayerItem(
              video: video,

            );
          },
        );
      }),
    );
  }
}