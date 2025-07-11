import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/video_model.dart';
import '../../../routes/app_pages.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../profile/views/edit_profile_view.dart';
import '../controllers/video_user_controller.dart';

// V SỬA: Xóa tham số không cần thiết trong hàm khởi tạo
class VideoUserView extends GetView<VideoUserController> {
  const VideoUserView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.userProfile.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Không tìm thấy người dùng.'),
                TextButton(
                    onPressed: controller.fetchData, child: const Text('Thử lại')),
              ],
            ),
          );
        }

        final profile = controller.userProfile.value!;
        return RefreshIndicator(
          onRefresh: () => controller.fetchData(),
          child: CustomScrollView(
            controller: controller.scrollController,
            slivers: [
              SliverAppBar(
                // V SỬA: Lấy giá trị .value từ RxString
                title: Text(profile.username.value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                pinned: true,
                elevation: 0,
              ),
              SliverToBoxAdapter(child: _buildProfileHeader(profile)),
              _buildVideoGrid(),
              SliverToBoxAdapter(
                child: Obx(() => controller.isLoadingMore.value
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
                    : const SizedBox.shrink()),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(Profile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // V SỬA: Lấy giá trị .value từ RxString
          Obx(() => CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: profile.avatarUrl.value.isNotEmpty
                ? CachedNetworkImageProvider(profile.avatarUrl.value)
                : null,
            child: profile.avatarUrl.value.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          )),
          const SizedBox(height: 12),
          // V SỬA: Lấy giá trị .value từ RxString
          Obx(() => Text(
            profile.fullName.value.isNotEmpty
                ? profile.fullName.value
                : '@${profile.username.value}',
            style:
            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )),
          const SizedBox(height: 16),
          _buildStatsRow(profile),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Profile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('Posts', profile.postCount),
        _buildStatColumn('Followers', profile.followerCount),
        _buildStatColumn('Following', profile.followingCount),
      ],
    );
  }

  // V SỬA: Widget này bây giờ nhận RxInt
  Widget _buildStatColumn(String label, RxInt value) {
    return Column(
      children: [
        Obx(() => Text(
          value.value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        )),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: controller.isMyProfile
          ? OutlinedButton(
        onPressed: () {
          Get.to(() => EditProfileView(), binding: ProfileBinding());
        },
        child: const Text('Edit Profile'),
      )
          : Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: controller.toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isFollowing
                    ? Colors.grey.shade300
                    : Colors.red,
                foregroundColor: controller.isFollowing
                    ? Colors.black
                    : Colors.white,
              ),
              child: Text(
                  controller.isFollowing ? 'Unfollow' : 'Follow'),
            ),
          ),
          const SizedBox(width: 8),
          // V SỬA: Chuyển logic vào controller và chỉ gọi hàm ở đây
          IconButton(
            icon: const Icon(Iconsax.message),
            onPressed: controller.navigateToChat,
          ),
        ],
      ),
    ));
  }

  Widget _buildVideoGrid() {
    return Obx(() {
      if (controller.userVideos.isEmpty && !controller.isLoading.value) {
        return const SliverToBoxAdapter(
            child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text("Người dùng này chưa đăng video nào."),
                )));
      }
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final video = controller.userVideos[index];
            return GestureDetector(
              onTap: () => Get.toNamed(Routes.USER_FEED, arguments: {
                'initialVideos': controller.userVideos.toList(),
                'initialIndex': index,
              }),
              onLongPress: controller.isMyProfile
                  ? () => _showVideoOptions(context, video)
                  : null,
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade200),
                errorWidget: (context, error, stackTrace) =>
                    Container(color: Colors.grey.shade300),
              ),
            );
          },
          childCount: controller.userVideos.length,
        ),
      );
    });
  }

  void _showVideoOptions(BuildContext context, Video video) {
    Get.bottomSheet(
      Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Iconsax.trash, color: Colors.red),
            title: const Text('Xóa Video', style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.back();
              _showDeleteConfirmationDialog(context, video);
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.close_circle),
            title: const Text('Hủy'),
            onTap: () {
              Get.back();
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Video video) {
    Get.defaultDialog(
      title: "Xác nhận xóa",
      middleText:
      "Bạn có chắc chắn muốn xóa video này không? Hành động này không thể hoàn tác.",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      textConfirm: "Xóa",
      textCancel: "Hủy",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.deleteVideo(video.id, video.videoUrl);
      },
      onCancel: () {},
    );
  }
}
