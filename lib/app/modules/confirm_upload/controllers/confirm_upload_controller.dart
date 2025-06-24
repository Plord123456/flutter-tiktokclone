import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart';
import 'package:tiktok_clone/services/media_service.dart';
import '../../../data/models/tag_model.dart';
import '../../home/controllers/home_controller.dart';

class ConfirmUploadController extends GetxController {
  final File videoFile;
  ConfirmUploadController({required this.videoFile});

  // Dependencies
  final _supabase = Supabase.instance.client;
  final MediaService _mediaService = Get.find<MediaService>();
  final HomeController _homeController = Get.find<HomeController>();

  // UI State
  final isUploading = false.obs;
  final uploadStatus = ''.obs; // Biến trạng thái để hiển thị cho người dùng
  final captionController = TextEditingController();
  final tagsController = TextEditingController();
  final tags = <Tag>[].obs;

  /// Hàm chính xử lý việc đăng bài
  Future<void> uploadVideoPost() async {
    // Ngăn chặn việc bấm nút nhiều lần
    if (isUploading.value) return;

    // Kiểm tra dữ liệu đầu vào
    if (captionController.text.trim().isEmpty) {
      Get.snackbar('Thông báo', 'Vui lòng nhập tiêu đề cho video.');
      return;
    }
    final user = _supabase.auth.currentUser;
    if (user == null) {
      Get.snackbar('Lỗi', 'Bạn cần đăng nhập để đăng bài.');
      return;
    }

    isUploading.value = true;
    uploadStatus.value = 'Bắt đầu...';

    try {
      // Bước 1: Gọi MediaService để xử lý và upload file
      // Service sẽ lo việc nén, tạo thumbnail, upload và báo cáo tiến trình
      final uploadResult = await _mediaService.uploadMedia(
        videoFile,
        onProgress: (status) {
          uploadStatus.value = status;
        },
      );

      if (uploadResult == null) {
        throw Exception('Quá trình xử lý media thất bại.');
      }

      uploadStatus.value = 'Đang lưu thông tin...';

      final newVideoData = await _supabase.from('videos').insert({
        'user_id': user.id,
        'title': captionController.text.trim(),
        'video_url': uploadResult.videoUrl,
        'thumbnail_url': uploadResult.thumbnailUrl,
      }).select().single();

      final newVideoId = newVideoData['id'];

      if (tags.isNotEmpty) {
        // Upsert tags để đảm bảo không bị trùng lặp
        final tagsToUpsert =
        tags.map((tag) => {'name': tag.name.toLowerCase()}).toList();
        final upsertedTags = await _supabase
            .from('tags')
            .upsert(tagsToUpsert, onConflict: 'name')
            .select();

        final videoTagsToInsert = upsertedTags
            .map((tagData) => {
          'video_id': newVideoId,
          'tag_id': tagData['id'],
        })
            .toList();
        await _supabase.from('video_tags').insert(videoTagsToInsert);
      }

      Get.offAllNamed(Routes.LAYOUT); // Quay về trang chính
      _homeController.fetchVideos(refresh: true); // Làm mới danh sách video
      Get.snackbar('Thành công', 'Đã đăng video của bạn!');

    } catch (e) {
      print('Lỗi nghiêm trọng khi đăng bài: $e');
      Get.snackbar('Đăng bài thất bại', 'Đã có lỗi xảy ra: ${e.toString()}');
    } finally {
      isUploading.value = false;
    }
  }

  void addTagFromTextField() {
    final text = tagsController.text.trim().replaceAll('#', '');
    if (text.isNotEmpty && !tags.any((tag) => tag.name == text)) {
      // Tạo một Tag object mới
      tags.add(Tag(id: 0, name: text, initialIsFavorited: false)); // id không quan trọng ở client
    }
    tagsController.clear();
  }

  void removeTag(Tag tag) {
    tags.remove(tag);
  }

  @override
  void onClose() {
    captionController.dispose();
    tagsController.dispose();
    super.onClose();
  }
}
