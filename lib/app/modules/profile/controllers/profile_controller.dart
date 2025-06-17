import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/data/models/profile_model.dart'; // Import Profile model
import 'package:tiktok_clone/app/modules/profile/views/edit_profile_view.dart';
import '../../../../services/auth_service.dart';

class ProfileController extends GetxController {
  // REFACTOR: Chỉ cần một tham chiếu đến AuthService.
  // Mọi dữ liệu về người dùng sẽ được lấy từ đây.
  final AuthService authService = Get.find<AuthService>();
  final supabase = Supabase.instance.client;
  final _storageBox = GetStorage();

  final isUpdating = false.obs;
  final selectedImage = Rx<File?>(null);
  final isDarkMode = false.obs;

  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController dobController; // Giả sử bạn có trường này

  // REFACTOR: Không cần _rxUser hay _authServiceSubscription nữa.
  // Tạo một getter đơn giản để truy cập profile từ service.
  Profile? get userProfile => authService.userProfile.value;

  final _themeKey = 'isDarkMode';

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    dobController = TextEditingController();
    _loadTheme();
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
    // FIX: Lấy dữ liệu từ `userProfile` của service
    final profile = userProfile;
    if (profile == null) {
      Get.snackbar('Lỗi', 'Dữ liệu người dùng chưa sẵn sàng.');
      return;
    }
    // Dùng `.value` vì username và fullName là RxString
    nameController.text = profile.fullName.value;
    // dobController.text = profile.dateOfBirth.value; // Ví dụ
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
      // 1. Upload ảnh mới (nếu có)
      if (selectedImage.value != null) {
        final imageFile = selectedImage.value!;
        final imageExtension = imageFile.path.split('.').last.toLowerCase();
        final filePath = '${authService.currentUserId}/profile.$imageExtension';

        // Dùng `upload` thay vì `update` để xử lý cả trường hợp chưa có ảnh
        await supabase.storage.from('avatars').upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
        // Lấy public URL với timestamp để tránh cache
        newAvatarUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
        newAvatarUrl = '$newAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      // 2. Cập nhật dữ liệu trong Supabase Auth (user_metadata)
      final updatedData = {
        'full_name': nameController.text.trim(),
        'avatar_url': newAvatarUrl, // Luôn cập nhật URL, dù là cũ hay mới
      };
      await supabase.auth.updateUser(UserAttributes(data: updatedData));

      // 3. Cập nhật dữ liệu trong bảng `profiles`
      await supabase
          .from('profiles')
          .update({
        'full_name': nameController.text.trim(),
        'avatar_url': newAvatarUrl,
      })
          .eq('id', authService.currentUserId);

      // ✅ FIX: BÁO CHO AUTHSERVICE BIẾT ĐỂ CẬP NHẬT STATE TRÊN TOÀN APP
      authService.updateLocalProfile(
        newUsername: userProfile!.username.value, // username không đổi
        newFullName: nameController.text.trim(),
      );

      Get.back(); // Quay về trang profile
      Get.snackbar('Thành công', 'Hồ sơ đã được cập nhật!');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật hồ sơ: ${e.toString()}');
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> signOut() async {
    // REFACTOR: Gọi hàm signOut từ service, nó đã xử lý cả việc chuyển hướng
    await authService.signOut();
  }

  @override
  void onClose() {
    nameController.dispose();
    dobController.dispose();
    super.onClose();
  }
}