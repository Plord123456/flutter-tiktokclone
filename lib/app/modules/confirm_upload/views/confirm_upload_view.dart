import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/confirm_upload_controller.dart';

class ConfirmUploadView extends StatefulWidget {
  final File videoFile;

  const ConfirmUploadView({
    super.key,
    required this.videoFile,
  });

  @override
  State<ConfirmUploadView> createState() => _ConfirmUploadViewState();
}

class _ConfirmUploadViewState extends State<ConfirmUploadView> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConfirmUploadController(videoFile: widget.videoFile));
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng video mới')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: Get.height * 0.45,
                child: _videoController.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                )
                    : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.captionController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
                maxLength: 150,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.tagsController,
                decoration: InputDecoration(
                  labelText: 'Gắn thẻ (Tags)',
                  hintText: 'Ví dụ: #dance, #funny...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: controller.addTagFromTextField,
                  ),
                ),
                onSubmitted: (_) => controller.addTagFromTextField(),
              ),
              const SizedBox(height: 10),
              Obx(() => Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: controller.tags.map((tag) => Chip(
                  label: Text('#$tag'),
                  onDeleted: () => controller.removeTag(tag),
                )).toList(),
              )),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: controller.isUploading.value ? null : controller.uploadVideoPost,
                child: controller.isUploading.value
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                )
                    : const Text('Đăng'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}