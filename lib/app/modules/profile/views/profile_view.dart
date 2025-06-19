import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../../routes/app_pages.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        centerTitle: true,
        actions: [
          Obx(() => Switch(
            value: controller.isDarkMode.value,
            onChanged: controller.toggleTheme,
            activeColor: Theme.of(context).colorScheme.primary,
            thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return const Icon(Iconsax.moon);
                }
                return const Icon(Iconsax.sun_1);
              },
            ),
          )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Obx(() {
          if (controller.isLoadingProfile.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = controller.userProfile;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Không có dữ liệu người dùng hoặc bạn chưa đăng nhập.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.offAllNamed(Routes.LOGIN),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Obx(() => CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: profile.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(profile.avatarUrl.value)
                      : null,
                  child: profile.avatarUrl.isEmpty
                      ? Icon(Iconsax.user, size: 50, color: Colors.grey.shade400)
                      : null,
                )),
                const SizedBox(height: 16),
                Obx(() => Text(
                  profile.fullName.value.isNotEmpty
                      ? profile.fullName.value
                      : profile.username.value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )),
                const SizedBox(height: 8),
                Text(
                  controller.authService.supabase.auth.currentUser?.email ?? 'No email',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.navigateToEditProfile,
                    icon: const Icon(Iconsax.edit),
                    label: const Text('Chỉnh sửa hồ sơ'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Obx(() => Column(
                    children: [
                      ListTile(
                        leading: const Icon(Iconsax.user_octagon),
                        title: const Text('Tên người dùng'),
                        subtitle: Text(profile.username.value),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Iconsax.user),
                        title: const Text('Họ và Tên'),
                        subtitle: Text(profile.fullName.value.isNotEmpty
                            ? profile.fullName.value
                            : 'Chưa cập nhật'),
                      ),
                    ],
                  )),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.signOut,
                    icon: const Icon(Iconsax.logout_1),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}