import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/app/modules/profile/views/edit_profile_view.dart';
import '../../../../services/auth_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final supabase = Supabase.instance.client;
  final _storageBox = GetStorage();

  final isLoading = false.obs;
  final isUpdating = false.obs;
  final _rxUser = Rx<User?>(null);
  final selectedImage = Rx<File?>(null);
  final isDarkMode = false.obs;

  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController dobController;

  StreamSubscription? _authServiceSubscription;

  User? get currentUserData => _rxUser.value;
  String? get avatarUrlData => _rxUser.value?.userMetadata?['avatar_url'];
  final _themeKey = 'isDarkMode';

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    dobController = TextEditingController();

    _rxUser.value = _authService.currentUser;
    _authServiceSubscription = _authService.rxCurrentUser.listen((user) {
      _rxUser.value = user;
    });

    _loadTheme();
  }

  void _loadTheme() {
    isDarkMode.value = _storageBox.read(_themeKey) ?? Get.isPlatformDarkMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    });
  }

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    _storageBox.write(_themeKey, value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    });
  }

  void navigateToEditScreen() {
    final user = currentUserData;
    if (user == null) {
      Get.snackbar('Lỗi', 'Dữ liệu người dùng chưa sẵn sàng.');
      return;
    }
    nameController.text = user.userMetadata?['name'] ?? '';
    dobController.text = user.userMetadata?['date_of_birth'] ?? '';
    selectedImage.value = null;

    Get.to(() => const EditProfileView());
  }

  Future<void> pickImageFromGallery() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
    }
  }

  Future<void> updateUserProfile() async {
    if (!formKey.currentState!.validate()) return;

    isUpdating.value = true;
    try {
      String? newAvatarUrl;

      if (selectedImage.value != null) {
        final imageFile = selectedImage.value!;
        final imageExtension = imageFile.path.split('.').last.toLowerCase();
        final filePath =
            '${supabase.auth.currentUser!.id}/profile.$imageExtension';

        await supabase.storage.from('avatars').update(
          filePath,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
        newAvatarUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
        newAvatarUrl =
        '$newAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      final Map<String, dynamic> updatedData = {
        'name': nameController.text.trim(),
        'date_of_birth': dobController.text.trim(),
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      };

      await supabase.auth.updateUser(UserAttributes(data: updatedData));

      Get.back();
      Get.snackbar('Thành công', 'Hồ sơ đã được cập nhật!');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật hồ sơ: ${e.toString()}');
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    nameController.dispose();
    dobController.dispose();
    _authServiceSubscription?.cancel();
    super.onClose();
  }
}