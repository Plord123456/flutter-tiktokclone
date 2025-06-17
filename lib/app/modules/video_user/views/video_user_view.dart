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
    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 300) {
        controller.fetchUserVideos();
      }
    });

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
                TextButton(onPressed: controller.fetchData, child: const Text('Thử lại')),
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
              SliverAppBar(
                title: Text(profile.username, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false)
                ? CachedNetworkImageProvider(profile.avatarUrl!)
                : null,
            child: (profile.avatarUrl?.isEmpty ?? true)
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName ?? '@${profile.username}',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('Posts', profile.postCount.toString()),
        _buildStatColumn('Followers', profile.followerCount.toString()),
        _buildStatColumn('Following', profile.followingCount.toString()),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: controller.isMyProfile
          ? OutlinedButton(onPressed: () {}, child: const Text('Edit Profile'))
          : ElevatedButton(
        onPressed: controller.toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: controller.isFollowing.value ? Colors.grey.shade300 : Colors.red,
          foregroundColor: controller.isFollowing.value ? Colors.black : Colors.white,
        ),
        child: Text(controller.isFollowing.value ? 'Unfollow' : 'Follow'),
      ),
    ));
  }

  Widget _buildVideoGrid() {
    return Obx(() {
      if (controller.userVideos.isEmpty && !controller.isLoading.value) {
        return const SliverToBoxAdapter(child: Center(child: Padding(
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
              onLongPress: controller.isMyProfile ? () => _showVideoOptions(context, video) : null,
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, error, stackTrace) => Container(color: Colors.grey.shade300),
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
      // Logic bottom sheet ở đây
        Container()
    );
  }
}
