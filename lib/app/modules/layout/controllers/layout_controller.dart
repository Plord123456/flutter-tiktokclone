import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tiktok_clone/app/modules/confirm_upload/views/confirm_upload_view.dart';
import 'package:tiktok_clone/app/modules/home/views/home_view.dart';
import 'package:tiktok_clone/app/modules/profile/views/profile_view.dart';
import '../../video_user/views/video_user_view.dart'; // Giả sử bạn có màn hình search

class LayoutController extends GetxController {
  // Sử dụng RxInt để theo dõi chỉ số tab hiện tại
  final RxInt currentIndex = 0.obs;

  final List<Widget> screens = [
    HomeView(),
    ProfileView(),
  ];

  void changeTabIndex(int index) {
    currentIndex.value = index;
  }

  Future<void> pickAndNavigateToConfirm() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video == null) {
        // Người dùng không chọn video nào
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(video.path)}';
      final safeVideoFile = await File(video.path).copy('${appDir.path}/$fileName');

      Get.to(() => ConfirmUploadView(videoFile: safeVideoFile));

    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chọn video: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}