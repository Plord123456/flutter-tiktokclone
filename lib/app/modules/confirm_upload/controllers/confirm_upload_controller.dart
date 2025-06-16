import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/tag_model.dart';
import '../../home/controllers/home_controller.dart';

class ConfirmUploadController extends GetxController {
  final File videoFile;
  ConfirmUploadController({required this.videoFile});

  final captionController = TextEditingController();
  final tagsController = TextEditingController();
  final tags = <Tag>[].obs; // Sử dụng danh sách Tag
  final HomeController _homeController = Get.find();
  final supabase = Supabase.instance.client;
  final isUploading = false.obs;

  void addTagFromTextField() {
    final text = tagsController.text.trim().replaceAll('#', '');
    if (text.isNotEmpty && !tags.any((tag) => tag.name == text)) {
      tags.add(Tag(id: tags.length + 1, name: text, initialIsFavorited: false));
    }
    tagsController.clear();
  }

  void removeTag(Tag tag) {
    tags.remove(tag);
  }

  Future<void> uploadVideoPost() async {
    if (isUploading.value) return;

    if (captionController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập tiêu đề cho video.');
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) {
      Get.snackbar('Lỗi', 'Bạn cần đăng nhập để đăng bài.');
      return;
    }

    isUploading.value = true;

    try {
      final thumbnailFile = await _generateThumbnail(videoFile);
      if (thumbnailFile == null) {
        throw Exception('Không thể tạo thumbnail cho video.');
      }

      final videoUrl = await _uploadFile(videoFile, 'videos', 'video/mp4');
      final thumbnailUrl = await _uploadFile(thumbnailFile, 'thumbnails', 'image/png');

      final newVideoData = await supabase.from('videos').insert({
        'user_id': user.id,
        'title': captionController.text.trim(),
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
      }).select().single();

      final newVideoId = newVideoData['id'];

      if (tags.isNotEmpty) {
        final tagsToUpsert = tags.map((tag) => {'name': tag.name}).toList();
        final upsertedTags = await supabase
            .from('tags')
            .upsert(tagsToUpsert, onConflict: 'name')
            .select();

        final videoTagsToInsert = upsertedTags.map((tagData) => {
          'video_id': newVideoId,
          'tag_id': tagData['id'],
        }).toList();

        await supabase.from('video_tags').insert(videoTagsToInsert);
      }

      Get.back();
      _homeController.fetchVideos(refresh: true);
      Get.snackbar('Thành công', 'Đã đăng video của bạn!');
    } catch (e) {
      Get.snackbar('Lỗi', 'Đã có lỗi xảy ra: ${e.toString()}');
    } finally {
      isUploading.value = false;
    }
  }

  Future<File?> _generateThumbnail(File videoFile) async {
    final fileName = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 640,
      quality: 75,
    );
    return fileName != null ? File(fileName) : null;
  }

  Future<String> _uploadFile(File file, String bucket, String contentType) async {
    final fileExt = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = '${supabase.auth.currentUser!.id}/$fileName';

    await supabase.storage.from(bucket).upload(
      filePath,
      file,
      fileOptions: FileOptions(contentType: contentType),
    );

    return supabase.storage.from(bucket).getPublicUrl(filePath);
  }

  @override
  void onClose() {
    captionController.dispose();
    tagsController.dispose();
    super.onClose();
  }
}