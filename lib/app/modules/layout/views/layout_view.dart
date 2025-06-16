import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tiktok_clone/app/modules/layout/controllers/layout_controller.dart';

class LayoutView extends GetView<LayoutController> {
  const LayoutView({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy màu chủ đạo từ Theme
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // Body giờ chỉ cần lấy list screens từ controller
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: controller.screens,
      )),
      bottomNavigationBar: BottomAppBar(
        elevation: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Nút Home (index 0)
              _buildNavItem(
                context: context,
                icon: Iconsax.home_2,
                label: 'Home',
                index: 0,
              ),
              // Nút Search/Feed (index 1)
              _buildNavItem(
                context: context,
                icon: Iconsax.user,
                label: 'Profile',
                index: 1,
              ),
              // Nút Upload ở giữa
              // Thay thế IconButton bằng một Widget custom hơn để nổi bật
              InkWell(
                onTap: () => controller.pickAndNavigateToConfirm(), // Chỉ gọi hàm từ controller
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Iconsax.add, color: Colors.white, size: 28),
                ),
              ),
              // Nút Profile (index 2)
              _buildNavItem(
                context: context,
                icon: Iconsax.setting,
                label: 'Setting',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget được tối ưu hóa một chút
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    // Sử dụng Obx để widget này tự build lại khi currentIndex thay đổi
    // mà không cần build lại toàn bộ BottomAppBar
    return Obx(() {
      final isSelected = controller.currentIndex.value == index;
      final color = isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

      return MaterialButton(
        minWidth: 40,
        onPressed: () => controller.changeTabIndex(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      );
    });
  }
}