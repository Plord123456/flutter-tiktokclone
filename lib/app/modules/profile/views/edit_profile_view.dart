import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Thêm import này
import '../controllers/profile_controller.dart';

class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa hồ sơ'),
        actions: [
          Obx(() => controller.isUpdating.value
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : TextButton(
            onPressed: controller.updateUserProfile,
            child: const Text('Lưu'),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- PHẦN HIỂN THỊ AVATAR ---
              Obx(() {
                final newImage = controller.selectedImage.value;
                // SỬA LỖI Ở ĐÂY
                final existingAvatarUrl = controller.userProfile?.avatarUrl;
                ImageProvider? backgroundImage;

                if (newImage != null) {
                  backgroundImage = FileImage(newImage);
                } else if (existingAvatarUrl != null && existingAvatarUrl.isNotEmpty) {
                  // Cải tiến: Dùng CachedNetworkImageProvider
                  backgroundImage = CachedNetworkImageProvider(existingAvatarUrl.value);
                }

                return CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: backgroundImage,
                  child: backgroundImage == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                );
              }),
              TextButton(
                onPressed: controller.pickImageFromGallery,
                child: const Text('Thay đổi ảnh đại diện'),
              ),
              const SizedBox(height: 24),
              // --- CÁC TRƯỜNG NHẬP LIỆU ---
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và Tên',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Tên không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.dobController,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh',
                  hintText: 'DD/MM/YYYY',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    // Định dạng ngày tháng theo chuẩn
                    String formattedDate =
                        "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                    controller.dobController.text = formattedDate;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}