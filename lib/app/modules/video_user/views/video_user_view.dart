import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/models/profile_model.dart';
import '../../../data/models/video_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/video_user_controller.dart';

class VideoUserView extends GetView<VideoUserController> {
  const VideoUserView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building VideoUserView with profileUserId: ${controller.profileUserId.value}, username: ${controller.userProfile.value?.username}');
    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.hasClients &&
          scrollController.position.pixels >= scrollController.position.maxScrollExtent * 0.9) {
        controller.fetchUserVideos();
      }
    });
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value && controller.userProfile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.userProfile.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('User not found.'),
                TextButton(onPressed: controller.fetchData, child: const Text('Retry')),
              ],
            ),
          );
        }

        final profile = controller.userProfile.value!;
        return RefreshIndicator(
          onRefresh: () => controller.fetchData(),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildProfileHeader(profile)),
              _buildVideoGrid(),
            ],
          ),
        );
      }),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      title: Obx(() => Text(
        controller.userProfile.value?.username ?? 'Profile',
        style: const TextStyle(fontWeight: FontWeight.bold),
      )),
    );
  }

  Widget _buildProfileHeader(Profile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey.shade200,
            child: profile.avatarUrl?.isNotEmpty ?? false
                ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: profile.avatarUrl!,
                fit: BoxFit.cover,
                width: 90,
                height: 90,
                placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                errorWidget: (context, url, error) => const Icon(Icons.person, size: 40),
              ),
            )
                : const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName ?? profile.username,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn('Posts', controller.postCount.value.toString()),
          const VerticalDivider(width: 20, thickness: 1),
          _buildStatColumn('Followers', (profile.followerCount ?? 0).toString()),
          const VerticalDivider(width: 20, thickness: 1),
          _buildStatColumn('Following', (profile.followingCount ?? 0).toString()),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Obx(() => SizedBox(
        width: double.infinity,
        child: controller.isMyProfile.value
            ? OutlinedButton.icon(
          icon: const Icon(Iconsax.edit, size: 18),
          onPressed: () => Get.toNamed(Routes.PROFILE),
          label: const Text('Edit Profile'),
        )
            : ElevatedButton(
          onPressed: controller.isFollowing ? controller.unfollowUser : controller.followUser,
          child: Text(controller.isFollowing ? 'Unfollow' : 'Follow'),
        ),
      )),
    );
  }

  Widget _buildVideoGrid() {
    return Obx(() => SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          if (index >= controller.videos.length) {
            return controller.hasMoreVideos.value
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : const SizedBox.shrink();
          }
          final video = controller.videos[index];
          return GestureDetector(
            onTap: () => Get.toNamed(Routes.USER_FEED, arguments: {
              'userId': controller.profileUserId.value,
              'initialVideos': controller.videos.toList(),
              'initialIndex': index,
            }),
            onLongPress: controller.isMyProfile.value ? () => _showVideoOptions(context, video) : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (video.thumbnailUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.play_circle_outline, color: Colors.white),
                    ),
                  )
                else
                  Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.play_circle_outline, color: Colors.white),
                  ),
                if (controller.isMyProfile.value)
                  const Positioned(top: 4, right: 4, child: Icon(Icons.copy_all_outlined, color: Colors.white, size: 16)),
                if (video.tags.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Wrap(
                      children: video.tags.take(2).map((tag) => Chip(
                        label: Text('#${tag.name}', style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.black54,
                      )).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
        childCount: controller.videos.length + (controller.hasMoreVideos.value ? 1 : 0),
      ),
    ));
  }

  void _showVideoOptions(BuildContext context, Video video) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          spacing: 8.0,
          children: [
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: const Text('Delete Video', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                Get.defaultDialog(
                  title: 'Confirm Deletion',
                  middleText: 'Are you sure you want to delete this video?',
                  onConfirm: () {
                    controller.deleteVideo(video.id, video.videoUrl);
                    Get.back();
                  },
                  onCancel: () => Get.back(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.share),
              title: const Text('Share'),
              onTap: () => Get.back(), // TODO: Thêm logic share
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}