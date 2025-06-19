import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/routes/app_pages.dart'; // Sửa lại đường dẫn nếu cần
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../services/auth_service.dart';
import '../views/edit_profile_view.dart';

class ProfileController extends GetxController {
  // Dependencies
  final AuthService authService = Get.find<AuthService>();
  final supabase = Supabase.instance.client;
  final _storageBox = GetStorage();

  // UI State
  final isUpdating = false.obs;
  final selectedImage = Rx<File?>(null);
  final isDarkMode = false.obs;
  final isLoadingProfile = false.obs;

  // Form
  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController dobController;

  // Getter
  Profile? get userProfile => authService.userProfile.value;

  final _themeKey = 'isDarkMode';

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    dobController = TextEditingController();
    ever(authService.userProfile, _updateFormWithProfileData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTheme();
      _updateFormWithProfileData(userProfile);
    });
  }

  void _updateFormWithProfileData(Profile? profile) {
    if (profile != null) {
      if (nameController.text != profile.fullName.value) {
        nameController.text = profile.fullName.value;
      }
      isLoadingProfile.value = false;
    } else {
      isLoadingProfile.value = true;
    }
  }

  void _loadTheme() {
    isDarkMode.value = _storageBox.read(_themeKey) ?? Get.isPlatformDarkMode;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    _storageBox.write(_themeKey, value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  // Chuyển sang dùng route đã định danh
  void navigateToEditProfile() {
    Get.to(
          () => const EditProfileView(), // Truyền thẳng View vào đây
    );
  }

  // ✅ HÀM ĐÃ ĐƯỢC SỬA LẠI HOÀN TOÀN
  Future<void> pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(pickedFile.path);
        final newFilePath = '${appDir.path}/$fileName';
        final newImageFile = await File(pickedFile.path).copy(newFilePath);
        selectedImage.value = newImageFile;
      } catch (e) {
        Get.snackbar('Lỗi xử lý ảnh', 'Không thể lưu ảnh đã chọn, vui lòng thử lại.');
        print('Error copying image: $e');
      }
    }
  }

  Future<void> updateUserProfile() async {
    if (!formKey.currentState!.validate() || userProfile == null) return;

    isUpdating.value = true;
    try {
      String? newAvatarUrl;
      if (selectedImage.value != null) {
        final imageFile = selectedImage.value!;
        final imageExtension = imageFile.path.split('.').last.toLowerCase();
        final filePath = '${authService.currentUserId}/profile.$imageExtension';

        await supabase.storage.from('avatars').upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
        newAvatarUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      await authService.updateUserProfile(
        newUsername: userProfile!.username.value,
        newFullName: nameController.text.trim(),
        newAvatarUrl: newAvatarUrl,
      );

      Get.back();
      Get.snackbar('Thành công', 'Hồ sơ đã được cập nhật!');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật hồ sơ: ${e.toString()}');
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> signOut() async {
    await authService.signOut();
  }

  @override
  void onClose() {
    nameController.dispose();
    dobController.dispose();
    super.onClose();
  }
}