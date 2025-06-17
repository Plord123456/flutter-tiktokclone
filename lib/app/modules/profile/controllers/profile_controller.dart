import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart';
import 'package:tiktok_clone/app/modules/profile/views/edit_profile_view.dart';
import '../../../../services/auth_service.dart';

class ProfileController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final supabase = Supabase.instance.client;
  final _storageBox = GetStorage();

  final isUpdating = false.obs;
  final selectedImage = Rx<File?>(null);
  final isDarkMode = false.obs;

  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController dobController; // Date of Birth Controller

  Profile? get userProfile => authService.userProfile.value;

  final _themeKey = 'isDarkMode';

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    dobController = TextEditingController();
    // Defer theme loading until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTheme();
    });
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

  void navigateToEditScreen() {
    final profile = userProfile;
    if (profile == null) {
      Get.snackbar('Lỗi', 'Dữ liệu người dùng chưa sẵn sàng.');
      return;
    }
    // Khởi tạo giá trị cho các controller trước khi chuyển trang
    nameController.text = profile.fullName.value;
    // Giả sử model Profile của bạn có trường dateOfBirth
    // dobController.text = profile.dateOfBirth.value;
    selectedImage.value = null;

    Get.to(() => const EditProfileView());
  }

  Future<void> pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
    }
  }

  Future<void> updateUserProfile() async {
    if (!formKey.currentState!.validate() || userProfile == null) return;

    isUpdating.value = true;
    try {
      String? newAvatarUrl = userProfile!.avatarUrl.value;

      // 1. Upload ảnh mới nếu có
      if (selectedImage.value != null) {
        final imageFile = selectedImage.value!;
        final imageExtension = imageFile.path.split('.').last.toLowerCase();
        final filePath = '${authService.currentUserId}/profile.$imageExtension';

        await supabase.storage.from('avatars').upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
        // Lấy public URL mới và thêm timestamp để tránh cache
        newAvatarUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
        newAvatarUrl = '$newAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      // 2. Cập nhật dữ liệu trên Supabase Auth và bảng 'profiles'
      final updatedData = {
        'full_name': nameController.text.trim(),
        'avatar_url': newAvatarUrl,
        // 'date_of_birth': dobController.text, // Thêm ngày sinh nếu cần
      };

      // Cập nhật cả bảng 'profiles'
      await supabase
          .from('profiles')
          .update(updatedData)
          .eq('id', authService.currentUserId);

      // 3. ✅ SỬA LỖI CHÍNH: Cập nhật dữ liệu local trong AuthService
      // Truyền đầy đủ các giá trị mới vào hàm
      authService.updateLocalProfile(
        newUsername: userProfile!.username.value, // username giả sử không đổi
        newFullName: nameController.text.trim(),
        newAvatarUrl: newAvatarUrl,               // <-- Dòng quan trọng nhất đã được thêm
        // newDateOfBirth: dobController.text,    // <-- Thêm nếu cần
      );

      Get.back(); // Quay lại trang profile
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